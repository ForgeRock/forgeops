# Upgrade identity stack tags

The code in this folder is intended to help with:

1. Get the latest commit from forgeops stable
2. Modify dockerfiles to point to the new commits
3. Replace customer environment step values to use new commits

## Running

For example, from the top level, run:

```shell script
cd services/go/common/cmd/update_identity_stack
LOG_LEVEL=info go run update_identity_stack.go --git-root ../../../../..
```

Then commit the changes.
