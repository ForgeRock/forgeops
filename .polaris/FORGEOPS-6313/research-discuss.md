# Research: FORGEOPS-6313 — Add `--amster-ttl` to `forgeops env`

## Status
DONE

## Summary

The `--amster-retain` argument currently exists in two separate CLI entry points (`forgeops env` and
`forgeops amster`) but only controls the **pod run duration** (the `sleep` value in the pause
container via `AMSTER_DURATION`). It has no effect on the Kubernetes Job's
`ttlSecondsAfterFinished` field. There is already an `amster-ttl.yaml` patch file present in every
overlay directory, but it is not wired into any `kustomization.yaml` and is not generated or updated
by `forgeops env`. Adding `--amster-ttl` to `forgeops env` requires writing/patching this file and
then ensuring it is referenced as a patch in the overlay's `amster/kustomization.yaml`. For Helm,
the value maps cleanly to `amster.ttlSecondsAfterFinished` in `values.yaml`.

Additionally, the Jira story includes two minor fixes: adding `type=int` validation to
`--amster-retain` in `forgeops env` (it already has this), and removing the word "infinity" from
the `--amster-retain` help text (which currently only appears in the `apply` command's usage string,
not in `forgeops env`).

---

## Findings

### 1. Where `--amster-retain` is defined

There are two independent definitions:

**`bin/commands/common.sh` (bash arg parser, used by `apply`, `install`, etc.)**
- Line 92: default `AMSTER_RETAIN=10`
- Line 116: `--amster-retain) AMSTER_RETAIN=$2 ; shift 2 ;;`
- No type validation — the value is accepted as a raw string.
- Sources: `bin/commands/common.sh:92`, `bin/commands/common.sh:116`

**`bin/commands/env` (Python argparse, used by `forgeops env`)**
- Line 329: `parser.add_argument('--amster-retain', dest='amster_retain', type=int, help='Keep amster pod running for n seconds')`
- `type=int` is already present, so passing a string will already raise an argparse error.
- Source: `bin/commands/env:329`

**`bin/commands/amster` (Python argparse, used by `forgeops amster`)**
- Line 203: `parser_import.add_argument('--retain', dest='retain', default="10", type=int, ...)`
- Line 208: `parser_export.add_argument('--retain', dest='retain', default="10", type=int, ...)`
- `type=int` is already present.
- Source: `bin/commands/amster:203,208`

### 2. How `--amster-retain` flows to overlays and Helm values

**Kustomize path (via `forgeops env`):**
- `bin/commands/env:186–188` — in `process_overlay_dir()`, when `skey == 'base'` and
  `platform-config.yaml` is present, and `args.amster_retain` is set, the code writes:
  ```python
  pc['data']['AMSTER_DURATION'] = config['amsterRetain']
  ```
  to `kustomize/overlay/<env>/base/platform-config.yaml`.
- This sets the value for the `sleep ${AMSTER_DURATION:-10}` command in the **pause container** of
  the amster Job — this controls how long the pod stays running after import, not the Job TTL.
- There is no code in `forgeops env` that touches `amster-ttl.yaml` or
  `amster/kustomization.yaml`.
- Source: `bin/commands/env:186–188`

**Helm path (via `forgeops env`):**
- `bin/commands/env:494–498` — builds `values_amster = {'amster': {'amsterRetain': ...}}`.
- This is merged into the Helm `values.yaml` at line 740 via `merge(values, ..., values_amster, ...)`.
- However, there is **no `amsterRetain` key** in the Helm chart's `values.yaml` or in any Helm
  template. The Helm chart uses `amster.ttlSecondsAfterFinished` (not `amster.amsterRetain`) for
  the Job TTL and `amster.env.DURATION` for the pause container sleep value. The `values_amster`
  dict written by `forgeops env` therefore writes an unused key (`amster.amsterRetain`) into the
  Helm values file and has **no effect** on the Helm deployment.
- Sources: `bin/commands/env:494–498`, `charts/identity-platform/values.yaml:293–342`,
  `charts/identity-platform/templates/amster-job.yaml:18–19`

### 3. What Kubernetes resource controls the Amster job TTL

The field is `spec.ttlSecondsAfterFinished` on the `batch/v1 Job` resource named `amster`.

**Kustomize base** — both `kustomize/base/amster/secret-agent/amster-job.yaml` and
`kustomize/base/amster/secret-generator/amster-job.yaml` hardcode:
```yaml
spec:
  ttlSecondsAfterFinished: 7200
```
Source: `kustomize/base/amster/secret-agent/amster-job.yaml:20`,
`kustomize/base/amster/secret-generator/amster-job.yaml:20`

**Helm template** — `charts/identity-platform/templates/amster-job.yaml:18–19`:
```yaml
{{- if .Values.amster.ttlSecondsAfterFinished }}
ttlSecondsAfterFinished: {{ .Values.amster.ttlSecondsAfterFinished }}
{{- end }}
```
Default value in `charts/identity-platform/values.yaml:299`:
```yaml
ttlSecondsAfterFinished: 7200
```
Source: `charts/identity-platform/templates/amster-job.yaml:18–19`,
`charts/identity-platform/values.yaml:299`

### 4. The existing `amster-ttl.yaml` files

`amster-ttl.yaml` files exist in the `amster/` sub-directory of every overlay, including the
tracked `default` overlay. All four files have identical content — a JSON Patch fragment:
```yaml
- op: replace
  path: /spec/ttlSecondsAfterFinished
  value: 7200
```
Files found:
- `kustomize/overlay/default/amster/amster-ttl.yaml` (untracked)
- `kustomize/overlay/lee-iam/amster/amster-ttl.yaml` (untracked)
- `kustomize/overlay/8-1-test/amster/amster-ttl.yaml` (untracked)
- `kustomize/overlay/lee-api/amster/amster-ttl.yaml` (untracked)

**Critical gap:** None of the corresponding `amster/kustomization.yaml` files reference
`amster-ttl.yaml` as a patch. All four `kustomization.yaml` files contain only:
```yaml
kind: Kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
components:
- ../image-defaulter
resources:
- ../../../base/amster/secret-agent
```
The `amster-ttl.yaml` files are therefore unused dead files in every overlay.
Source: `kustomize/overlay/default/amster/kustomization.yaml:1–8`,
`kustomize/overlay/default/amster/amster-ttl.yaml:1–3`

### 5. How `forgeops env` writes values to overlays

`forgeops env` (Python) uses two mechanisms:

1. **Direct YAML mutation** — reads existing YAML files with `yaml.safe_load`, modifies specific
   keys in-memory, then writes back with `write_yaml_file()` (`yaml.dump`). Examples: patching
   `FQDN` in `base/platform-config.yaml`, patching `namespace` in `kustomization.yaml`, patching
   `ttlSecondsAfterFinished` in ingress patch files.
2. **Helm values merge** — builds Python dicts for various setting groups and calls
   `mergedeep.merge()` over the existing `helm/<env>/values.yaml`.

When creating a new overlay, it first `shutil.copytree()`s the source overlay (usually `default`)
to the new path, then processes each sub-directory recursively via `process_overlay_dir()`.
Sources: `bin/commands/env:54–289` (`process_overlay_dir`), `bin/commands/env:681–705` (create
logic), `bin/commands/env:734–741` (Helm merge).

### 6. "Infinity" in help text

The word "infinity" appears **only** in the `apply` command's usage string:
```
-a|--amster-retain <n>      : keep amster pod running for n seconds. (default: 10)
                              add "infinity" to keep up indefinitely
```
Source: `bin/commands/apply:32–33`

It does **not** appear in `forgeops env`'s `--amster-retain` help text. The `env` command simply
says: `'Keep amster pod running for n seconds'` (no mention of infinity).

The reference to "infinity" in `apply` appears to be a stale/misleading hint — the bash
`processArgs()` in `common.sh` accepts whatever string is passed for `AMSTER_RETAIN` and it would
flow to `AMSTER_DURATION` in the ConfigMap. The shell's `sleep infinity` is a valid command, so the
hint is technically functional only in that narrow bash path. However, the acceptance criteria
require removing this language.

---

## Options & Tradeoffs

### Adding `--amster-ttl` to `forgeops env` — Kustomize path

| Option | Pros | Cons | Evidence |
|--------|------|------|----------|
| Write `value` into existing `amster-ttl.yaml` + add `patches` entry to `amster/kustomization.yaml` | Uses the existing patch file pattern already present in every overlay; consistent with how ingress patches work | `amster-ttl.yaml` is currently untracked/dead in `default`; need to ensure it is present in `source` overlay before `copytree` creates new envs | `kustomize/overlay/default/amster/amster-ttl.yaml`, `kustomize/overlay/default/amster/kustomization.yaml` |
| Write `ttlSecondsAfterFinished` directly into the base `amster-job.yaml` in the overlay (if overlay has its own copy) | Simple, single-file change | Overlays currently reference the base directly, not a local copy; would require copying the base job YAML into the overlay | `kustomize/overlay/default/amster/kustomization.yaml:7–8` |
| Add a new `patches` section to `amster/kustomization.yaml` using an inline patch | No separate file needed | Less consistent with existing file-based patch pattern | N/A |

**Recommended Kustomize approach:** Wire `amster-ttl.yaml` into `amster/kustomization.yaml` in the
source overlay (add `patches: [{path: amster-ttl.yaml, target: {kind: Job, name: amster}}]`), and in
`forgeops env` write the desired TTL value into `amster-ttl.yaml` (mutate the `value` field in the
patch list), creating the file if absent.

### Adding `--amster-ttl` to `forgeops env` — Helm path

The Helm chart already supports `amster.ttlSecondsAfterFinished`. The `values_amster` dict in
`forgeops env` currently writes the wrong key (`amster.amsterRetain`). A new `--amster-ttl`
argument should produce:
```python
values_amster = {'amster': {'ttlSecondsAfterFinished': args.amster_ttl}}
```
This is a clean, low-risk change.

---

## Open Questions

1. **Should `--amster-retain` be kept as-is (controlling `AMSTER_DURATION`) and `--amster-ttl`
   added as a separate argument, or should they be merged/renamed?** The Jira story asks to add
   `--amster-ttl` as a distinct option for the Job TTL, keeping `--amster-retain` for the pod sleep
   duration. The story title says "add amster ttl option" which implies a distinct new arg.

2. **What default value should `--amster-ttl` use?** The base YAML and Helm default are both 7200
   seconds. The story says users want to set a longer TTL for CI/CD testing. If no default is
   specified, the base manifest's hardcoded 7200 applies unless the option is passed.

3. **Should `forgeops env` also ensure `amster-ttl.yaml` is present in the source overlay before
   it is copied to a new environment?** Currently `default` is the source, and it already has the
   file — but it is not wired into `kustomization.yaml`. This needs to be fixed in the default
   overlay's tracked files.

4. **The `--amster-retain` bug in the Helm path** — `values_amster` writes `amster.amsterRetain`
   which is not a recognized Helm values key and has no effect. Should this be fixed as part of
   this story, or separately? It appears to be a pre-existing bug.

5. **The bash `common.sh` `--amster-retain` still has no type validation.** The story AC says
   "Add a string to --amster-retain will throw an error". The Python `env` command already has
   `type=int`. Does this AC apply to the bash-based `apply`/`install` commands too?

---

## Sources

- Jira: FORGEOPS-6313 ("Add amster ttl option to forgeops env command plus minor improvements")
- `bin/commands/env:329` — `--amster-retain` argparse definition (type=int already present)
- `bin/commands/env:186–188` — writes `AMSTER_DURATION` to `platform-config.yaml`
- `bin/commands/env:488–498` — builds `values_amster` dict (uses wrong key `amsterRetain`)
- `bin/commands/env:734–741` — Helm merge logic
- `bin/commands/common.sh:92,116` — bash `--amster-retain` definition (no type validation)
- `bin/commands/apply:32–33` — help text containing "infinity"
- `bin/commands/amster:203,208` — `--retain` in `forgeops amster` (type=int, separate from env)
- `kustomize/base/amster/secret-agent/amster-job.yaml:20` — base Job with `ttlSecondsAfterFinished: 7200`
- `kustomize/base/amster/secret-generator/amster-job.yaml:20` — base Job with `ttlSecondsAfterFinished: 7200`
- `kustomize/overlay/default/amster/amster-ttl.yaml` — patch file, unwired, value hardcoded 7200
- `kustomize/overlay/default/amster/kustomization.yaml` — does not reference `amster-ttl.yaml`
- `charts/identity-platform/values.yaml:299` — Helm default `ttlSecondsAfterFinished: 7200`
- `charts/identity-platform/templates/amster-job.yaml:18–19` — Helm template rendering `ttlSecondsAfterFinished`
