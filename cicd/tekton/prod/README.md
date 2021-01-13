# "prod" Tekton Deployment

This sample deploys the ForgeRock Identity Platform to the `prod` namespace in a
cluster named `eng-shared`. This sample is similar to the nightly deployment,
except that the persistence tier (`cts` and `idrepo` stores) are not created 
from scratch every night. This sample demonstrates upgrading the AM and IDM 
configurations.

