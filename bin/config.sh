#!/usr/bin/env bash
# make sure errexit is not set
set +o errexit
read -r -d '' DEP <<'EOF'
=====================
Notice of Deprecation
=====================

# What's Changed:

  ForgeOps no longer requires the "staging" of configuration profiles. This means that
  one no longer has to run "config.sh init -p cdk". Configuration is now located next
  to the Dockerfile in a directory called "config-profiles" This directory is added
  to the container when the container is built. Note that the profiles <productname>-only
  for internal teams only and shouldn't be used.

  New Tree:
  docker/am/config-profiles/
  ├── am-only
  │   └── config
  └── cdk
      └── config
  docker/amster/config-profiles/
  ├── am-only
  │   └── config
  └── cdk
      └── config
  docker/ds/config-profiles/
  └── ds-only
      └── readme.txt
  docker/idm/config-profiles/
  ├── cdk
  │   ├── conf
  │   └── ui
  └── idm-only
      ├── conf
      └── script
  docker/ig/config-profiles/
  ├── cdk
  │   └── config
  └── ig-only
      ├── config
      └── scripts

# How does this impact me?

  * You now manage config directly in the docker directory.
  * The config.sh init command is no longer required.
  * The ./bin/config.sh is no longer used.
  * Export configuration  with the new bin/config export script.
  * Subdirectories named 7.0 in the docker and kustomize directories are no longer used, except for internal legacy usage.
  * If you have scripts that reference kustomization files or docker files, modify them to use the bin/config path command.

# What should I do now?

  ## Run CDK

    If you use the cdk profile out of the box, you simply don't need to use config.sh init.
    Just run skaffold command or ./bin/cdk as outlined in the documentation.

  ## Custom Config Profile:

    If you have a custom profile in git under ./config/ you will need to do a
    one time migration.
      MYPROFILE_PATH=config/7.0/<myprofile>;
      for i in $MYPROFILE_PATH/*; do echo "git mv $i docker/$(basename $i)/config-profiles/$(basename $MYPROFILE_PATH)"; done

      example:
        ❯ MYPROFILE_PATH=config/7.0/cdk;
        for i in $MYPROFILE_PATH/*; do echo "git mv $i docker/$(basename $i)/config-profiles/$(basename $MYPROFILE_PATH)"; done
        git mv config/7.0/cdk/am docker/am/config-profiles/cdk
        git mv config/7.0/cdk/amster docker/amster/config-profiles/cdk
        git mv config/7.0/cdk/idm docker/idm/config-profiles/cdk
        git mv config/7.0/cdk/ig docker/ig/config-profiles/cdk

  ## Exporting Config:

    When you export configuration from a running IDM or AM instance, use the bin/config export command:
    ./bin/config and the subcommand of `export`

     ❯ ./bin/config export -h
     usage: config export [-h] [--sort] {am,amster,idm,ig,ds} profile

     Export config from running instance to a given profile.

     positional arguments:
       {am,amster,idm,ig,ds}
                             ForgeRock Identity Platform component.
       profile

     optional arguments:
       -h, --help            show this help message and exit
       --sort, -s            Sort configuration json alphanumerically. This will lead to a large
                             initial diff but subsequent iterations should be smaller and more readable.

     examples:
       # Export just AM configuration to myprofile
       $ ./bin/config export am myprofile

  ## Scripting and ForgeOps

    If you have script that wraps forgeops AND touch Dockerfiles, config, or kustomization then use the
    ./bin/config path subcommand to determine the path DO NOT HARDCODE A PATH
    We reserve the right to change paths at any given point and ./bin/config path is the stable interface to that.

  ## How do I use a custom profile?

    Using ./bin/cdk build --config-profile <myprofile>; ./bin/cdk install -n <mynamespace> -f <fqdn>

    If you are using the "legacy" skaffold method then add the environment variable CONFIG_PROFILE=<myprofile>
    to the shell or the command e.g. CONFIG_PROFILE=idm-only skaffold -r my.prvt.registry/forgeops

  ## How do I make a new profile?

    Assuming your baselines is CDK then:
      * Deploy CDK via the cdk install command
      * Make some changes via UI
      * Run ./bin/confg export --baseline-profile cdk <product> <profilename> for every product that you need.
      * Now follow the "How do I use a custom profile?" section


# Where's the documentation?

  Coming soon! Remember, for the master branch of the forgeops repository, documentation sometimes lags behind the latest changes.
EOF
printf "%-10s \n" "$DEP" >&2
exit 1
