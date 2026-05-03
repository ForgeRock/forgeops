# QA Report

## Verdict: PASS

## Test Results

- Existing tests: NOT_RUN — repo has no automated test suite (confirmed in CLAUDE.md: "No automated test suite exists — validation is manual via Helm/Kustomize deployment.")
- New tests written: 0 formal test files; verification performed via 20+ direct execution checks (documented below)

## Acceptance Criteria Verification

1. **AC1 — `forgeops env -e <env> --amster-ttl <n>` sets `spec.ttlSecondsAfterFinished: <n>` in both Kustomize and Helm modes**: PASS
   - Kustomize: `bin/forgeops env -e qa-ttl-test --fqdn qa.example.com --skip-issuer --no-helm --amster-ttl 300 --testing` created `kustomize/overlay/qa-ttl-test/amster/amster-ttl.yaml` with `value: 300`. `kustomize build kustomize/overlay/qa-ttl-test/amster` rendered `ttlSecondsAfterFinished: 300`.
   - Helm: `bin/forgeops env -e qa-helm-test --no-kustomize --amster-ttl 300 --testing` wrote `amster.ttlSecondsAfterFinished: 300` to `helm/qa-helm-test/values.yaml`. `helm template ... -f helm/qa-helm-test/values.yaml` rendered `ttlSecondsAfterFinished: 300` on the Amster Job spec.

2. **AC2 — `forgeops env -e <env> --amster-ttl notanumber` exits non-zero without modifying files**: PASS
   - Executed: `bin/forgeops env -e testenv-qa --amster-ttl notanumber`
   - Exit code 2, argparse error: `argument --amster-ttl: invalid int value: 'notanumber'`. No files modified.

3. **AC3 — `apply` help text no longer mentions "infinity"**: PASS
   - `grep "infinity" bin/commands/apply` returns no matches (exit 1).
   - `bin/forgeops apply --help` output contains `-a|--amster-retain <n>      : keep amster pod running for n seconds. (default: 10)` — description retained without "infinity".

4. **AC4 — `forgeops env -e <env> --amster-retain notanumber` exits non-zero (regression)**: PASS
   - Executed: `bin/forgeops env -e testenv-qa --amster-retain notanumber`
   - Exit code 2, argparse error: `argument --amster-retain: invalid int value: 'notanumber'`. No regression.

5. **AC5 — `kustomize/overlay/default/amster/amster-ttl.yaml` is tracked in git; new env via `forgeops env` inherits it**: PASS
   - `git ls-files kustomize/overlay/default/amster/amster-ttl.yaml` returns the path.
   - `bin/forgeops env -e qa-newenv --skip-issuer --no-helm --testing` created `kustomize/overlay/qa-newenv/amster/amster-ttl.yaml` with `value: 7200` via `shutil.copytree`.

6. **AC6 — `kustomize/overlay/default/amster/kustomization.yaml` has `patches` entry with `target: {kind: Job, name: amster}`**: PASS
   - File content confirmed: `patches: [{path: amster-ttl.yaml, target: {kind: Job, name: amster}}]`
   - `kustomize build kustomize/overlay/default/amster` exits 0 with `ttlSecondsAfterFinished: 7200`.

7. **AC7 — `forgeops env -e <env> --amster-retain <n>` sets `AMSTER_DURATION` in Kustomize `platform-config.yaml` (regression)**: PASS
   - `bin/forgeops env -e qa-retain-kustomize --skip-issuer --no-helm --amster-retain 120 --testing` wrote `AMSTER_DURATION: '120'` to `kustomize/overlay/qa-retain-kustomize/base/platform-config.yaml`.

8. **AC8 — `forgeops env -e <env> --amster-retain <n>` writes `amster.env.DURATION` (not `amster.amsterRetain`) to Helm values; pause container renders `sleep <n>`**: PASS
   - `bin/forgeops env -e qa-helm-retain --no-kustomize --amster-retain 60 --testing` wrote `amster.env.DURATION: '60'` to `helm/qa-helm-retain/values.yaml`. Key `amster.amsterRetain` absent.
   - `helm template ... -f helm/qa-helm-retain/values.yaml` rendered `env: [{name: AMSTER_DURATION, value: "60"}]` on the pause container.

9. **AC9 — Helm `amster-job.yaml` renders `Values.amster.env.DURATION` into pause container `env:` as `name: AMSTER_DURATION`**: PASS
   - `helm template identity-platform charts/identity-platform` (default values, `amster.env.DURATION: "10"`) rendered `env: [{name: AMSTER_DURATION, value: "10"}]`.
   - `helm template --set amster.env.DURATION=60` rendered `value: "60"`.
   - `helm template --set 'amster.env.DURATION='` omits the `env:` block (conditional guard works). Confirmed the single match for `AMSTER_DURATION` in that output is the `args` shell reference (`sleep ${AMSTER_DURATION:-10}`), not an `env:` entry.
   - `helm lint charts/identity-platform` passes (0 chart(s) failed).

## Exploratory Testing

**Edge case: `--amster-ttl 0` (immediate job deletion after completion)**

Both the Kustomize write path and the Helm write path correctly handle `--amster-ttl 0` due to the `isinstance(args.amster_ttl, int)` guard:
- Kustomize: `kustomize/overlay/qa-ttl-zero/amster/amster-ttl.yaml` written with `value: 0`. Verified.
- Helm: `helm/qa-helm-ttl-zero/values.yaml` written with `amster.ttlSecondsAfterFinished: 0`. Verified.

However, the pre-existing Helm template guard `{{- if .Values.amster.ttlSecondsAfterFinished }}` (line 18 of `amster-job.yaml`) evaluates to false for the integer value `0`, so the Helm-rendered Job spec will not contain `ttlSecondsAfterFinished: 0` even when the value is correctly written by `forgeops env`. Confirmed by running `helm template --set amster.ttlSecondsAfterFinished=0`. This is a pre-existing template defect explicitly noted in task-2-review-iter-1 as out of scope for this story.

**Edge case: `--ds-set-passwords-ttl` end-to-end**

Verified the full flow for the ds-set-passwords TTL path:
- `kustomize/overlay/default/ds-set-passwords/ds-set-passwords-ttl.yaml` is tracked in git with `value: 7200`.
- `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` has the `patches` block with `target: {kind: Job, name: ds-set-passwords}`.
- `kustomize build kustomize/overlay/default/ds-set-passwords` renders `ttlSecondsAfterFinished: 7200`.
- `bin/forgeops env -e qa-ds-ttl --ds-set-passwords-ttl 600 --no-helm --testing` wrote `value: 600`; `kustomize build` rendered `ttlSecondsAfterFinished: 600`.
- `bin/forgeops env -e qa-ds-helm --ds-set-passwords-ttl 600 --no-kustomize --testing` wrote `ds_set_passwords.ttlSecondsAfterFinished: 600`; Helm template renders it.
- `bin/forgeops env -e testenv-qa --ds-set-passwords-ttl notanumber` exits 2.

**Combined `--amster-ttl` + `--amster-retain` on Helm path**

`bin/forgeops env -e qa-helm-combined --amster-ttl 300 --amster-retain 120 --no-kustomize --testing` wrote:
```yaml
amster:
  env:
    DURATION: '120'
  ttlSecondsAfterFinished: 300
```
Helm template rendered both `ttlSecondsAfterFinished: 300` and `env: [{name: AMSTER_DURATION, value: "120"}]` correctly.

**Idempotency: omitting `--amster-ttl` on update does not mutate file**

Ran `forgeops env` on an existing overlay that had `value: 900` in `amster-ttl.yaml` without passing `--amster-ttl`. The file was not modified (value remained 900). Correct.

**`git ls-files` verification**

All four newly tracked files confirmed:
```
kustomize/overlay/default/amster/amster-ttl.yaml
kustomize/overlay/default/amster/kustomization.yaml
kustomize/overlay/default/ds-set-passwords/ds-set-passwords-ttl.yaml
kustomize/overlay/default/ds-set-passwords/kustomization.yaml
```

## Deviation Review

One deviation was found and fixed during the development cycle (documented in task-2-review-iter-1, resolved in task-2 fix iteration 1):

**Task 2, iteration 1 — Critical finding resolved**: Both `--amster-ttl` guards initially used `getattr(args, 'amster_ttl', None)` (falsy truthiness check), silently discarding the valid Kubernetes value `--amster-ttl 0`. Fixed to `isinstance(args.amster_ttl, int)` in both locations (`bin/commands/env:282` and `bin/commands/env:511`), consistent with the `am_rep`, `cts_rep`, `idm_rep`, `idrepo_rep`, `ig_rep` pattern. The fix was verified by QA above (both Kustomize and Helm paths correctly write `ttlSecondsAfterFinished: 0`).

No other deviations were recorded across all five tasks and their review iterations. All tasks were approved. No behavioral issues introduced by auto-fixes; scope classification was appropriate throughout.

## Issues Found

None.

## Suggestions

- **Pre-existing: Helm template falsy guard for `ttlSecondsAfterFinished: 0`** — `charts/identity-platform/templates/amster-job.yaml:18` uses `{{- if .Values.amster.ttlSecondsAfterFinished }}`, which suppresses rendering when the value is `0`. The Python side now correctly writes `0` to the values file (thanks to the `isinstance` fix), but the Helm template will not render it. The same pattern exists at `ds-set-passwords-job.yaml:13`. A follow-up to change both to `{{- if not (eq .Values.amster.ttlSecondsAfterFinished nil) }}` or `{{- if (ne .Values.amster.ttlSecondsAfterFinished nil) }}` would make the full `--amster-ttl 0` path functional for Helm. Not blocking — value `0` is an edge case (delete immediately), and it was explicitly out of scope for this story.

- **Pre-existing: `if args.amster_retain:` falsy check** — `bin/commands/env:186` and `bin/commands/env:513` both use truthy checks for `amster_retain`, silently discarding `--amster-retain 0`. This inconsistency with the new `isinstance(..., int)` pattern for `amster_ttl` and `ds_set_passwords_ttl` is noted in task-2-review-iter-2 suggestions. Practically low-risk (`--amster-retain 0` means "sleep 0 seconds"), but a follow-up to use `isinstance` would complete the consistency improvement.

- **Help strings lack units for TTL arguments** — `--amster-ttl` reads `'Set ttlSecondsAfterFinished on the Amster Job'` and `--ds-set-passwords-ttl` reads `'Set ttlSecondsAfterFinished on the ds-set-passwords Job'`. Neither states the unit (seconds) or the default (7200). Adding `(seconds, default: 7200)` would improve operator discoverability, consistent with the suggestion raised in task-2-review-iter-2 and task-3-review-iter-1.
