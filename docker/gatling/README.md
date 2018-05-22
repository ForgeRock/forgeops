# Gatling image with included benchmark for forgeops deployed products
This image should be used with `forgeops/helm/gatling-benchmark` chart.

This image contains gatling as well as various benchmarks that can be
used to test your deployment.

## Adding custom simulations
In case you want to add your own simulations/test/benchmarks, you need to copy
them over to simulations folder and build your image. There are currently am
benchmarks, but we expect that more will come in future.
