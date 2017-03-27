#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

cd ${DIR}

./openam.sh

./openidm.sh

./openig.sh

