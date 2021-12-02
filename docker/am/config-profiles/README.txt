READ THIS FIRST!

All CDK config is now managed in the AM repository and a `am-cdk` Docker image
is produced containing the "base" AM config and the "CDK" config as two
separate immutable config layers.

Any additional "config profiles" will be added as a third mutable config layer.

Any changes to the "CDK" config MUST be made in the AM repository so that it
is maintained and provided by the `am-cdk` Docker image.
