READ THIS FIRST!

All default config is now managed in the PingAM repository and a `am-cdk` Docker image
is produced containing the "base" PingAM config and the "cdk" config as two
separate immutable config layers.

Any additional "config profiles" will be added as a third mutable config layer.

Any changes to the "cdk" config MUST be made in the PingAM repository so that it
is maintained and provided by the `am-cdk` Docker image.
