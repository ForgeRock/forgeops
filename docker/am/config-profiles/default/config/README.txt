DO NOT ADD ANYTHING HERE!

All default config is now managed in the PingAM repository and a `am-cdk` Docker image
is produced containing the "base" PingAM config and the "cdk" config as two
separate immutable config layers.

This directory is maintained as the Lodestar/PyRock PIT/Perf testing framework
overlays config as well. All the config that is overlaid will be in a third
mutable config layer.
