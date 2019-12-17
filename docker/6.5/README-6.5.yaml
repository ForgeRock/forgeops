# Docker images for 6.5

## Base images

The base image folders (for example, am-base) are the "parent" docker images used by the derived child image (example, am). You
must build your own base images as a pre-requistite to deploying the child images.

The images do not contain ForgeRock binaries. You must download the appropriate war or zip file
artifact from [ForgeRock Backstage](https://backstage.forgerock.com/downloads) and copy
the artifact to the appropriate -base folder. The artifact should be named according to the following table:

| base image | artifact name |
| --- | --- |
openam-base | openam.war
amster-base | amster.zip
ds-base | opendj.zip
idm-base | openidm.zip
ig-base | openig.war


To build the base image, you can use the `docker build` command. For example:

  ```bash
  cd docker/6.5
  docker build -t am-base am-base
  ```

A skaffold profile is also provided. You can build the base images using:

```
# The default-repo should be replaced with your own repository that hosts your images
skaffold -f skaffold-6.5.yaml -p base --default-repo gcr.io/engineering-devops build
```

