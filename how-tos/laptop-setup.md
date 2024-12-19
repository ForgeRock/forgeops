# Setting up your laptop or local environment

## Introduction

This document is designed to help folks, who are new to ForgeOps, get their
local environment setup. It requires some extra Python libraries, and some
explanation of some basics.

## Clone git repo

There are a couple of options your organization may have to set up it's git
repos to run ForgeOps and store the configs. Ask your senior admin(s) for the
details about your organization's git repos.

### ForgeOps Fork

The first and most common method is to create a fork of the official ForgeOps
repo on GitHub. In this method, all of the configurations are stored in this
fork. It requires that someone on your team needs to merge in changes as new
versions of ForgeOps are published.

Then you clone your organization's fork into a folder on your laptop. Your team
may have a common path everyone does this in so that some shared configuration
can work. If not, just clone it into your home dir somewhere. We'll assume
you're just working in your home dir instead of a team path.

For this example, we assume your fork is on GitHub at https://github.com/MyOrg/forgeops.

```
cd ~
mkdir -p git
cd git
git clone -b main https://github.com/MyOrg/forgeops.git
cd forgeops
```

Now you are in your local clone of your organization's fork. This is where you
will work with the `forgeops` command.

### Separate Artifact Repository

Another way your organization may do things is to have a separate repo that
stores all of the artifacts managed by `forgeops`. In this scenario, you may
have an organizational fork of the ForgeOps repo like above, or your team may
just use the official repo. The only thing that's changed in here is
`forgeops.conf`. The ForgeOps tool allows you to specify alternate paths to
your configurations. This allows you to avoid merge conflicts when upgrading
ForgeOps. Your team may have one checked into git (fork repo), or you may need
to set it up for your laptop (official repo).

Ask your senior admin(s) for more details if your team uses this method.

Once you have cloned your organization's ForgeOps and artifact repos, cd into
the ForgeOps repo.

## Python Setup

There are a few steps to setting up Python to run `forgeops`. First we must cd
into our forgeops checkout.

`cd /path/to/forgeops`

### Python Virtual Environment

The official recommendation of the Python team is to use a virtual environment
for each set of code, and install your libraries into that. This is the
recommended way to run ForgeOps.

The common way to create a Python virtual environment (venv) is to use the venv
module to create it in .venv in the root of your code base. This keeps all of
the venv pieces isolated to this folder instead of getting mixed into the code.

`python3 -m venv .venv`

After you've created the venv, you'll need to activate it. You need to activate
and deactivate the venv per terminal.

`source .venv/bin/activate`

This sets up .venv as a Python root with bin, lib, and include folders. It also
creates an alias in your shell in this terminal called `deactivate`. Just call
that if you want to get out of the venv.

Now you are inside of your venv, and you can use python and pip normally here.
You won't have to use them directly because we have a command to do it for you.

### Run configure

We have created the `configure` command that will install the libraries required
to run `forgeops`. It also creates
`/path/to/forgeops/lib/dependencies/.configured_version` that is used by the
family of forgeops commands to ensure the proper libraries have been installed.

`./bin/forgeops configure`

Now your local clone of the forgeops git repo is ready to run `forgeops`.

#### Without a virtual environment

It is possible to run `configure` outside of a venv. However, if the Python
environment in your system has the EXTERNALLY_MANAGED file, then you may need
to run ./bin/forgeops configure command with the --break-system-packages
option, though it is NOT RECOMMENDED.

`./bin/forgeops configure --break-system-packages`

This method is best for CI/CD pipelines where you are using ephemeral
instances, and it doesn't matter if you contaminate the system Python.

## Running ForgeOps

We have documentation on running ForgeOps in this <a href="how-tos">how-tos</a>
folder and in our official <a href="https://docs.pingidentity.com/forgeops">Documentation</a>.
The official documentation covers using ForgeOps generally, while the how-tos are
targeted at specific tasks.
