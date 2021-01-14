# Repository Tools

A simple set of tools for managing and releasing the ForgeOps repository.

## How To Use 

1. Make sure you have the `make` command available. If not, install it.

1. Pull the `repo` container from the `engineering-devops` registry:
    ```
    docker pull gcr.io/engineering-devops/repo:latest
    ```

1. Change to the container's root directory.
   
1. Run this command, which aggregates the commit messages for the current 
branch into release notes:
    ```
    make branch-notes
    ```
    The root level makefile runs the repo docker container, then runs the `target` 
    inside the container. This circumvents the need for localhost to have the 
    software.

## About Release Notes

Release notes are built with a Python library that produces templated output 
based on commit messages.

The `.gitchangelog.rc` file, in the root directory of the ForgeOps repository, 
controls how messages are grouped in sections, how references to tickets are 
inserted, which template is used to render the change log.

The change log is intended to adhere to the style of 
[Conventional Commit 1.0](https://www.conventionalcommits.org/en/v1.0.0/), 
however it's not 100% compliant. 

### Ticket References

A commit message can generate a URL to a ticket if the ticket is referenced in 
the commit message footer with a `ref` or `jira` key. Multiple tickets are 
supported by a *single* newline, and an additional `ref` or `jira` key (even 
though Conventional Commit specifies multiple tickets per `ref` key).

Here's an example of a commit that specifies multiple tickets:

```
this is my commit subject

this is my body

ref: CLOUD-1111
jira: CLOUD-1112
```

### Breaking Changes

If `BREAKING: ` appears anywhere in the body of a message, the message is added 
to the release notes just before the ticket references.