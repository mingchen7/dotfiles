---
name: streamlit-app
description: Build production Streamlit apps at Stripe. Use when creating new Streamlit apps, adding pages/charts/filters to existing apps, structuring Streamlit projects, configuring Bazel BUILD targets, querying Pinot or Hubble from Streamlit, adding feature flags, setting up LDAP access controls, deploying to streamlit-proxy-srv, or migrating to Python 3.11. Also triggers on questions about Streamlit best practices, layout patterns, data layer design, or deep-linking at Stripe.
---

# Building Production Streamlit Apps at Stripe

## Quick Start

```bash
# Create a new app scaffold
pay streamlit:create   # run from /pay/src/zoolander

# Run locally (remote devbox)
pay streamlit run src/python/<team>/<app>/dashboard.py --universe ml_golden_202407_streamlit_311

# Run locally (laptop with syncing mydata)
pay up  # in ~/stripe/zoolander first
pay streamlit run src/python/<team>/<app>/dashboard.py --universe ml_golden_202407_streamlit_311
```

All Streamlit source lives in `zoolander/src/python/`. Apps deploy to `streamlit-proxy-next.corp.stripe.com/<app_name>`.

## Project Structure

Follow this modular page-based layout. See [references/architecture.md](references/architecture.md) for detailed patterns.

```
src/python/<team>/<app>/
  dashboard.py              # Entry point: page config, sidebar nav, routing
  BUILD.bazel               # streamlit_page + py_library targets
  core/
    abstract_dataset.py     # Data source ABC (Pinot/Trino dispatch)
    routing.py              # URL <-> session state sync (deep linking)
    logger.py               # Structured logging with username injection
  <domain>/
    constants.py            # Enums mapping dimension names -> SQL columns
    configuration.py        # Sidebar filters, dataset selection, Configuration dataclass
    datasets.py             # Concrete dataset classes
    filter_value.py         # FilterValue(dimension, condition, is_system) dataclass
    charts/                 # Reusable chart components (one class per chart type)
    pages/                  # One module per nav page, each exports render(config)
      helpers.py            # Shared validation, title rendering
  flags/
    flags.yaml              # Feature flag definitions
```

## BUILD.bazel Configuration

```python
load("//tools/build_rules/streamlit:defs.bzl", "streamlit_page")

py_library(
    name = "my_app_lib",
    srcs = glob(["**/*.py"]),
    requires = [
        "plotly",
        "pandas",
        "numpy",
        "pydantic",
        "streamlit",
    ],
    deps = [
        "//src/python/autohubble",           # Trino/Hubble queries
        "//src/python/auth_rates:pinot_connector",  # Pinot queries (if needed)
        "//src/python/latency/streamlit:extra",     # Shared utils
        "//src/python/stripe_feature_flags",        # Feature flags
    ],
    visibility = ["//visibility:public"],
)

streamlit_page(
    name = "my_app",
    main = "dashboard.py",
    deps = [":my_app_lib"],
    visibility = ["//visibility:public"],
)
```

**Universe**: Apps default to `ml_golden_202407_streamlit_311` (Python 3.11, Streamlit 1.45). Legacy apps in `PY38_STREAMLIT_APPS` get `airflow1`. Custom universes are forbidden.

**Missing deps**: Add to `config/py_dependencies/ml_golden_202407_streamlit_311/deps.yaml` then run `dev/py requirements update --force-update ml_golden_202407_streamlit_311`.

## Deployment

See [references/deployment.md](references/deployment.md) for the full deployment checklist including ACL registration, QA testing, and production deploy.

## Data Layer

See [references/data-layer.md](references/data-layer.md) for:
- AbstractDataset pattern (Pinot/Trino dispatch)
- Query caching with `@st.cache_data(ttl=900)`
- SQL generation from enum-driven dimension/aggregation mappings
- Debug mode (`?debug=True` shows generated SQL)
- Hubble streaming for large results

## Charts and Visualization

See [references/charts.md](references/charts.md) for:
- Plotly Express patterns (line, bar, scatter)
- Standard layout configuration
- Tab organization (Auth Rate / Share / Count / Table)
- Chart class structure with `render(context, title, additional_filters)` interface
- KPI cards with `st.metric()`

## Key Patterns (Quick Reference)

### Entry Point (`dashboard.py`)

```python
import streamlit as st

st.set_page_config(layout="wide", page_title="My Dashboard")

# Hydrate session state from URL params BEFORE any rendering
set_state_from_url()

# Sidebar navigation
page = st.sidebar.radio("Navigate", ["Summary", "Details", "Settings"],
                        key="page", format_func=lambda p: f"{'icon'} {p}")

# Route to page modules — each exposes render()
if page == "Summary":
    summary.render()
elif page == "Details":
    details.render()
```

### Deep Linking (URL <-> Session State)

```python
def set_state_from_url():
    """Read URL params into session state (URL seeds initial state)."""
    for key, value in st.query_params.items():
        if key not in st.session_state:
            st.session_state[key] = clean_param(key, value)

def set_url_from_state(config):
    """Push current config back to URL for shareability."""
    st.query_params.update(url_params_from_config(config))
```

### Configuration Dataclass

```python
@dataclass
class Configuration:
    dataset: AbstractDataset
    metric: Metric
    start_date: date
    end_date: date
    filters: list[FilterValue] = field(default_factory=list)
    # ... all dashboard state in one object

    def add_filters(self, *new_filters):
        self.filters = self.filters + [f for f in new_filters if f is not None]
```

### Filter Composition

```python
# System filters (auto-applied, never serialized to URL)
FilterValue(dimension=Dimension.OUTCOME_TYPE, condition="!= 'blocked'", is_system=True)

# User filters (from widgets)
FilterValue(dimension=Dimension.CARD_BRAND, condition="IN ('visa', 'mastercard')")
```

### Feature Flags

```yaml
# flags/flags.yaml
:flags:
  :show_new_feature:
    :flag_type: :feature
    :interface: :custom
    :custom_attributes: [username, team_name]
    :description: "Gates access to new feature"
```

```python
from src.python.stripe_feature_flags import FeatureFlag
if FeatureFlag.is_active("zoolander.show_new_feature",
                         custom_attributes={"username": username, "team_name": team}):
    render_new_feature()
else:
    st.error("You don't have access to this feature.")
```

### Shared Utilities (`latency/streamlit/extra.py`)

```python
from src.python.latency.streamlit.extra import (
    get_stripe_username,     # Authenticated user from SSL cert header
    query_with_permalink,    # Hubble query -> (DataFrame, permalink_url)
    hubble_link,             # Render clickable Hubble link
    setup_trusted_egress_proxy,  # Required before external HTTP calls
    is_in_streamlit,         # Check if running in prod pod
)
```

## Critical Constraints

- **No sqlite** — deploys spin up new instances; use S3 for persistence
- **No usertables for writes** — use team scratch zones
- **Secrets are shared** across all apps (no isolation)
- **Multi-threading breaks SRC tokens** — attach `ScriptRunContext` if you must thread
- **External domains must be allowlisted** via egress proxy
- **gRPC needs manual SRC tokens** — only `autohubble` gets automatic propagation
- **Contingent workers can't use autohubble** — use parameterized queries instead
- **QA != prod** — autohubble doesn't work in QA
- **Large results (>2GB on py3.8)** — use `hubble_permalink_to_df(url, stream=True)`
