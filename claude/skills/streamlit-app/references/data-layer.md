# Data Layer Patterns

## AbstractDataset Pattern

Base class that dispatches queries to Pinot (real-time) or Trino (analytics) transparently.

```python
from abc import ABC, abstractmethod
from enum import IntEnum
import pandas as pd

class DataStore(IntEnum):
    PINOT = 1
    TRINO = 2

class AbstractDataset(ABC):
    @property
    @abstractmethod
    def table_name(self) -> str: ...

    @property
    @abstractmethod
    def data_store(self) -> DataStore: ...

    @property
    @abstractmethod
    def last_updated(self) -> str: ...

    def query(self, sql: str) -> pd.DataFrame:
        if self.data_store == DataStore.PINOT:
            from src.python.auth_rates.pinot_connector import query as pinot_query
            return pinot_query(sql, should_emit_metrics=False, timeout=60000)
        else:
            from src.python.autohubble.autohubble import hubble_query_to_df, PRESTO
            return hubble_query_to_df(sql, PRESTO)

    @property
    def data_store_name(self) -> str:
        return "Pinot" if self.data_store == DataStore.PINOT else "Trino"
```

## Extended Dataset with SQL Generation

```python
class AuthorizationData(AbstractDataset):
    @property
    @abstractmethod
    def dimensions(self) -> dict[Dimension, str]:
        """Map Dimension enum -> SQL expression for SELECT/GROUP BY."""
        ...

    @property
    @abstractmethod
    def aggregations(self) -> dict[Aggregation, str]:
        """Map Aggregation enum -> SQL expression for SELECT."""
        ...

    def validate(self, dimensions: list[Dimension], aggregations: list[Aggregation]) -> bool:
        """Check dataset supports requested dimensions/aggregations."""
        return (all(d in self.dimensions for d in dimensions) and
                all(a in self.aggregations for a in aggregations))

    def aggregation(self, dimensions, aggregations, filters, order_by=None, limit=None):
        dim_sql = ", ".join(self.dimensions[d] for d in dimensions)
        agg_sql = ", ".join(self.aggregations[a] for a in aggregations)
        filter_sql = " AND ".join(f"{f.dimension.value} {f.condition}" for f in filters)
        where = f"WHERE {filter_sql}" if filter_sql else ""
        group_by = ", ".join(str(i+1) for i in range(len(dimensions)))

        sql = f"""SELECT {dim_sql}, {agg_sql}
                  FROM {self.table_name}
                  {where}
                  GROUP BY {group_by}
                  ORDER BY {order_by or '1'}
                  LIMIT {limit or 9999999}"""

        if st.session_state.get("debug", False):
            st.code(sql)
        return self.query(sql)
```

## Querying Hubble/Trino

```python
from src.python.autohubble.autohubble import hubble_query_to_df, PRESTO

# Basic query
df = hubble_query_to_df("SELECT * FROM analytics.my_table LIMIT 100", PRESTO)

# With permalink (for sharing/debugging)
from src.python.latency.streamlit.extra import query_with_permalink
df, permalink = query_with_permalink("SELECT * FROM analytics.my_table LIMIT 100")
st.markdown(f"[View in Hubble]({permalink})")

# Streaming for large results (>2GB)
from src.python.autohubble.autohubble import hubble_permalink_to_df
df = hubble_permalink_to_df(permalink_url, stream=True)
```

## Querying Pinot (Real-time)

```python
from src.python.auth_rates.pinot_connector import query as pinot_query

# Pinot connector auto-prepends broker trim settings
# Returns pd.DataFrame, cached for 15 minutes via @st.cache_data
df = pinot_query(sql, should_emit_metrics=False, timeout=15000)
```

The pinot_connector uses `RadClient()` (Real-time Analytics Database) and:
- Caches results with `@st.cache_data(ttl=15 * 60)` (15 min)
- Emits DogStatsD metrics for query latency/success/failure
- Pretty-prints failed SQL with `sqlglot`
- Raises `PinotQueryError` with formatted error details

## Caching Strategy

Cache at the **query execution layer**, not at the chart/page level:

```python
@st.cache_data(ttl=15 * 60)  # 15 minute TTL
def query(sql: str, timeout: int = 15000) -> pd.DataFrame:
    # Execute and return
    ...
```

For Hubble queries, `autohubble` has its own caching. To force fresh results:
```python
df = hubble_query_to_df(query, PRESTO, forceRefresh=True)
```

## Dataset Selection Logic

Auto-select the best dataset based on user choices:

```python
def compute_dataset(charge_type, metric_version, start_date, force_realtime=False):
    if force_realtime:
        return EEAcceptanceFlows()  # Near-real-time Pinot table

    if charge_type == ChargeType.VALIDATION:
        return ValidationFlows()

    if metric_version == MetricVersion.DEDUPLICATED:
        return PaymentFlows()  # Pre-aggregated, deduplicated

    # AcceptanceFlows has 180-day retention
    if (date.today() - start_date).days > 180:
        return PaymentFlows()  # Longer retention

    return AcceptanceFlows()  # Default: real-time hourly
```

## Timestamp Handling

Different Pinot tables use different timestamp formats:

```python
# Seconds-based (AcceptanceFlows, ValidationFlows)
df["time"] = pd.to_datetime(df["time"], unit="s")

# Milliseconds-based (AuthorizationObservations, EEAcceptanceFlows)
df["time"] = pd.to_datetime(df["time"] / 1000, unit="s")
```

## Debug Mode

Append `?debug=True` to URL to show generated SQL before execution:

```python
if st.session_state.get("debug", False):
    st.code(sql, language="sql")
```

## Error Handling in Data Layer

```python
try:
    df = hubble_query_to_df(query, PRESTO)
except Exception as e:
    st.error(f"Query failed: {str(e)}")
    return pd.DataFrame()

if df.empty:
    st.warning("No data found for the selected filters.")
    return
```

For Pinot, the connector raises `PinotQueryError` with:
- The formatted SQL that failed
- The Pinot error message
- Query timing information
