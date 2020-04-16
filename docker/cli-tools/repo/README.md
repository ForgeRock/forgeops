# Repo Tools

A simple set of tools for managing and releasing the ForgeOps repository.

## How To Use

Pull the repo container from the engineering-devops registry
```
docker pull gcr.io/engineering-devops/repo:latest
```

Now assuming you `make` installed, from the root directory run:
```
make branch-notes
```
You can now see how your commit messages will appear for the current branch when a new release is completed.

The root level makefile simply runs the repo docker container, then runs the "target" inside the container circumventing the need for localhost to have the required software.


## Release Notes

Release notes are build with a python library that produces templated output based on commit messages.

A `.gitchangelog.rc` exists in the git root. That file controls what messages are grouped in sections, how references to tickets are inserted as well as the template that's used to render the changelog.

The change log is fairly convention commit message compliant, however not thoroughly tested  and referencing multiple tickets should be one per key (keys JIRA ticket references

### Refs

A commit messages can generate a URL to ticket if the ticket is referenced in the footer with the key of `ref` or `jira`. Multiple tickets are supported by a *single* newline and `ref` or `jira` key again.
For example:

```
this is my commit subject

this is my body

ref: CLOUD-1111
jira: CLOUD-1112
```

### BREAKING

If `BREAKING: ` is in the body of the message, it's added to the release notes just before the ticket references.
