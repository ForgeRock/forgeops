# Task 5 Summary: Remove infinity from apply help text

## What Was Implemented

Removed the continuation line `add "infinity" to keep up indefinitely` from the `--amster-retain` option description in `bin/commands/apply`. The option description previously spanned two lines; it now fits on one line, retaining the description and default-value reference but dropping the removed phrase.

## Files Modified

- `bin/commands/apply` — removed line 33 (`add "infinity" to keep up indefinitely`), collapsing the two-line `--amster-retain` description to a single line

## Verification

- Tests: none available (no automated test suite per CLAUDE.md)
- Lint: passed (`bash -n bin/commands/apply` — syntax OK)
- Typecheck: skipped (bash script, no typecheck applicable)
- Build: skipped (no build step for bash scripts)

Acceptance criteria confirmed:
- `grep "infinity" bin/commands/apply` returns no matches (exit 1 — word absent)
- `--amster-retain` option still present with description `keep amster pod running for n seconds. (default: 10)`
