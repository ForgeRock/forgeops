#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

DIR=$(pwd)

command=$1

# Optional AM web app customization script that can be run before Tomcat starts.
CUSTOMIZE_AM="${CUSTOMIZE_AM:-/home/forgerock/customize-am.sh}"
export OPENAM_HOME=${OPENAM_HOME:-/home/forgerock/openam}


run() {
    cd "${CATALINA_HOME}"
    exec tini -v -- "${CATALINA_HOME}/bin/catalina.sh" run
}


run

