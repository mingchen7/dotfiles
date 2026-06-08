# Deployment Guide

## Pre-Deployment Checklist

1. App works locally via `pay streamlit run`
2. All Python deps declared in BUILD.bazel `requires` list
3. All internal deps declared in BUILD.bazel `deps` list
4. `streamlit_page` rule defined with correct `main` entry point
5. LDAP access group chosen (or `"stripe"` for all employees)

## Step 1: Register the App

Edit `zoolander/src/python/latency/streamlit/BUILD.bazel`:

### Add ACL Entry

```python
STREAMLIT_ACLS = {
    # ...
    "myApp": ["stripe"],              # All employees
    # "myApp": ["access-my-ldap"],    # Restricted access
}
```

### Add to App List

```python
STREAMLIT_APPS_ON_PY311 = [
    # ...
    "//src/python/<team>/<app>:my_app",
]
```

### Add Page Mapping

```python
streamlit_bundle(
    name = "pages_py311",
    acls = STREAMLIT_ACLS,
    pages = {
        # ...
        "//src/python/<team>/<app>:my_app": "myApp",
    },
)
```

The short name in `pages` becomes the URL path: `streamlit-proxy-next.corp.stripe.com/myApp`

## Step 2: Request Access

- Join [access-streamlit-proxy](https://ldapmanager.corp.stripe.com/groups/access-streamlit-proxy) LDAP group
- For QA: request [QA deploy permission](https://ldapmanager.qa.corp.stripe.com/permissions/deploy-mainland-streamlit-proxy)

## Step 3: Test in QA

1. Push your branch
2. Go to [amp.qa.corp.stripe.com/services/streamlit-proxy-srv](https://amp.qa.corp.stripe.com/services/streamlit-proxy-srv)
3. Click "Kick off missing builds" (CI doesn't build Streamlit on every branch)
4. **Claim** the service to prevent auto-deploys from master
5. Deploy your branch
6. Verify at `streamlit-proxy.qa.corp.stripe.com/myApp`

**Known limitation**: `autohubble` does not work in QA. Test data queries in prod or mock them.

## Step 4: Merge and Deploy

1. Create PR with label `service-streamlit-proxy-srv`
2. Merge to master
3. Wait for [streamlit-proxy-srv](https://amp.corp.stripe.com/services/streamlit-proxy-srv) auto-deploy
4. Verify at `streamlit-proxy-next.corp.stripe.com/myApp`

## Step 5: Verify Migration (Python 3.11)

After confirming the app works on the py3.11 service, add a verified entry:

```python
streamlit_bundle(
    name = "pages_py311",
    verified = {
        "myApp": "true",
    },
    # ...
)
```

This enables automatic request redirection from the old service to the new one.

## Adding Missing Dependencies

If your app needs a Python package not in the py3.11 universe:

1. Add to `config/py_dependencies/ml_golden_202407_streamlit_311/deps.yaml`
2. Run: `dev/py requirements update --force-update ml_golden_202407_streamlit_311`
3. Merge the change

## LDAP Access Patterns

```python
# All employees
"myApp": ["stripe"]

# Specific team
"myApp": ["access-my-team"]

# Multiple groups (user needs to be in ANY one)
"myApp": ["access-team-a", "access-team-b"]
```

Only LDAP **permissions** work, not user groups.

## Feature Flags for Gradual Rollout

Gate features within your app without redeploying:

```yaml
# flags/flags.yaml
:flags:
  :show_new_feature:
    :flag_type: :feature
    :interface: :custom
    :permanent: false
    :custom_attributes: [username, team_name]
    :description: "New experimental feature"
    :expected_end_date: "2026-06-30"
```

```python
from src.python.stripe_feature_flags import FeatureFlag
if FeatureFlag.is_active("zoolander.show_new_feature",
                         custom_attributes={"username": get_stripe_username()}):
    render_experimental_page()
```

## Docker Layer Optimization

Heavy deps (torch, tensorflow, xgboost) are split into separate Docker layers in the bundle BUILD to:
- Stay under the 3GiB remote cache limit
- Improve layer caching (heavy deps change rarely)

If your app pulls in a large dependency, check if it needs its own layer in the container image config.

## Monitoring

- Usage metrics: [go/streamlit-metrics](https://hubble.corp.stripe.com/viz/dashboards/44926-streamlit-metrics)
- Service health: [amp.corp.stripe.com/services/streamlit-proxy-srv](https://amp.corp.stripe.com/services/streamlit-proxy-srv)
- Logs: Available in Splunk (inconsistently — known issue)
- Emit custom metrics via DogStatsD (see pinot_connector for example pattern)

## External Network Access

Before making HTTP calls to external domains:

```python
from src.python.latency.streamlit.extra import setup_trusted_egress_proxy
setup_trusted_egress_proxy()
# Now requests.get("https://allowed-domain.com") works
```

Allowed domains are listed in `gocode/shared_configs/egress-proxy-srv/acl-trusted.yaml`. To add a new domain, follow [the egress proxy guide](trh_doc_PEKVsLrHZmG9bS).

## S3 Access

For reading/writing S3 buckets from Streamlit:
1. Configure your S3 dataset to grant `streamlit-proxy-srv` read/write access
2. On mydata, apply [S3 monkey patching](https://go/s3-mydata) for local dev
3. Use boto3 or the utilities in `src/python/ml/lib/parquet`

## LLM Integration

Use Stripe's internal LLM Proxy:

```python
from src.python.ml.llm.llmproxy.client import LLMProxyClient

# Supports Azure O4 Mini, OpenAI O3, GCP Gemini, Bedrock Claude
client = LLMProxyClient()
response = client.chat_completion(messages=[...], model="bedrock-claude-sonnet-4")
```

Feature-gate LLM features — they are experimental and may have latency/reliability issues.
