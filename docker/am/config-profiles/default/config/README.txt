DO NOT ADD ANYTHING HERE!

All CDK config is now managed in the AM repository and a `am-cdk` Docker image
is produced containing the "base" AM config and the "CDK" config as two
separate immutable config layers.

This directory is maintained as the Lodestar/PyRock PIT/Perf testing framework
overlays config as well. All the config that is overlaid will be in a third
mutable config layer.
