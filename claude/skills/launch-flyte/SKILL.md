---
name: launch-flyte
description: Launch Flyte workflows programmatically from devbox. Use when user wants to execute/launch/trigger/run a Flyte workflow, kick off a Flyte execution, or mentions launching a registered workflow with specific inputs. Also use when user asks how to run a Flyte workflow without the console UI.
---

# Launch Flyte Workflow

Launch registered Flyte workflows programmatically using `create_flyte_remote()` via the `flyte_inspect` bazel target.

## Prerequisites

- Workflow must already be registered (adhoc or master domain)
- Know: project, domain, workflow name, version, and inputs

## Workflow

### 1. Gather Parameters

Ask user for (or infer from context):
- **project**: Flyte project (e.g., `ml-exploration`, `payments-intelligence`)
- **domain**: Usually `adhoc` for manual runs, `master` for scheduled
- **workflow name**: Fully qualified (e.g., `src.python.flyte.my_team.my_wf.main.my_workflow`)
- **version**: Branch-commit format (e.g., `my-branch-abc123def`) or with base (`my-branch-abc123-based-on-my-branch-def456`)
- **inputs**: Dict of workflow input parameters

To find the version, user can check Flyte console or use recent registration output.

### 2. Write Launch Script

Write a Python script to `/tmp/launch_flyte_wf.py`:

```python
from src.python.flyte.internal.remote.client import create_flyte_remote

remote = create_flyte_remote()
wf = remote.fetch_workflow(
    project="<project>",
    domain="<domain>",
    name="<workflow_name>",
    version="<version>",
)
execution = remote.execute(
    entity=wf,
    inputs={<inputs_dict>},
    project="<project>",
    domain="<domain>",
)
print(f"Execution launched!")
print(remote.generate_console_url(execution))
```

### 3. Execute via Bazel

Determine environment and run the script using `flyte_inspect` as the runtime:

```bash
if [ -n "$SSH_CONNECTION" ]; then
  # Remote devbox
  bazel run //src/python/agentic_mle/scripts:flyte_inspect \
    --run_under="python3 /tmp/launch_flyte_wf.py #"
else
  # Local laptop
  pay exec bazel run //src/python/agentic_mle/scripts:flyte_inspect \
    --run_under="python3 /tmp/launch_flyte_wf.py #"
fi
```

The `#` at the end comments out the original binary path that bazel appends, so only our script runs.

**Why this approach**: The `flyte_inspect` target uses a universe with flytekit and grpc dependencies needed by `create_flyte_remote()`. Running `python3` directly fails due to missing grpc.

### 4. Report Result

On success, print the Flyte console URL for the user to monitor the execution.

## Common Patterns

**Launch with date input:**
```python
from datetime import datetime
inputs={"ds": datetime(2026, 6, 1)}
```

**Launch with string/int inputs:**
```python
inputs={"model_name": "smart_retry_v3", "num_samples": 1000}
```

**Launch with no inputs:**
```python
inputs={}
```

## Troubleshooting

- **"Workflow not found"**: Check project/domain/name/version are correct. Browse Flyte console to verify.
- **Import errors**: Ensure using `flyte_inspect` target, not running python directly.
- **Timeout on laptop**: First run may be slow due to bazel build. Subsequent runs use cache.

## Reference

For registration details, see Trailhead: [Flyte Registration](https://trailhead.corp.stripe.com/docs/flyte/user-guides/stages-of-development/registration)
