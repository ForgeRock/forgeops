# Holistic Review — FORGEOPS-6313

## Verdict

APPROVE

## Summary

FORGEOPS-6313 delivers five cohesive changes: tracking and wiring the Amster TTL patch file, adding
`--amster-ttl` to `forgeops env`, adding `--ds-set-passwords-ttl` to `forgeops env`, fixing the
Helm `amster-job.yaml` template so that `amster.env.DURATION` reaches the pause container, and
removing "infinity" from the `apply` help text. All nine acceptance criteria in `requirements.md`
are independently verified as met. The integrated change is internally consistent, the
cross-cutting merge path is correct, and `kustomize build`, `helm lint`, and `python3 -m
py_compile` all pass. One important cross-cutting observation is noted below (not blocking); the
three suggestions carried forward from per-task review are consolidated here.

## Verification

- Tests: NOT_RUN — repo has no automated test suite (confirmed in CLAUDE.md)
- Lint: PASS — `helm lint charts/identity-platform` (0 chart(s) failed); `bash -n
  bin/commands/apply` (exit 0)
- Typecheck: PASS — `python3 -m py_compile bin/commands/env` (no syntax errors)
- Build: PASS — `kustomize build kustomize/overlay/default/amster` renders
  `ttlSecondsAfterFinished: 7200`; `kustomize build kustomize/overlay/default/ds-set-passwords`
  renders `ttlSecondsAfterFinished: 7200`; `helm template identity-platform
  charts/identity-platform` renders `AMSTER_DURATION: "10"` on the pause container and
  `ttlSecondsAfterFinished: 7200` on both Jobs.

## Requirements Check

- [x] AC1: `forgeops env -e <env> --amster-ttl <n>` sets `spec.ttlSecondsAfterFinished: <n>` in
  both Kustomize (`amster-ttl.yaml` patch write in `process_overlay_dir`, line 282–291) and Helm
  (`values_amster` merge at line 523–526, rendered by `amster-job.yaml:18–19`). Verified by
  `helm template --set amster.ttlSecondsAfterFinished=300` outputting `ttlSecondsAfterFinished:
  300`, and `kustomize build` rendering the correct value after a write.
- [x] AC2: `forgeops env -e <env> --amster-ttl notanumber` exits 2 with argparse type error before
  any file mutations — guaranteed by `type=int` at `bin/commands/env:352`.
- [x] AC3: `grep infinity bin/commands/apply` returns no match — line 33 deletion confirmed in
  diff and verified independently.
- [x] AC4: `forgeops env -e <env> --amster-retain notanumber` exits 2 — `type=int` on
  `--amster-retain` at line 351 is unchanged; no regression.
- [x] AC5: `git ls-files kustomize/overlay/default/amster/amster-ttl.yaml` returns the path;
  `shutil.copytree` propagation confirmed by presence of file in tracked `default` overlay.
- [x] AC6: `kustomize/overlay/default/amster/kustomization.yaml` contains `patches` block with
  `path: amster-ttl.yaml`, `target.kind: Job`, `target.name: amster` — confirmed by direct read.
- [x] AC7: `--amster-retain <n>` writes `AMSTER_DURATION` to `platform-config.yaml` via
  `bin/commands/env:186–187` (Kustomize path) — unchanged, no regression.
- [x] AC8: `--amster-retain <n>` now writes `amster.env.DURATION` (not `amster.amsterRetain`) to
  Helm values — confirmed at `bin/commands/env:518–521`; `amsterRetain` key removed from
  `values_amster` dict.
- [x] AC9: Helm `amster-job.yaml` renders `Values.amster.env.DURATION` as `name: AMSTER_DURATION`
  on the pause container — confirmed by `helm template` default output producing `env: [{name:
  AMSTER_DURATION, value: "10"}]`.

## Cross-Cutting Analysis

### Design coherence

The three independent write paths for TTL values (Kustomize `amster-ttl.yaml`, Kustomize
`ds-set-passwords-ttl.yaml`, Helm `amster.ttlSecondsAfterFinished` / `ds_set_passwords.ttlSecondsAfterFinished`)
are cleanly separated by mode flags (`--no-helm`, `--no-kustomize`) in the surrounding
`manage_env` logic. The `isinstance(args.X, int)` guard pattern is consistently applied to all
four new integer arguments (`amster_ttl` in both `process_overlay_dir` and `manage_env`,
`ds_set_passwords_ttl` in both locations). The `mergedeep.merge` call at line 774 correctly
accumulates `values_amster` and `values_ds_set_passwords` without key conflicts, verified by
tracing the merge path for every argument combination (TTL-only, retain-only, both).

### Helm env precedence — behavioral change for existing Helm deployments

`app-code` — **Important**

The new `env:` block on the pause container (`amster-job.yaml:127–131`) introduces an explicit
`AMSTER_DURATION` env var that will **take precedence over** any `AMSTER_DURATION` supplied by the
`platform-config` ConfigMap via `envFrom` (Kubernetes env var precedence: explicit `env:` overrides
`envFrom`). Before this change, users who set `AMSTER_DURATION` in their `platform-config`
ConfigMap via Kustomize (the `--amster-retain` Kustomize path) and then deployed with Helm would
have had their ConfigMap value honoured. After this change, the Helm chart's
`amster.env.DURATION` value (defaulting to `"10"`) will always shadow the ConfigMap value unless
the user explicitly overrides `amster.env.DURATION` in their Helm values.

In practice the overlap scenario is unlikely — Kustomize and Helm modes are mutually exclusive for
a given environment — and the `"10"` default matches the pause container's own fallback
(`${AMSTER_DURATION:-10}`). Nevertheless the behaviour change is real and is not documented in
`values.yaml` or the chart's `README`. Existing Helm users who had customised `AMSTER_DURATION`
in `platform-config` will silently have it overridden by the chart default after upgrading.

Mitigation: The impact is limited to Helm-mode deployments that relied on `platform-config` to
supply `AMSTER_DURATION`. Users can work around this by setting `amster.env.DURATION` in their
`values.yaml`. The behaviour is not wrong by design — it is the intended effect of this story —
but the precedence consequence deserves a comment in `amster-job.yaml` near the new `env:` block
and/or a note in the chart's `values.yaml` near `amster.env.DURATION`.

### Pre-existing Kustomize environments and missing `patches` entry

For Kustomize overlays created **before** this story is merged, the overlay's
`amster/kustomization.yaml` will not contain the `patches` entry. When a user runs `forgeops env
-e <legacy-env> --amster-ttl 300`, the `amster-ttl.yaml` file is correctly written (or created)
by `process_overlay_dir`, but the TTL patch will have **no effect** because `kustomization.yaml`
does not reference it. There is no error or warning. This is the same silent-failure scenario that
existed for any environment created before Task 1's commit. The design decision (documented in
plan.md open question 2) was to not write the `kustomization.yaml` entry dynamically — that entry
is a static artifact of the `copytree` path. This limitation is acceptable and consistent with how
the rest of the `forgeops env` overlay patching works, but it is worth documenting in the
`--amster-ttl` help string or release notes so operators of pre-existing Kustomize environments are
not confused when their TTL change does not take effect.

### QA verdict quality

The QA report is thorough: 9 AC checks plus 5 exploratory cases including edge cases `--amster-ttl
0`, combined flags, idempotency, and the `git ls-files` verification. The pre-existing Helm
`{{- if .Values.amster.ttlSecondsAfterFinished }}` falsy-guard issue for value `0` is correctly
identified and scoped out as a pre-existing defect. The observation that `--amster-retain 0` is
also silently discarded (truthy check at lines 186 and 513) is surfaced as a suggestion. The QA
PASS verdict is sound.

## Findings

### Critical

None.

### Important

- **`charts/identity-platform/templates/amster-job.yaml:127–131`** (`app-code`): The new explicit
  `env:` block renders `AMSTER_DURATION` from `amster.env.DURATION` (default `"10"`), which
  silently overrides any `AMSTER_DURATION` set in the `platform-config` ConfigMap via `envFrom`.
  While the scenario is unlikely in practice (Helm and Kustomize modes are separate), the
  precedence change is undocumented. A comment in the template near the `env:` block — e.g., `#
  Explicit env takes precedence over platform-config envFrom; set amster.env.DURATION in values to
  override` — would be sufficient. Not blocking because the override is the intended design and
  the practical impact is minimal, but it is a behavioral change that warrants documentation.

### Suggestions

- **`bin/commands/env:352–353`** (`app-code`): Both `--amster-ttl` and `--ds-set-passwords-ttl`
  help strings omit the unit (seconds) and default value (7200). Adding `(seconds, default: 7200)`
  to each would match the discoverability level of `--amster-retain` (`'Keep amster pod running
  for n seconds'`). Raised in task-2-review-iter-2 and task-3-review-iter-1; not addressed.

- **`bin/commands/env:186` and `bin/commands/env:513`** (`app-code`): The `if args.amster_retain:`
  truthy checks for `--amster-retain` silently discard value `0`, inconsistent with the new
  `isinstance(args.amster_ttl, int)` pattern applied throughout the same file for the new
  arguments. Raised in task-2-review-iter-2; acknowledged as low-risk but worth a follow-up
  `isinstance(args.amster_retain, int)` change for consistency.

- **`charts/identity-platform/templates/amster-job.yaml:18` and
  `charts/identity-platform/templates/ds-set-passwords-job.yaml:13`** (`app-code`): Both Helm
  template guards `{{- if .Values.X.ttlSecondsAfterFinished }}` suppress rendering when the value
  is `0`, meaning `--amster-ttl 0` (or `--ds-set-passwords-ttl 0`) is correctly written to the
  values file by the Python layer but silently suppressed at render time. Identified in
  task-2-review-iter-1 and QA; explicitly out of scope for this story but worth a follow-up.
