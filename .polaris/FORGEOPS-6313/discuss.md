# Discussion Output

## Understanding

This story adds a new `--amster-ttl` argument to `forgeops env` to control the Kubernetes Job's `ttlSecondsAfterFinished` field — how long the completed Amster job persists in the namespace after it finishes. This is distinct from the existing `--amster-retain` argument, which controls how long the pause container sleeps while the job is running (the `AMSTER_DURATION` sleep value). Both fields must be correctly propagated to both Kustomize overlays and Helm values. The story also removes "infinity" from the `apply` command's help text.

## Jira Quality Assessment

ACs are present and mostly testable, but had two gaps identified during discussion:

1. The "add a string to --amster-retain will throw an error" AC is already satisfied in `forgeops env` (Python argparse `type=int`). No code change needed for this AC.
2. "Help command updated to not include `infinity`" refers to `bin/commands/apply`, not `forgeops env` — the research confirmed "infinity" does not appear in the `env` command at all.

A significant pre-existing bug was also found during research: `forgeops env` currently writes `amster.amsterRetain` into Helm values, but the chart has no such key. The correct keys are `amster.ttlSecondsAfterFinished` (for TTL) and `amster.env.DURATION` (for pause sleep). This must be fixed as part of this story to correctly wire both `--amster-retain` and the new `--amster-ttl` to their Helm equivalents.

## Locked Decisions

1. **`--amster-retain` and `--amster-ttl` are distinct arguments with distinct purposes**: `--amster-retain` controls the pause container sleep (`AMSTER_DURATION` / `amster.env.DURATION`); `--amster-ttl` controls `ttlSecondsAfterFinished`. Both must be correctly plumbed for Kustomize and Helm.
2. **`--amster-ttl` default is 7200**: Matches the existing base manifest and Helm chart defaults.
3. **Int validation AC is already done**: `forgeops env` already has `type=int` on `--amster-retain`. No change needed.
4. **Fix `--amster-retain` Helm bug in scope**: The current code writes `amster.amsterRetain` which has no effect. Fix to write `amster.env.DURATION`.
5. **"infinity" removal targets `bin/commands/apply`**: That is the only location where the word appears.
6. **Bash `common.sh` `--amster-retain` validation is out of scope**: The story is about `forgeops env`.

## Constraints

1. **Kustomize overlays use a patch file approach**: The existing `amster-ttl.yaml` JSON Patch fragments in each overlay should be wired into `amster/kustomization.yaml` (not duplicated or replaced with a different pattern).
2. **`forgeops env` may create new overlays by copying `default`**: The `default` overlay's `amster-ttl.yaml` must be a tracked file and wired into `kustomization.yaml` so that new environments inherit the TTL patch mechanism.
3. **Helm path must use the correct chart keys**: `amster.ttlSecondsAfterFinished` for TTL, `amster.env.DURATION` for pause sleep.

## Research Directives

1. **Confirm `amster.env.DURATION` is the correct Helm key for the pause container sleep**: Verify in `charts/identity-platform/values.yaml` and the amster-job template that this key is used to set the `DURATION` env var on the pause container, and confirm there is no other competing key.
2. **Check all tracked overlays for `amster-ttl.yaml` presence and `kustomization.yaml` state**: The research found these files in untracked overlays — confirm which overlays are tracked in git and whether any already wire the patch file.
3. **Confirm the exact structure of `amster/kustomization.yaml` patches section**: Verify the correct `target` selector for the Amster Job (kind, name) to use in the `patches` entry.
4. **Check if the `default` overlay's `amster-ttl.yaml` needs to be committed to git**: It is currently untracked — it must be tracked as the source for `shutil.copytree` to include it when creating new environments.

## Confidence

| Dimension | Level | Rationale |
|-----------|-------|-----------|
| Requirements sufficiency | High | ACs are clear, ambiguities resolved in discussion, implementation path confirmed by research |
