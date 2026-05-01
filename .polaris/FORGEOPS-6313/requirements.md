# Requirements

## Summary

FORGEOPS-6313 adds a `--amster-ttl` argument to `forgeops env` so that CI/CD engineers can
dynamically set the Kubernetes Job's `ttlSecondsAfterFinished` field, controlling how long the
completed Amster job persists in the namespace. The story also fixes a pre-existing bug where
`--amster-retain` writes an unused Helm key (`amster.amsterRetain`), and removes the word
"infinity" from the `apply` command's help text. Research confirmed that the `default` overlay's
`amster-ttl.yaml` is untracked and not wired into any `kustomization.yaml`, and that
`amster.env.DURATION` in `values.yaml` is an orphan key never rendered by any Helm template — both
must be addressed as part of this story.

## Functional Requirements

1. Add `--amster-ttl <int>` argument to `forgeops env` that sets the Amster Job's
   `ttlSecondsAfterFinished` value. — Source: Jira AC "Can set the ttl in your environment using
   forgeops env. Deployment takes this value into consideration."

2. When `--amster-ttl` is passed with a Kustomize overlay, write the TTL value into the overlay's
   `amster/amster-ttl.yaml` patch file (mutating the `value` field), and ensure the patch is wired
   into `amster/kustomization.yaml` via a `patches` entry with `target: {kind: Job, name: amster}`.
   — Source: discuss.md Constraint 1; research-discuss.md Findings §4 (`kustomize/overlay/default/amster/amster-ttl.yaml`,
   `kustomize/overlay/default/amster/kustomization.yaml`)

3. When `--amster-ttl` is passed with a Helm environment, write the value to
   `amster.ttlSecondsAfterFinished` in the Helm values file. — Source: discuss.md Locked Decision 1;
   research-discuss.md Findings §3 (`charts/identity-platform/values.yaml:299`,
   `charts/identity-platform/templates/amster-job.yaml:18–19`)

4. Fix the `--amster-retain` Helm bug: replace the current `values_amster` dict key
   `amster.amsterRetain` with the correct key `amster.ttlSecondsAfterFinished`. — Source:
   discuss.md Locked Decision 4; research-discuss.md Findings §2
   (`bin/commands/env:494–498`). NOTE: see Open Questions — the correct Helm fix for
   `--amster-retain` may be `amster.ttlSecondsAfterFinished` rather than `amster.env.DURATION`.

5. Remove the word "infinity" from the `--amster-retain` help text in `bin/commands/apply`. —
   Source: Jira AC "Help command updated to not include `infinity`"; discuss.md Locked Decision 5;
   research-discuss.md Findings §6 (`bin/commands/apply:32–33`)

6. The `--amster-retain` argument on `forgeops env` must reject non-integer input. — Source: Jira
   AC "Add a string to --amster-retain will throw an error"; discuss.md Locked Decision 3 (already
   satisfied by `type=int` at `bin/commands/env:329`; no code change required).

7. The `default` overlay's `amster-ttl.yaml` must be committed to git as a tracked file so that
   `shutil.copytree` includes it when `forgeops env` creates new environments. — Source: discuss.md
   Constraint 2; research Directive 4 (`kustomize/overlay/default/amster/amster-ttl.yaml` confirmed
   untracked via `git status`)

## Non-Functional Requirements

1. `--amster-ttl` default must be 7200 seconds to match the base manifest and Helm chart defaults.
   — Source: discuss.md Locked Decision 2; research-discuss.md Findings §3
   (`kustomize/base/amster/secret-agent/amster-job.yaml:20`, `charts/identity-platform/values.yaml:299`)

2. The Kustomize patch mechanism must use the existing `amster-ttl.yaml` file-based pattern rather
   than inline patches or alternative patch styles, for consistency with other overlay patches. —
   Source: discuss.md Constraint 1

3. The `--amster-retain` and `--amster-ttl` arguments are distinct: `--amster-retain` controls the
   pause container sleep duration (`AMSTER_DURATION`); `--amster-ttl` controls Job TTL
   (`ttlSecondsAfterFinished`). They must not be conflated. — Source: discuss.md Locked Decision 1

## Technical Context

### Helm path: `amster.env.DURATION` is an orphan key

Research Directive 1 produced a blocking finding. `amster.env.DURATION: "10"` exists in
`charts/identity-platform/values.yaml:341` but is **never referenced by any Helm template**. The
`amster-job.yaml` template's pause container (`charts/identity-platform/templates/amster-job.yaml:120`)
runs `sleep ${AMSTER_DURATION:-10}` and loads env vars from `envFrom: configMapRef: platform-config`
(`amster-job.yaml:121–123`). No template block renders `Values.amster.env` into any resource
(confirmed by exhaustive grep across all templates in `charts/identity-platform/templates/`). The
`amster.env.DURATION` key in `values.yaml` has no effect on the deployed cluster.

For the Kustomize path, `AMSTER_DURATION` is set via `data.AMSTER_DURATION` in the `platform-config`
ConfigMap, which `forgeops env` writes to `kustomize/overlay/<env>/base/platform-config.yaml`
(`bin/commands/env:187`).

### Helm path: existing `--amster-retain` bug

`bin/commands/env:494–498` writes `{'amster': {'amsterRetain': <value>}}` into the Helm values
file. There is no `amster.amsterRetain` key in the chart; the correct key for Job TTL is
`amster.ttlSecondsAfterFinished` (`values.yaml:299`). As a result, `--amster-retain` currently has
no effect on Helm deployments.

### Kustomize: only `default` overlay is tracked

Only `kustomize/overlay/default/` contains tracked files (confirmed: `git ls-files
kustomize/overlay/` returns only `default/` paths). Other overlays (`lee-iam`, `lee-api`,
`8-1-test`) are untracked user environments and are not relevant to the implementation. Only the
`default` overlay must be updated.

### Kustomize: `amster-ttl.yaml` structure and target selector

`kustomize/overlay/default/amster/amster-ttl.yaml` (currently untracked) contains a JSON Patch
fragment:
```yaml
- op: replace
  path: /spec/ttlSecondsAfterFinished
  value: 7200
```

`kustomize/overlay/default/amster/kustomization.yaml` (tracked) currently has no `patches` section.
The correct patch entry to add is:
```yaml
patches:
- path: amster-ttl.yaml
  target:
    kind: Job
    name: amster
```
The Job is named `amster` (`kustomize/base/amster/secret-agent/amster-job.yaml` metadata.name) and
kind is `Job` (batch/v1). Source: `kustomize/overlay/default/amster/kustomization.yaml`,
`kustomize/base/amster/secret-agent/amster-job.yaml`.

### `shutil.copytree` and the `default` overlay

`forgeops env` creates new environments by calling `shutil.copytree()` on the `default` overlay
(`bin/commands/env:681–705`). Because `amster-ttl.yaml` is currently untracked/absent from the
committed `default` overlay, new environments created today would not receive the file. It must be
committed to git so it is present on disk in the default overlay at the time `copytree` runs.

### `amster_retain` Kustomize path (working correctly)

`forgeops env` writes `AMSTER_DURATION` to `kustomize/overlay/<env>/base/platform-config.yaml`
(`bin/commands/env:186–188`). The pause container's `envFrom` loads `platform-config`, so this
value reaches the container. The Kustomize path for `--amster-retain` is correct and functional.

## Constraints

1. **Kustomize overlays use a patch file approach**: Wire `amster-ttl.yaml` into
   `amster/kustomization.yaml`; do not replace with inline patches or a different pattern.
   (discuss.md Constraint 1)

2. **`default` overlay's `amster-ttl.yaml` must be tracked in git**: Required for `shutil.copytree`
   to propagate the file to new environments. (discuss.md Constraint 2; Research Directive 4)

3. **Helm path must use the correct chart keys**: `amster.ttlSecondsAfterFinished` for TTL.
   (discuss.md Constraint 3; Research Directive 1 — see Open Questions re: `amster.env.DURATION`)

4. **Bash `common.sh` `--amster-retain` validation is out of scope**: This story is about `forgeops
   env` only. (discuss.md Locked Decision 6)

5. **Only one tracked overlay exists**: Only `kustomize/overlay/default/` is in git. Implementation
   only needs to update that overlay's files. (Research Directive 2)

## Acceptance Criteria

1. Running `forgeops env -e <env> --amster-ttl <n>` updates the environment so that the Amster Job
   is deployed with `spec.ttlSecondsAfterFinished: <n>` in both Kustomize and Helm modes.
   — Source: Jira AC "Can set the ttl in your environment using forgeops env. Deployment takes this
   value into consideration."

2. Running `forgeops env -e <env> --amster-ttl notanumber` raises an argparse error and exits
   non-zero without modifying any files.

3. The `apply` command's help text no longer mentions "infinity" in the `--amster-retain`
   description. — Source: Jira AC "Help command updated to not include `infinity`"

4. Running `forgeops env -e <env> --amster-retain notanumber` raises an argparse error and exits
   non-zero. — Source: Jira AC "Add a string to --amster-retain will throw an error" (already
   satisfied; verify no regression)

5. `kustomize/overlay/default/amster/amster-ttl.yaml` is committed to git and tracked. After a
   `forgeops env -e newenv` command that copies `default`, the new env contains
   `amster/amster-ttl.yaml`.

6. `kustomize/overlay/default/amster/kustomization.yaml` includes a `patches` entry referencing
   `amster-ttl.yaml` with `target: {kind: Job, name: amster}`.

7. `forgeops env -e <env> --amster-retain <n>` correctly sets `AMSTER_DURATION` in the Kustomize
   `platform-config.yaml` (existing behavior, verify no regression).

8. `forgeops env -e <env> --amster-retain <n>` no longer writes the orphan `amster.amsterRetain`
   key to the Helm values file. — Source: discuss.md Locked Decision 4

## Open Questions

1. **`amster.env.DURATION` is an orphan key with no effect** (Research Directive 1 finding):
   `discuss.md` says the fix for `--amster-retain` in Helm should write `amster.env.DURATION`.
   However, no Helm template renders `Values.amster.env` — the `AMSTER_DURATION` variable in the
   pause container is sourced from `platform-config` ConfigMap, not from a Helm env block. Writing
   `amster.env.DURATION` would have no effect on the deployed cluster. The implementer must decide
   whether to: (a) fix the template to render `amster.env` into the pause container's env section,
   making `amster.env.DURATION` functional; or (b) write `AMSTER_DURATION` into the
   `platform.configMap.data` block (analogous to what the Kustomize path does); or (c) accept that
   `--amster-retain` has no Helm equivalent and leave it with no Helm effect. This choice also
   determines which key `values_amster` should write for `--amster-retain`.

2. **Should `forgeops env --amster-ttl` create `amster-ttl.yaml` if it is absent**, or only mutate
   it if present? The `default` overlay will have the file once it is committed, and new environments
   will inherit it via `copytree`. But the code path that mutates the file should handle the
   creation case defensively in case the file is absent from an existing overlay.

3. **What happens when `--amster-ttl` is not passed?** Should `forgeops env` leave the existing
   `amster-ttl.yaml` value unchanged, or should it write the default value (7200)? This affects
   idempotency of the `forgeops env` command.
