# Implementation Plan

## Overview

This story makes five distinct, independently committable changes to the ForgeOps codebase:

1. **Commit the untracked `amster-ttl.yaml`** and wire it into the `default` overlay's `amster/kustomization.yaml`. This is a pure repo-state fix: the file already exists on disk with the correct content; it just needs to be tracked and wired.

2. **Add `--amster-ttl` to `forgeops env`**: a new `type=int` argparse argument that — when passed — writes the TTL value into `amster/amster-ttl.yaml` for Kustomize overlays, and into `amster.ttlSecondsAfterFinished` in the Helm values file.

3. **Add `--ds-set-passwords-ttl` to `forgeops env`**: a new `type=int` argparse argument that — when passed — writes the TTL value into `ds-set-passwords/ds-set-passwords-ttl.yaml` for Kustomize overlays, and into `ds_set_passwords.ttlSecondsAfterFinished` in the Helm values file. A new `ds-set-passwords-ttl.yaml` patch file must also be created and committed in `kustomize/overlay/default/ds-set-passwords/` (no such file exists today), and wired into `kustomize/overlay/default/ds-set-passwords/kustomization.yaml`.

4. **Fix the `--amster-retain` Helm bug**: the current code writes the unused key `amster.amsterRetain`; the correct key is `amster.env.DURATION`. Also fix the Helm template `amster-job.yaml` to render `Values.amster.env.DURATION` into an explicit `env:` block on the pause container as `AMSTER_DURATION`.

5. **Remove "infinity" from `bin/commands/apply` help text**: a one-line string change.

Tasks are ordered so that each builds on the last: the Amster Kustomize file-system baseline is fixed first (Task 1), then the Amster CLI argument (Task 2), then the DS set-passwords patch file and CLI argument (Task 3), then the Helm template fix for `amster.env.DURATION` (Task 4), then the standalone help-text cleanup (Task 5).

## Architecture Decisions

### Open question 1 — create vs mutate `amster-ttl.yaml`

The code must handle both cases: a freshly copied environment (has the file from `copytree`) and a pre-existing environment (may or may not have the file). The pattern used by the snapshot `cluster-role-name.yaml` and `role-binding.yaml` at `bin/commands/env:202–224` constructs a Python list and calls `write_yaml_file(data, path)` unconditionally — the file is always written, creating it if absent. This is the correct approach here too. The TTL patch is a list with one element (`[{'op': 'replace', 'path': '/spec/ttlSecondsAfterFinished', 'value': <int>}]`); it should be written only when `--amster-ttl` is passed.

**Decision**: write `amster-ttl.yaml` only when `--amster-ttl` is explicitly passed; otherwise leave it unchanged. This matches how all other flags in `process_overlay_dir` work — they are gated on the presence of the argument.

### Open question 2 — what happens when `--amster-ttl` is not passed

The requirements state the default is 7200 (matching the existing file content and Helm chart). If `--amster-ttl` is not passed, the existing file value is left untouched (idempotent). If `--amster-ttl` is passed, the file is written with the new value. The `kustomization.yaml` `patches` entry is always present in the committed `default` overlay; it does not need to be added at runtime.

**Decision**: do not write a default value unconditionally. Only mutate `amster-ttl.yaml` (and the Helm key) when the argument is explicitly supplied.

### Open question 3 — template guard for `amster.env.DURATION`

Use a conditional guard `{{- if .Values.amster.env.DURATION }}`. This allows the key to be suppressed by setting it to empty in user values, though in practice the default is `"10"`. The guard is consistent with how `ttlSecondsAfterFinished` is guarded at `amster-job.yaml:18`.

### Where to hook TTL mutation inside `process_overlay_dir`

`process_overlay_dir` is called recursively for all subdirectories. When it visits the `amster` directory, `skey` is `"amster"`. The TTL patch file mutation belongs in the `skey == 'amster'` branch, analogous to how `skey == 'base'` and `skey == 'keystore_create'` gate their own file mutations. The `amster-ttl.yaml` path is `path / 'amster-ttl.yaml'`. The file is written (or created if absent) with `write_yaml_file`.

When it visits the `ds-set-passwords` directory, `skey` is `"ds_set_passwords"` (hyphens replaced by underscores). The same write pattern applies: gate on `skey == 'ds_set_passwords' and isinstance(args.ds_set_passwords_ttl, int)` and write to `path / 'ds-set-passwords-ttl.yaml'`. The guard uses `isinstance(..., int)` to correctly handle value `0` (immediate deletion), consistent with the established `am_rep`, `cts_rep`, `idm_rep`, `idrepo_rep`, `ig_rep`, and `amster_ttl` pattern already in the file.

### `kustomization.yaml` `patches` entry placement

The `patches` entry is static metadata — it belongs in the committed `default` overlay's `kustomization.yaml`, not written dynamically at runtime. Once committed, it is propagated to new environments via `shutil.copytree`. For `ds-set-passwords`, the entry to add to `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` is:

```yaml
patches:
- path: ds-set-passwords-ttl.yaml
  target:
    kind: Job
    name: ds-set-passwords
```

### `--ds-set-passwords-ttl` CLI name

The naming pattern for component-scoped TTL arguments follows the component name. The Amster argument is `--amster-ttl` (matching the `amster` component). The DS set-passwords argument should be `--ds-set-passwords-ttl` (matching the `ds-set-passwords` component directory name and the `ds_set_passwords` Helm key prefix). This is consistent with how `--cts-rep`, `--idrepo-rep`, `--cts-disk` all use the component's short directory-derived name.

### `--amster-retain` Helm fix scope

The fix replaces `'amsterRetain': config['amsterRetain']` with `'env': {'DURATION': config['amsterRetain']}` inside the `amster` dict at `bin/commands/env:506–509`. The value stored in `config['amsterRetain']` is already a string (`str(args.amster_retain)`); `amster.env.DURATION` in `values.yaml:341` is also a string (`"10"`), so the type matches.

### Helm template fix — map key, not list

`amster.env` in `values.yaml` is a YAML map (`DURATION: "10"`), unlike `am.env` which is a list. The template must render it as a single named env var, not via `{{- toYaml . | nindent N }}`. The correct snippet for the pause container (after its existing `envFrom` block) is:

```yaml
          {{- if .Values.amster.env.DURATION }}
          env:
          - name: AMSTER_DURATION
            value: {{ .Values.amster.env.DURATION | quote }}
          {{- end }}
```

Placing it between the `envFrom` block and `readinessProbe` at `amster-job.yaml:121–127` is consistent with how `am-deployment.yaml:178–180` appends env vars before `envFrom`.

### DS set-passwords Helm path — template is already wired

Unlike `amster.env.DURATION` (which was an orphan key with no template reference), `ds_set_passwords.ttlSecondsAfterFinished` is already rendered by `charts/identity-platform/templates/ds-set-passwords-job.yaml:13–15` with the same conditional guard pattern as Amster. No Helm template fix is required for Task 3.

## Tasks

### Task 1: Commit `amster-ttl.yaml` and wire it into the `default` overlay's `amster/kustomization.yaml`

- **Description**: Track `kustomize/overlay/default/amster/amster-ttl.yaml` in git (it already exists with the correct content) and add a `patches` entry to `kustomize/overlay/default/amster/kustomization.yaml` so that Kustomize applies the TTL patch when building the `amster` component.
- **Scope**: Covers adding the `patches` block to `amster/kustomization.yaml` and staging `amster-ttl.yaml` for git tracking. Does not change any Python code, Helm templates, or other overlay files.
- **Files**:
  - `kustomize/overlay/default/amster/amster-ttl.yaml` — existing file, must be committed (no content change)
  - `kustomize/overlay/default/amster/kustomization.yaml` — add `patches` block
- **Acceptance Criteria**:
  - [x] `git ls-files kustomize/overlay/default/amster/amster-ttl.yaml` returns the file path (file is tracked).
  - [x] `kustomize/overlay/default/amster/kustomization.yaml` contains a `patches` list with one entry: `path: amster-ttl.yaml`, `target.kind: Job`, `target.name: amster`.
  - [x] `kustomize build kustomize/overlay/default/amster` (or equivalent) exits cleanly and the rendered Job manifest contains `ttlSecondsAfterFinished: 7200`.
  - [x] Running `forgeops env -e newenv --fqdn example.com --skip-issuer` creates `kustomize/overlay/newenv/amster/amster-ttl.yaml` with the same content.
- **Dependencies**: none
- **Status**: COMPLETED

### Task 2: Add `--amster-ttl` argument to `forgeops env` and implement Kustomize and Helm write paths

- **Description**: Add a `--amster-ttl <int>` argument to `bin/commands/env`. When supplied: (a) write the TTL patch to `amster/amster-ttl.yaml` in the Kustomize overlay via `process_overlay_dir`; (b) merge `amster.ttlSecondsAfterFinished` into the Helm values dict. Also fix the `--amster-retain` Helm bug in the same block: replace `'amsterRetain': config['amsterRetain']` with `'env': {'DURATION': config['amsterRetain']}`.
- **Scope**: Covers `setup_args()` (new argument), `manage_env()` (new `values_amster` key for TTL + fix for `--amster-retain` Helm key), and `process_overlay_dir()` (new `skey == 'amster'` block to write `amster-ttl.yaml`). Does not modify Helm templates, Kustomize base manifests, or any other command. Does not change behavior when `--amster-ttl` is not passed.
- **Files**:
  - `bin/commands/env` — three changes:
    1. `setup_args()`: add `parser.add_argument('--amster-ttl', ...)` with `type=int` immediately after the `--amster-retain` argument (line 329).
    2. `manage_env()`: in the `values_amster` block (lines 488–498), fix `amsterRetain` → `env.DURATION` and add a parallel block for `args.amster_ttl` that writes `{'amster': {'ttlSecondsAfterFinished': args.amster_ttl}}`.
    3. `process_overlay_dir()`: add a new block guarded by `skey == 'amster' and isinstance(args.amster_ttl, int)` that constructs and writes the TTL patch list to `path / 'amster-ttl.yaml'`.
- **Acceptance Criteria**:
  - [x] `forgeops env --help` lists `--amster-ttl` with a description and `type=int` behaviour.
  - [x] `forgeops env -e <env> --amster-ttl notanumber` exits non-zero with an argparse type error before modifying any files.
  - [x] After `forgeops env -e <kustomize_env> --amster-ttl 300`, `kustomize/overlay/<env>/amster/amster-ttl.yaml` contains `value: 300`.
  - [x] After `forgeops env -e <helm_env> --amster-ttl 300` (Helm mode), the environment's `values.yaml` contains `amster.ttlSecondsAfterFinished: 300`.
  - [x] After `forgeops env -e <helm_env> --amster-retain 60` (Helm mode), the environment's `values.yaml` contains `amster.env.DURATION: '60'` and does **not** contain `amster.amsterRetain`.
  - [x] When `--amster-ttl` is not passed, `amster-ttl.yaml` in an existing overlay is not modified.
- **Dependencies**: Task 1
- **Status**: COMPLETED

### Task 3: Create `ds-set-passwords-ttl.yaml`, wire it into the `default` overlay, and add `--ds-set-passwords-ttl` to `forgeops env`

- **Description**: Parallel to the Amster TTL work in Tasks 1 and 2, introduce a `ds-set-passwords-ttl.yaml` JSON Patch file in `kustomize/overlay/default/ds-set-passwords/`, wire it into the overlay's `kustomization.yaml`, and add a `--ds-set-passwords-ttl <int>` argument to `forgeops env` that writes the TTL value into both the Kustomize patch file and the Helm values key `ds_set_passwords.ttlSecondsAfterFinished`.

  Unlike the Amster case (Task 1), there is no pre-existing untracked file to commit — the `ds-set-passwords-ttl.yaml` file does not exist at all today. It must be created with default content mirroring the base manifest value of 7200.

  The Helm template at `charts/identity-platform/templates/ds-set-passwords-job.yaml:13–15` already renders `Values.ds_set_passwords.ttlSecondsAfterFinished` conditionally — no template fix is required.

- **Scope**: Covers:
  1. Creating `kustomize/overlay/default/ds-set-passwords/ds-set-passwords-ttl.yaml` with a JSON Patch list setting `ttlSecondsAfterFinished` to `7200`.
  2. Adding a `patches` block to `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` referencing the new file with `target: {kind: Job, name: ds-set-passwords}`.
  3. Adding `--ds-set-passwords-ttl` (`dest='ds_set_passwords_ttl'`, `type=int`) to `setup_args()` in `bin/commands/env`, after the `--amster-ttl` argument.
  4. Adding a `skey == 'ds_set_passwords' and isinstance(args.ds_set_passwords_ttl, int)` block to `process_overlay_dir()` that writes the TTL patch list to `path / 'ds-set-passwords-ttl.yaml'`.
  5. Adding a new `values_ds_set_passwords` dict in `manage_env()` — populated with `{'ds_set_passwords': {'ttlSecondsAfterFinished': args.ds_set_passwords_ttl}}` when `isinstance(args.ds_set_passwords_ttl, int)` — and merging it into `values` at the `merge(...)` call at `bin/commands/env:756`.

  Does not modify the Helm template, the Kustomize base manifest, or any other overlay. Does not change behavior when `--ds-set-passwords-ttl` is not passed.

- **Files**:
  - `kustomize/overlay/default/ds-set-passwords/ds-set-passwords-ttl.yaml` — new file to create
  - `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` — add `patches` block
  - `bin/commands/env` — three changes:
    1. `setup_args()`: add `--ds-set-passwords-ttl` argument after `--amster-ttl` (currently line 341).
    2. `process_overlay_dir()`: add `skey == 'ds_set_passwords'` block after the existing `skey == 'amster'` block (currently lines 282–291).
    3. `manage_env()`: add `values_ds_set_passwords` dict (populated when `isinstance(args.ds_set_passwords_ttl, int)`) and include it in the `merge(...)` call at line 756.

- **Acceptance Criteria**:
  - [ ] `kustomize/overlay/default/ds-set-passwords/ds-set-passwords-ttl.yaml` exists, is tracked in git, and contains a JSON Patch list with `op: replace`, `path: /spec/ttlSecondsAfterFinished`, `value: 7200`.
  - [ ] `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` contains a `patches` list with one entry: `path: ds-set-passwords-ttl.yaml`, `target.kind: Job`, `target.name: ds-set-passwords`.
  - [ ] `kustomize build kustomize/overlay/default/ds-set-passwords` exits cleanly and the rendered Job manifest contains `ttlSecondsAfterFinished: 7200`.
  - [ ] `forgeops env --help` lists `--ds-set-passwords-ttl` with a description and `type=int` behaviour.
  - [ ] `forgeops env -e <env> --ds-set-passwords-ttl notanumber` exits non-zero with an argparse type error before modifying any files.
  - [ ] After `forgeops env -e <kustomize_env> --ds-set-passwords-ttl 300`, `kustomize/overlay/<env>/ds-set-passwords/ds-set-passwords-ttl.yaml` contains `value: 300`.
  - [ ] After `forgeops env -e <helm_env> --ds-set-passwords-ttl 300` (Helm mode), the environment's `values.yaml` contains `ds_set_passwords.ttlSecondsAfterFinished: 300`.
  - [ ] When `--ds-set-passwords-ttl` is not passed, `ds-set-passwords-ttl.yaml` in an existing overlay is not modified.
  - [ ] Running `forgeops env -e newenv --fqdn example.com --skip-issuer` creates `kustomize/overlay/newenv/ds-set-passwords/ds-set-passwords-ttl.yaml` (propagated via `shutil.copytree` from the `default` overlay).
  - [ ] `python3 -m py_compile bin/commands/env` passes (no syntax errors).

- **Dependencies**: Task 2

### Task 4: Fix the Helm `amster-job.yaml` template to render `amster.env.DURATION` into the pause container

- **Description**: Add an `env:` block to the pause container in `charts/identity-platform/templates/amster-job.yaml` that renders `Values.amster.env.DURATION` as `name: AMSTER_DURATION`. Without this fix, writing `amster.env.DURATION` to the Helm values file (via the corrected `--amster-retain` path from Task 2) has no effect because the key is never referenced in any template.
- **Scope**: Covers only the pause container section of `amster-job.yaml` (lines 112–138 in the current file). Does not change the init container, the Job spec, other templates, or `values.yaml`. The `env:` block is conditional on the value being non-empty.
- **Files**:
  - `charts/identity-platform/templates/amster-job.yaml` — add `env:` block to the pause container after its `envFrom` block (between lines 126 and 127 in the current file).
- **Acceptance Criteria**:
  - [ ] `helm template` (or `helm lint`) against the chart with default values produces a pause container spec that includes `env: [{name: AMSTER_DURATION, value: "10"}]`.
  - [ ] `helm template` with `--set amster.env.DURATION=60` produces `value: "60"` in the pause container env.
  - [ ] `helm template` with `--set amster.env.DURATION=""` produces no `AMSTER_DURATION` env var on the pause container (conditional guard respected).
  - [ ] No other templates are modified; `helm lint` passes without warnings.
- **Dependencies**: Task 2

### Task 5: Remove "infinity" from `bin/commands/apply` help text

- **Description**: Remove the phrase `add "infinity" to keep up indefinitely` from the `--amster-retain` option description in `bin/commands/apply`.
- **Scope**: One-line string change in `apply`'s usage heredoc (line 33). No logic change, no other files.
- **Files**:
  - `bin/commands/apply` — line 33: remove the `add "infinity" to keep up indefinitely` continuation line.
- **Acceptance Criteria**:
  - [ ] `bin/forgeops apply --help` no longer contains the word "infinity" in any output.
  - [ ] `bin/forgeops apply --help` still shows `--amster-retain` with a description that includes the default value reference.
- **Dependencies**: none

## Amendments

### Amendment 1 — Add `--ds-set-passwords-ttl` option to `forgeops env`

- **Trigger**: Human-injected change after Tasks 1 and 2 were completed.
- **Decision**: Add a new `--ds-set-passwords-ttl` option to `forgeops env` that sets `ttlSecondsAfterFinished` on the `ds-set-passwords` Job, with the same default (7200) as the Amster TTL. The implementation is parallel to the Amster TTL work: create a `ds-set-passwords-ttl.yaml` patch file, wire it into the overlay's `kustomization.yaml`, add the CLI argument to `setup_args()`, add the Kustomize write block to `process_overlay_dir()`, and add the Helm write path in `manage_env()`. Key findings from codebase investigation:
  - `kustomize/base/ds/set-passwords/ds-set-passwords-job.yaml:18` already has `ttlSecondsAfterFinished: 7200` in the base manifest.
  - `kustomize/overlay/default/ds-set-passwords/kustomization.yaml` has no `patches` section today; only `components` and `resources`.
  - No `ds-set-passwords-ttl.yaml` exists in any overlay (tracked or untracked) — the file must be created from scratch.
  - `charts/identity-platform/templates/ds-set-passwords-job.yaml:13–15` already renders `Values.ds_set_passwords.ttlSecondsAfterFinished` conditionally — no Helm template fix is needed for this feature.
  - `charts/identity-platform/values.yaml:348` has `ds_set_passwords.ttlSecondsAfterFinished: 7200`.
  - `skey` for the `ds-set-passwords` directory is `ds_set_passwords` (hyphens replaced by underscores); `isDS` evaluates to `True` for it (starts with `ds`, no `snapshot`), which is harmless since the `sts.yaml` lookup is gated on file existence.
- **Tasks affected**: Former Tasks 3 and 4 (unchanged in scope) are renumbered to Tasks 4 and 5. A new Task 3 is inserted to cover the `ds-set-passwords` TTL feature.

## Confidence

| Dimension | Level | Rationale |
|-----------|-------|-----------|
| Scope definition | High | Every file is verified to exist or confirmed absent. The `ds-set-passwords-ttl.yaml` file is confirmed to not exist anywhere (no untracked file to worry about). The `kustomization.yaml` state, Helm template wiring, and `values.yaml` key are all confirmed by direct read. Task boundaries are clean: Task 3 touches only the two DS overlay files and `bin/commands/env`; Task 4 touches only `amster-job.yaml`; Task 5 touches only `apply`. |
| Feasibility | High | All changes follow patterns already established and exercised in Tasks 1 and 2. The Kustomize patch file, `kustomization.yaml` wiring, `isinstance` guard, and Helm values merge are all directly parallel to the Amster implementation. No new libraries or abstractions required. The Helm path for DS set-passwords is simpler than Amster (no template fix needed). |
| Estimation risk | Low | Task 3 is the largest new task but is a near-exact structural copy of Tasks 1+2 applied to a different component. The three sub-tasks (file create, kustomization.yaml patch, three env changes) are all small and well-understood. Tasks 4 and 5 are unchanged from the original plan and remain small. |
