# Architecture Patterns

## Page-Based Routing

Each page is a module with a `render()` function. The entry point dispatches based on session state.

```python
# dashboard.py
PAGES = {
    "Summary": ("chart-icon", summary),
    "Details": ("table-icon", details),
    "Realtime": ("clock-icon", realtime),
}

page = st.sidebar.radio("Navigate", list(PAGES.keys()), key="page",
                        format_func=lambda p: f"{PAGES[p][0]} {p}")

try:
    PAGES[page][1].render()
except ValueError:
    pass  # Guard against invalid URL param values
```

## Configuration-as-God-Object

Thread a single `Configuration` dataclass through the entire render pipeline:

```python
# In each page's render():
def render():
    header = st.container()  # Reserve space for title
    config = render_filters()  # Build config from sidebar widgets
    render_title_for_configuration(header, config)  # Fill in title

    chart = SummaryChart(config)
    chart.render(st)
```

The Configuration carries: dataset, metric, date range, filters, account info, feature flags, and monitoring context.

## Page Module Contract

Every page module must:
1. Export a `render()` function (no args — reads from shared state)
2. Call `render_filters()` to build Configuration
3. Validate dataset compatibility before querying
4. Handle empty results gracefully

```python
# pages/summary.py
def render():
    header = st.container()
    config = render_filters()
    render_title_for_configuration(header, config)

    if not validate_dataset_configuration(st, config.dataset,
            dimensions=[Dimension.TIME], aggregations=[Aggregation.TOTAL_COUNT]):
        return

    chart = SummaryChart(config)
    if not chart.render(st, title="Authorization Summary"):
        st.warning("No data found for selected filters.")
```

## Chart Class Contract

Charts are classes accepting Configuration, with a `render()` method returning bool:

```python
class SummaryChart:
    def __init__(self, configuration: Configuration):
        self.configuration = configuration

    def query(self) -> pd.DataFrame:
        """Fetch and transform data."""
        df = self.configuration.dataset.aggregation(
            dimensions=[...], aggregations=[...], filters=self.configuration.filters)
        df[resolution] = pd.to_datetime(df[resolution], unit="s")
        df["auth_rate"] = df["authorized"] / df["total"]
        return df.sort_values(resolution)

    def render(self, context, title=None, additional_filters=None) -> bool:
        """Render chart into the given Streamlit context. Returns success."""
        if not validate_dataset_configuration(context, self.configuration.dataset, ...):
            return False
        df = self.query()
        if df.empty:
            context.warning("No transactions found.")
            return False
        # ... render plotly charts ...
        return True
```

The `context` parameter (a Streamlit container) allows charts to render inside columns, tabs, or expanders without coupling to `st` directly.

## Filter System

### FilterValue

```python
@dataclass
class FilterValue:
    dimension: Dimension    # Enum member -> SQL column name
    condition: str          # Raw SQL fragment: "= 'visa'", "IN ('US', 'CA')", "between 100 and 500"
    is_system: bool = False # True = auto-applied, never serialized to URL
```

### Filter Widget Helpers

```python
def render_select(ctx, dataset, dimension, label, options, format_func=None):
    """Multi-select filter that auto-disables for unsupported dimensions."""
    if dimension not in dataset.dimensions:
        ctx.multiselect(label, options=[], disabled=True,
                       help="Not available for this dataset",
                       key=f"{dimension.value}-disabled")
        return None

    selected = ctx.multiselect(label, options=options, key=dimension.value,
                               format_func=format_func)
    if not selected:
        return None

    escaped = [v.replace("'", "''") for v in selected]
    if len(escaped) == 1:
        return FilterValue(dimension, f"= '{escaped[0]}'")
    return FilterValue(dimension, f"IN ({', '.join(f\"'{v}'\" for v in escaped)})")

def render_slider(ctx, dimension, label, min_val, max_val, multiple=1):
    """Range slider filter with unit conversion."""
    val = ctx.slider(label, min_val, max_val, (min_val, max_val), key=dimension.value)
    if val == (min_val, max_val):
        return None  # No filter when at defaults
    return FilterValue(dimension, f"between {val[0] * multiple} and {val[1] * multiple}")
```

### Sidebar Layout Pattern

```python
def render_filters() -> Configuration:
    # Tier 1: Sidebar controls (always visible)
    charge_type = st.sidebar.selectbox("Charge Type", list(ChargeType), key="charge_type")
    metric = st.sidebar.selectbox("Metric", list(Metric), key="metric")
    start_date = st.sidebar.date_input("Start", default_start, key="start_date")
    end_date = st.sidebar.date_input("End", default_end, key="end_date")

    # Dataset selection based on controls
    dataset = compute_dataset(charge_type, metric_version, start_date)

    # Tier 2: Main area filter rows (4 columns each)
    filters = []
    col1, col2, col3, col4 = st.columns(4)
    filters.append(render_select(col1, dataset, Dimension.CARD_BRAND, "Card Brand", brands))
    filters.append(render_select(col2, dataset, Dimension.COUNTRY, "Country", countries))
    filters.append(render_select(col3, dataset, Dimension.GATEWAY, "Gateway", gateways))
    filters.append(render_select(col4, dataset, Dimension.ISSUER, "Issuer", issuers))

    # Tier 3: Expandable advanced filters
    with st.expander("More filters"):
        col1, col2, col3, col4 = st.columns(4)
        filters.append(render_slider(col1, Dimension.AMOUNT, "Amount (USD)", 0, 10000, multiple=100))
        # ... more filters ...

    # System filters (auto-applied based on metric/dataset)
    system_filters = compute_system_filters(metric, metric_version, dataset)

    clean_filters = [f for f in filters if f is not None]

    config = Configuration(
        dataset=dataset, metric=metric, start_date=start_date, end_date=end_date,
        filters=clean_filters + system_filters)

    set_url_from_config(config)  # Push state to URL
    return config
```

## Enum-Driven Domain Modeling

Map all domain concepts to string-valued enums. Enum `.value` becomes the SQL column name.

```python
class Dimension(str, Enum):
    TIME = "time"
    CARD_BRAND = "card_brand"
    COUNTRY = "country"
    GATEWAY_ACQUIRER = "gateway_acquirer"
    ISSUER_NAME = "issuer_name"
    # ... 40+ dimensions

class Aggregation(str, Enum):
    TOTAL_COUNT = "total_count"
    AUTHORIZED_COUNT = "authorized_count"
    DECLINED_COUNT = "declined_count"

class Metric(str, Enum):
    CONVERSION = "E2E Conversion"
    AUTHORIZATION = "Authorization"
    NETWORK_AUTHORIZATION = "Network Authorization"
```

## Session State Conventions

- Widget `key=` params use `dimension.value` or config field names
- URL params seed session state on first load only (session state takes precedence after)
- `st.session_state.get("debug", False)` enables SQL display
- `st.session_state["page"]` drives navigation
- `st.session_state.active_tab` persists sub-tab selection across reruns

## Conditional Page Layouts

Different pages can render different subsets of filters:

```python
def render_filters():
    page = st.session_state.get("page", "Summary")

    if page == "Benchmarking":
        # Minimal sidebar, fixed metric/version
        st.sidebar.info("Metric: Conversion (Deduplicated)")
        account_id = st.sidebar.text_input("Merchant ID", key="account_id")
        return Configuration(dataset=PaymentFlows(), metric=Metric.CONVERSION, ...)

    if page == "Realtime":
        # Adjusted date constraints, slice monitoring controls
        ...

    # Standard full filter UI
    ...
```

## Logging Pattern

```python
class _UsernameFilter(logging.Filter):
    def filter(self, record):
        try:
            record.username = get_stripe_username()
        except:
            record.username = "unknown"
        return True

def get_logger(name="MyApp"):
    logger = logging.getLogger(name)
    handler = logging.StreamHandler(sys.stderr)
    handler.addFilter(_UsernameFilter())
    handler.setFormatter(logging.Formatter(
        "%(asctime)s - (%(username)s) - %(name)s - %(levelname)s - %(message)s"))
    logger.addHandler(handler)
    return logger
```
