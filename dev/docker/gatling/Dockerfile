
# Credit to the following article for the pattern:
# https://medium.com/de-bijenkorf-techblog/https-medium-com-annashepeleva-distributed-load-testing-with-gatling-and-kubernetes-93ebce26edbe

FROM gcr.io/forgerock-io/java-11:latest


ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 5.4.1

ADD  "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" /tmp/gradle.zip

RUN apt-get update && apt-get install -y unzip && \
    unzip -d /opt /tmp/gradle.zip && \
	rm /tmp/gradle.zip && \
    mv /opt/gradle-* /opt/gradle && \
	ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

WORKDIR /gatling

COPY src/ /gatling/src
COPY build.gradle /gatling

RUN gradle --no-daemon gatlingClasses
