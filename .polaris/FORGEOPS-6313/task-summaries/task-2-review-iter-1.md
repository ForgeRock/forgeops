# Task 2 Review — Iteration 1

## Verdict

REQUEST_CHANGES

## Summary

Task 2 adds `--amster-ttl` to `bin/commands/env` and fixes the `--amster-retain` Helm key bug. The three changes (argument declaration, `manage_env()` Helm merge, `process_overlay_dir()` patch write) are all present and structurally correct. However, both new guards use a falsy truthiness check (`getattr(args, 'amster_ttl', None)`) rather than `isinstance(args.amster_ttl, int)`, which silently discards the valid Kubernetes value `--amster-ttl 0` (immediate deletion after completion). This deviates from the existing `isinstance(args.X, int)` pattern used for every other integer argument in the same file (`am_rep`, `cts_rep`, `idm_rep`, `idrepo_rep`, `ig_rep`).

## Verification

- Tests: NOT_RUN — no automated test suite (confirmed by CLAUDE.md)
- Lint: NOT_RUN — no linter configured in repo
- Typecheck: PASS — `python3 -m py_compile bin/commands/env` passes
- Build: N/A
- `kustomize build kustomize/overlay/default/amster` exits cleanly and renders `ttlSecondsAfterFinished: 7200` — PASS
- `forgeops env --help` lists `--amster-ttl AMSTER_TTL` — PASS
- `forgeops env -e testenv --amster-ttl notanumber` exits 2 with argparse type error — PASS

## Requirements Check

- [x] AC1: `--amster-ttl <n>` sets `ttlSecondsAfterFinished` in Kustomize and Helm — met for non-zero values; **unmet for value 0** (see Critical finding)
- [x] AC2: `--amster-ttl notanumber` exits non-zero before file mutations — met; verified `exit 2` with argparse error
- [x] AC4 (regression): `--amster-retain notanumber` still exits non-zero — met; `type=int` already present, not regressed
- [x] AC5 (regression): `--amster-retain <n>` writes `amster.env.DURATION` (not `amster.amsterRetain`) to Helm values — met; fix confirmed at `bin/commands/env:506-509`
- [x] NFR3: `--amster-retain` and `--amster-ttl` are distinct — met; wired to different keys and different code paths

## Findings

### Critical

- **`bin/commands/env:282` and `bin/commands/env:511`**: Both TTL guards use `getattr(args, 'amster_ttl', None)`, which evaluates to falsy when `args.amster_ttl == 0`. Kubernetes `ttlSecondsAfterFinished: 0` is a valid, commonly-used value meaning "delete the Job immediately after it finishes". A user who runs `forgeops env -e myenv --amster-ttl 0` will receive no error and no feedback — both the Kustomize patch write and the Helm values merge are silently skipped. The `amster-ttl.yaml` file is left with its previous value (or the default 7200), directly contradicting the user's intent.

  The established pattern in this file for integer arguments is `isinstance(args.X, int)` (see lines 389, 418, 441, 470, 493 for `am_rep`, `cts_rep`, `idm_rep`, `idrepo_rep`, `ig_rep`). This pattern correctly distinguishes "user passed 0" from "user did not pass the flag" (where argparse sets the value to `None`). Both guards must be changed to `isinstance(args.amster_ttl, int)` to match the repo convention and handle the 0 case correctly.

  Note: the pre-existing Helm template guard `{{- if .Values.amster.ttlSecondsAfterFinished }}` at `charts/identity-platform/templates/amster-job.yaml:18` would also suppress rendering when the value is 0, but that is a pre-existing issue outside Task 2's scope. The Python-side guard must still be correct so the user's intent is at least written into the values file.

### Important

- **`bin/commands/env:511`**: The guard `if getattr(args, 'amster_ttl', None):` is inconsistent with the guard on the same variable at `bin/commands/env:282` and with the repo-wide `isinstance(args.X, int)` convention for integer args. Even setting aside the 0 edge case, using two different idioms for the same argument in the same file is a convention violation flagged in `CODE_REVIEW_GUIDE.md` (consistency under "Code Organization"). Once the Critical fix is applied (`isinstance(args.amster_ttl, int)`), the inconsistency is also resolved.

### Suggestions

- **`bin/commands/env:341`**: The help string `'Set ttlSecondsAfterFinished on the Amster Job'` does not state the unit. The analogous `--amster-retain` description says `'Keep amster pod running for n seconds'`. Consider `'Set ttlSecondsAfterFinished (seconds) on the Amster Job'` for consistency, though this is non-blocking.

- **`bin/commands/env:511-514`**: The debug print `print(f"amster_ttl={args.amster_ttl}")` is placed inside the `if getattr(...)` block, which means a debug run with `--amster-ttl 0` would not log the value. After the guard is corrected to `isinstance`, the debug print placement should be reviewed to ensure it fires whenever the argument is present.
