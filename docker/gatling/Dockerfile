# Run the gatling benchmarks using gradle
FROM gcr.io/forgerock-io/java-11:latest

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 6.5.1

ADD  "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" /tmp/gradle.zip

RUN apt-get update && apt-get install -y unzip procps && \
    unzip -d /opt /tmp/gradle.zip && \
	rm /tmp/gradle.zip && \
    mv /opt/gradle-* /opt/gradle && \
	ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

WORKDIR /gatling

COPY src/ /gatling/src
COPY build.gradle /gatling
COPY *.sh /gatling

RUN gradle --no-daemon compileGatlingScala

# Using shell form instead of exec otherwise env vars do not get set
CMD /gatling/run.sh all


