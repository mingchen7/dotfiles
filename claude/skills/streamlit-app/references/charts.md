# Charts and Visualization Patterns

## Plotly Express — Primary Library

All production Streamlit apps at Stripe use Plotly. Always pass `theme=None` to disable Streamlit's default theming.

### Line Charts (Time Series)

```python
import plotly.express as px

fig = px.line(df, x="time", y=["auth_rate", "network_auth_rate"],
              color_discrete_map={"auth_rate": "blue", "network_auth_rate": "green"})
fig.update_layout(
    margin=dict(l=40, r=0, t=5, b=0),
    legend=dict(title="", orientation="h"),
    xaxis=dict(title=""),
    yaxis=dict(title="", tickformat=".2%"),  # Percentage format for rates
)
context.plotly_chart(fig, use_container_width=True, theme=None)
```

### Stacked Bar Charts

```python
fig = px.bar(df, x="time", y="count", color="outcome",
             barmode="stack",
             color_discrete_map={
                 "authorized": "#2ecc71",   # Green
                 "declined": "#e74c3c",     # Red
                 "blocked": "#f1c40f",      # Yellow
                 "nsf": "#3498db",          # Blue
             })
fig.update_layout(
    margin=dict(l=40, r=0, t=5, b=0),
    legend=dict(title="", orientation="h"),
)
```

### Pivot Charts (Dimension Breakdown)

```python
fig = px.line(df, x="time", y="auth_rate", color=dimension.value)
# or
fig = px.bar(df, x="time", y="count", color=dimension.value, barmode="stack")
```

### Standard Layout Config (Apply to All Charts)

```python
STANDARD_LAYOUT = dict(
    margin=dict(l=40, r=0, t=5, b=0),
    legend=dict(title="", orientation="h"),
    xaxis=dict(title=""),
)

fig.update_layout(**STANDARD_LAYOUT)
```

### Monitoring Annotations

```python
from plotly import graph_objects as go

def add_annotation(fig, time, label, color="red"):
    fig.add_vline(x=time, line_dash="dot", line_color=color)
    fig.add_annotation(x=time, y=1, yref="paper", text=label,
                      showarrow=False, font=dict(size=10, color=color))
```

## Chart Tab Organization

Every chart renders 3-4 tabs showing different views of the same data:

```python
def render(self, context, title=None):
    if title:
        context.markdown(f"##### {title}")

    tabs = context.tabs(["Auth Rate", "Share", "Count", "Table"])

    with tabs[0]:  # Rate (line chart, percentage y-axis)
        fig = px.line(df, x="time", y="auth_rate")
        fig.update_layout(yaxis=dict(tickformat=".2%"))
        context.plotly_chart(fig, use_container_width=True, theme=None)

    with tabs[1]:  # Share (stacked bar, percentage)
        df["share"] = df["count"] / df.groupby("time")["count"].transform("sum")
        fig = px.bar(df, x="time", y="share", color=dimension, barmode="stack")
        context.plotly_chart(fig, use_container_width=True, theme=None)

    with tabs[2]:  # Count (stacked bar, absolute)
        fig = px.bar(df, x="time", y="count", color=dimension, barmode="stack")
        context.plotly_chart(fig, use_container_width=True, theme=None)

    with tabs[3]:  # Table (raw data)
        context.dataframe(df, use_container_width=True)
```

## Chart Class Pattern

```python
class PivotChart:
    def __init__(self, configuration: Configuration):
        self.configuration = configuration

    def query(self, dimension: Dimension, additional_filters=None) -> pd.DataFrame:
        filters = self.configuration.filters + (additional_filters or [])
        df = self.configuration.dataset.aggregation(
            dimensions=[Dimension.TIME, dimension],
            aggregations=[Aggregation.TOTAL_COUNT, Aggregation.AUTHORIZED_COUNT],
            filters=filters)
        df["time"] = pd.to_datetime(df["time"], unit="s")
        df["auth_rate"] = df["authorized_count"] / df["total_count"]
        df["share"] = df.groupby("time")["total_count"].transform(lambda x: x / x.sum())
        return df.sort_values("time")

    def render(self, context, title=None, additional_filters=None) -> bool:
        if not validate_dataset_configuration(context, self.configuration.dataset, ...):
            return False

        # Dimension selector
        dimension = context.multiselect("Pivot by", [d.value for d in available_dims],
                                        max_selections=1, key="pivot_dim")
        if not dimension:
            context.info("Select a dimension to pivot by.")
            return True

        df = self.query(Dimension(dimension[0]), additional_filters)
        if df.empty:
            context.warning("No data found.")
            return False

        # Render tabs...
        return True
```

## High-Cardinality Dimensions

For dimensions with many values (merchant, issuer), fetch top-N first:

```python
class HighDimensionalPivotChart(PivotChart):
    def render(self, context, title=None, additional_filters=None):
        # Slider to control cardinality
        limit = context.slider("Top N", 1, 50, 10, key="top_n")

        # Query top N by volume
        top_df = self.configuration.dataset.aggregation(
            dimensions=[dimension],
            aggregations=[Aggregation.TOTAL_COUNT],
            filters=self.configuration.filters,
            order_by=f"{Aggregation.TOTAL_COUNT.value} DESC",
            limit=limit)

        # Filter time series to only top N values
        top_values = top_df[dimension.value].tolist()
        top_filter = FilterValue(dimension, f"IN ({', '.join(f\"'{v}'\" for v in top_values)})")

        # Enrich with human-readable names
        df[dimension.value] = df[dimension.value].map(
            lambda x: get_merchant_name(x) if dimension == Dimension.MERCHANT_ID else x)

        return super().render(context, additional_filters=[top_filter])
```

## KPI Cards

```python
col1, col2, col3, col4, col5 = st.columns(5)
col1.metric("Auth Rate", f"{rate:.2%}", delta=f"{delta:+.2%}")
col2.metric("Transactions", f"{truncate_number(count)}")
col3.metric("Decline Rate", f"{decline_rate:.2%}")
# ...
```

## Custom Sub-Tab Navigation (Button-Based)

When native `st.tabs()` styling is insufficient:

```python
TAB_NAMES = ["Acceptance", "Declines", "Diagnostics", "Accounts"]

cols = st.columns(len(TAB_NAMES))
for i, (col, name) in enumerate(zip(cols, TAB_NAMES)):
    if col.button(name, key=f"tab_{name}", use_container_width=True):
        st.session_state.active_tab = i

# Highlight active tab with injected CSS
active = st.session_state.get("active_tab", 0)
st.markdown(f"""<style>
    div[data-testid="stHorizontalBlock"] > div:nth-child({active + 1}) button {{
        background-color: #4CAF50; color: white;
    }}
</style>""", unsafe_allow_html=True)

# Render active tab content
if active == 0:
    render_acceptance(config)
elif active == 1:
    render_declines(config)
# ...
```

## Context Parameter Pattern

Always accept a Streamlit context instead of using `st` directly — enables rendering in columns, tabs, expanders:

```python
def render(self, context, title=None):
    # context can be st, a column, a tab, or an expander
    context.markdown(f"##### {title}")
    context.plotly_chart(fig, use_container_width=True, theme=None)
```

## Rate Calculation Conventions

```python
# E2E conversion (includes blocks)
df["e2e_auth"] = df["authorized"] / df["total"]

# Network authorization (excludes blocks)
df["network_auth"] = df["authorized"] / (df["total"] - df["blocked"])

# Network auth minus NSF
df["network_auth_minus_nsf"] = df["authorized"] / (df["total"] - df["blocked"] - df["nsf"])

# Share of transactions
df["share"] = df.groupby("time")["total"].transform(lambda x: x / x.sum())
```
