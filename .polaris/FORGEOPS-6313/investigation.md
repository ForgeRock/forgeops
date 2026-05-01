# Investigation: FORGEOPS-6313

## Summary

The story is **ready to implement**. It adds `--amster-ttl` to `forgeops env` to control the Amster Job's `ttlSecondsAfterFinished`, and fixes two pre-existing bugs: the `--amster-retain` Helm path currently writes an unused dict key (`amster.amsterRetain`), and the Helm template for the pause container never renders `Values.amster.env.DURATION` at all, making the `amster.env.DURATION` values key a dead letter. Both bugs must be fixed as part of this story for the feature to have any effect on Helm deployments. All four changes are small, clearly scoped, and follow established codebase patterns — no architectural concerns or feasibility risks identified.

---

## Confidence

### Discussion

| Dimension | Level | Rationale |
|-----------|-------|-----------|
| Requirements sufficiency | High | ACs are clear, ambiguities resolved in discussion, implementation path confirmed by research |

### Research (requirements.md)

No explicit confidence table in requirements.md — all open questions resolved by codebase exploration.

### Planning (plan.md)

| Dimension | Level | Rationale |
|-----------|-------|-----------|
| Scope definition | High | Every file verified to exist, every line range confirmed by direct read. Clean task boundaries — no task touches another's files. |
| Feasibility | High | All changes follow established codebase patterns. No new libraries or abstractions required. |
| Estimation risk | Low | Four small, tightly scoped tasks. Task 2 is the largest (3 changes in one file) but all in adjacent, well-understood blocks. |

---

## Key Findings

### What `--amster-retain` actually controls (disambiguation)

- **Kustomize path**: `--amster-retain` writes `AMSTER_DURATION` to `platform-config.yaml`. The pause container loads this via `envFrom`. This path **works correctly today**.
- **Helm path**: `--amster-retain` writes `amster.amsterRetain` into the Helm values file — a key that does not exist in the chart. **This path has zero effect today.** The fix is to write `amster.env.DURATION` instead.
- **`--amster-ttl`** (new): controls `spec.ttlSecondsAfterFinished` on the Kubernetes Job — how long the *completed* job persists in the namespace. Distinct from `--amster-retain`.

### Kustomize TTL mechanism

`kustomize/overlay/default/amster/amster-ttl.yaml` already exists on disk with correct content (JSON Patch, `value: 7200`) but is **untracked** and **not wired** into `amster/kustomization.yaml`. The fix: commit the file and add a `patches` entry to `kustomization.yaml` with `target: {kind: Job, name: amster}`. The `forgeops env` Python code adds a new `skey == 'amster'` block in `process_overlay_dir` to write the TTL value into this file when `--amster-ttl` is passed.

### Helm TTL mechanism

`charts/identity-platform/templates/amster-job.yaml:18–19` already renders `Values.amster.ttlSecondsAfterFinished` — this path is **functional today**. The `forgeops env` fix only needs to write the correct dict key (`amster.ttlSecondsAfterFinished`, not `amster.amsterRetain`).

### Helm template bug (`amster.env.DURATION`)

`amster.env.DURATION: "10"` exists in `values.yaml:341` but **zero templates reference it**. The pause container reads `AMSTER_DURATION` from `envFrom` (platform-config ConfigMap) not from an explicit `env:` block. The fix adds a conditional `env:` block to the pause container in `amster-job.yaml:126` to render `Values.amster.env.DURATION` as `AMSTER_DURATION`. Note: `amster.env` is a YAML map (not a list like `am.env`), so the template uses a direct named-key pattern rather than `{{- toYaml . | nindent N }}`.

### "infinity" location

The word appears only in `bin/commands/apply:33` — not in `forgeops env`. One-line removal.

---

## Jira Quality Assessment

**ACs are clear and testable.** Two gaps were found and resolved during discussion:

1. "Add a string to --amster-retain will throw an error" — already satisfied by `type=int` in the Python argparse definition (`bin/commands/env:329`). No code change needed; verify as a regression check only.
2. "Help command updated to not include `infinity`" — the word lives in `bin/commands/apply`, not `forgeops env`. Scope confirmed: fix `apply`.

**Suggestion for future Jira quality**: the story title and description both say "forgeops env" but two of the four changes are in other files (`bin/commands/apply` for the infinity removal, `charts/identity-platform/templates/amster-job.yaml` for the template fix). ACs that say "the help command" rather than "forgeops env --help" would have been more precise.

---

## Recommended Next Steps

**Ready to implement.** The plan has four tasks, all High/Low confidence, no blockers. Recommend proceeding directly to `/polaris:new-project` or `/polaris:resume` in `execute` mode on this branch — the investigation artifacts are in place and `investigate → execute` continuity is supported by the Polaris workflow.

---

## Files Modified (planned)

| File | Change |
|------|--------|
| `kustomize/overlay/default/amster/amster-ttl.yaml` | Track in git (no content change) |
| `kustomize/overlay/default/amster/kustomization.yaml` | Add `patches` entry |
| `bin/commands/env` | Add `--amster-ttl` arg + Kustomize write + fix Helm `--amster-retain` key |
| `charts/identity-platform/templates/amster-job.yaml` | Add `env:` block to pause container |
| `bin/commands/apply` | Remove "infinity" from help text |
