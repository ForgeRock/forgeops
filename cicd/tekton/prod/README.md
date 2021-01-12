# "prod" tekton deployment

Deploys the ForgeRock platform to the eng-shared "prod" namespace. This is similar to the nightly deployment
with the exception that the persistence tier (CTS and idrepo stores) are not created from scratch each night. This
demonstrates upgrading AM and IDM configurations.

