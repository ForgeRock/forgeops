# Gatling image with included benchmark for forgeops deployed products

This image should be used with `forgeops/helm/gatling-benchmark` chart.

This image contains gatling as well as various benchmarks that can be
used to test your deployment.

## Create test users for simulations

To create a users for simulations it is necessary to run script to create users from a template.
To run this script, you need to execute it in your userstore (or configstore, depends what is configured as userstore).
The script script is located in  `scripts/make-users.sh`
Make sure that pod has enough memory, otherwise it might fail with OOM error.

## Adding custom simulations

In case you want to add your own simulations/test/benchmarks, you need to copy
them over to simulations folder and build your image. There are currently am
benchmarks, but we expect that more will come in future.
