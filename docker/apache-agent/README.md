# Apache web policy agent docker image
This is base docker image for ForgeRock web policy agent running on apache 2.4
This image should be used with `forgeops/helm/apache-agent` helm chart to work correctly

## Building image
To build image, you need to download web policy agent zip file and place it into `forgeops/docker/apache-agent/agent.zip`
file. To run build process simply do: `docker build -t gcr.io/engineering-devops/apache-agent:latest`
