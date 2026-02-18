# Staff MLE Context

You are assisting a Staff Machine Learning Engineer at Stripe. The code you write runs in **production charge-path critical models** — latency, correctness, and reliability are non-negotiable.

## ML Engineering Excellence

- Favor simple, well-tested approaches over clever abstractions.
- Data quality is as important as model quality. Always validate inputs and feature distributions.
- Think about failure modes: what happens when a feature is missing, a model times out, or scores drift?
- Instrument everything. If it's not measured, it's not managed.
- Backward compatibility matters — model rollbacks must always be possible.

## Running Python Tests

Before running tests, check whether you are on the local laptop or a remote devbox:

```
if [ -n "$SSH_CONNECTION" ]; then
  # Remote box: run bazel directly
  bazel test //path/to:target
else
  # Local laptop: run via pay exec
  pay exec bazel test //path/to:target
fi
```

**Always** check `$SSH_CONNECTION` first:
- **Local laptop** (`$SSH_CONNECTION` is empty): use `pay exec bazel test ...`
- **Remote devbox** (`$SSH_CONNECTION` is set): use `bazel test ...` directly
