#!/bin/bash
set -euo pipefail

KUBECTL_BINARY="${KUBECTL_BINARY-"kubectl"}"
KUBECTL_OPTIONS=""
TEMP_PATH="./temp"
ONE_BY_ONE="false"
EXCLUDE_REGEX="letsencrypt|^mongo-mongodb$"
CONFIG_MAPS="${CONFIG_MAPS-"ob-official-preprod-ca"}"
IGNORE_EMPTY="${IGNORE_EMPTY-"false"}"

checkDependencies () {
    jq --version >/dev/null
    kubectl version >/dev/null
}

listClusterObjects () {

    if [ "$1" != "secret" ] && [ "$1" != "configmap" ]; then
        echo "ERROR: listClusterObjects can only accept secret or configmap as object types." >&2
        exit 40
    fi

    if [ "${2-"!"}" == "!" ]; then
        RESPONSE=$(jq -r '.items | .[] | .metadata.name' temp/all${1}s.json)
    else
        RESPONSE=$(jq -r --arg TYPE ${2} '.items | .[] | select(.type==$TYPE) | .metadata.name' temp/all${1}s.json)
    fi


    if  [ "$1" == "configmap" ]; then
        for R in $RESPONSE; do
            for C in $CONFIG_MAPS; do
                if [ "$R" == "$C" ]; then echo $C; fi
            done
        done
    else
        echo $RESPONSE
    fi

}

listPropertyNames () {
    if [ "$1" != "secret" ] && [ "$1" != "configmap" ]; then
        echo "ERROR: '$1' listProperties can only accept secret or configmap as object types." >&2
        exit 50
    fi

    if [ "$1" == "configmap" ]; then
        jq -r --arg NAME ${2} '.items | .[] | select(.metadata.name==$NAME) | .binaryData | keys[]' temp/all${1}s.json
    else
        jq -r --arg NAME ${2} '.items | .[] | select(.metadata.name==$NAME) | .data | keys[]' temp/all${1}s.json
    fi

}

decodeSecretPropertyValue () {

    if [ "$1" != "secret" ] && [ "$1" != "configmap" ]; then
        echo "ERROR: '$1' decodeSecretPropertyValue can only accept secret or configmap as object types." >&2
        exit 60
    fi

    if [ "${1}" == "secret" ]; then
        jq -r --arg NAME ${2} --arg ATTR ${3//\\/} '.items | .[] | select(.metadata.name==$NAME) | .data[$ATTR]' temp/allsecrets.json | base64 -d > ${4}
    fi

    if [ "${1}" == "configmap" ]; then
        jq -r --arg NAME ${2} --arg ATTR ${3//\\/} '.items | .[] | select(.metadata.name==$NAME) | .binaryData[$ATTR]' temp/allconfigmaps.json | base64 -d > ${4}
    fi

    if { [ "$(head -c 1 ${4})" == "" ] || [ "$(base64 ${4})" == "null" ]; } && [ "$IGNORE_EMPTY" == "false" ]; then
        echo "ERROR: decoded empty value ${3} ${4}"
        exit 30
    fi

}

getConfigPropertyValue () {
    kubectl get configmap ${1} -o jsonpath="{.data.${2}}" > ${3}
}

writeDecodedObject () {
    for ITEM in $(listClusterObjects ${1} ${3}); do
        if [[ ! "${ITEM}" =~ ${EXCLUDE_REGEX} ]]; then
            mkdir -p ${2}/${ITEM}
            for PROP in $(listPropertyNames ${1} ${ITEM}); do
                echo "[${2}/${ITEM}] ${PROP}"
                decodeSecretPropertyValue ${1} ${ITEM} ${PROP//\./\\\.} ${2}/${ITEM}/${PROP}
            done
        fi
    done

}

makeFromFiles () {
    local filesStr=""
    for F in $(find ${1}/ -maxdepth 1 -type f -path '*' ! -path "*.gpg"); do
        filesStr="${filesStr} --from-file=${F}"
    done
    echo ${filesStr}
}

createK8sObject () {

    KUBECTL_OPTIONS="$KUBECTL_OPTIONS --save-config --dry-run=client -o yaml"
    KUBECTL_OUT="${TEMP_PATH}/createmanifests/$(basename ${2}).yaml"


    case "${1}" in
        'generic')
            kubectl create secret generic $(basename ${2}) $(makeFromFiles ${2}) ${KUBECTL_OPTIONS} > ${KUBECTL_OUT}
        ;;
        'tls')
            kubectl create secret tls $(basename ${2}) --cert ${2}/tls.crt --key ${2}/tls.key ${KUBECTL_OPTIONS} > ${KUBECTL_OUT}
        ;;
        'docker')
            DOCKER_MAIL="$(jq -r '.auths | .. | .email? | select(type != "null")' ${2}/.dockerconfigjson)"
            DOCKER_USER="$(jq -r '.auths | .. | .username? | select(type != "null")' ${2}/.dockerconfigjson)"
            DOCKER_PASS="$(jq -r '.auths | .. | .password? | select(type != "null")' ${2}/.dockerconfigjson)"
            DOCKER_REGI="$(jq -r '.auths | keys[]' ${2}/.dockerconfigjson)"

            [ -z "$DOCKER_MAIL" ] && DOCKER_MAIL="$(jq -r '.auths | .. | .Email? | select(type != "null")' ${2}/.dockerconfigjson)"
            [ -z "$DOCKER_USER" ] && DOCKER_USER="$(jq -r '.auths | .. | .Username? | select(type != "null")' ${2}/.dockerconfigjson)"
            [ -z "$DOCKER_PASS" ] && DOCKER_PASS="$(jq -r '.auths | .. | .Password? | select(type != "null")' ${2}/.dockerconfigjson)"

            kubectl create secret docker-registry $(basename ${2}) \
              --docker-server=${DOCKER_REGI} \
              --docker-username=${DOCKER_USER} \
              --docker-password=${DOCKER_PASS} \
              --docker-email=${DOCKER_MAIL} ${KUBECTL_OPTIONS} > ${KUBECTL_OUT}
        ;;
        'configmap')
            kubectl create configmap $(basename ${2}) $(makeFromFiles ${2}) ${KUBECTL_OPTIONS} > ${KUBECTL_OUT}
        ;;
    esac

}

createLoop () {
    for T in ${1}/*/; do
        for D in ${T}/*/; do
            # check for empty docker, tls, or generic directory
            if [ "${D}" != "${T}/*/" ]; then
                createK8sObject $(basename ${T}) ${D}
            fi
        done
    done
}

deleteAllExisting () {
    local delStringSecrets=""
    for ITEM in $(listClusterObjects secret); do
        if [ -d ${1}/docker/${ITEM} ] || [ -d ${1}/tls/${ITEM} ] || [ -d ${1}/generic/${ITEM} ] ; then
            delStringSecrets="$delStringSecrets $ITEM"
        fi
    done

    local delStringConfigMaps=""
    for ITEM in $(listClusterObjects configmap); do
        if [ -d ${1}/configmap/${ITEM} ]; then
            delStringConfigMaps="$delStringConfigMaps $ITEM"
        fi
    done

    if [ "$delStringSecrets" != "" ]; then kubectl delete secret $delStringSecrets; fi
    if [ "$delStringConfigMaps" != "" ]; then kubectl delete configmap $delStringConfigMaps; fi

}

getDefaultImagePullSecret () {
    kubectl get serviceaccount default -o jsonpath="{.imagePullSecrets[0].name}" > ${1}/docker/defaultsecret.txt
}

setDefaultImagePullSecret () {
    local secretName=$(< ${1}/docker/defaultsecret.txt)
    if [ "${secretName}" == "" ]; then
        echo "ERROR: Default image pull secret name in defaultsecret.txt is empty."
        exit 20
    fi
    kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"${secretName}\"}]}" || true
}

usage () {
    echo "bin/getset.sh [-s|-g] <path> <label>"
    echo "    -g GET the secrets in the cluster and namespace of the current kubernetes context and store them in <path>."
    echo "       Secrets that regex match the global variable EXCLUDE_REGEX will be ignored (default is 'letsencrypt')."
    echo "       IGNORE_EMPTY=true can be defined to prevent this operation from stopping on a secret with an empty value."
    echo "       If <labelname>=<labelval> is defined then only secrets with labelled with <labelname>=<labelval> will be retrieved."
    echo ""
    echo "    -s SET the secrets in the cluster and namespace of the current kubernetes context, based on the files in <path>."
    echo "       Any secrets that already exist in the cluster AND are represented on the filesystem in <path> will be deleted"
    echo "       from the cluster before the secrets are applied. Other secrets already in the cluster are ignored."
    echo "       If <labelname>=<labelval> is defined then secrets will be created with the label of <labelname>=<labelval>."
    echo ""
    echo "<path> is path to the environment directory, where the generic, tls and docker directories are located or will be created"
    echo "       if they don't exist already."
    echo ""
    echo "NOTE: Secrets should already be decrypted (ie. bin/crypt.sh -d <path>)."
    exit 10
}

if [ "${1-"!"}" == "!" ] || [ "${2-"!"}" == "!" ]; then
    usage
fi

checkDependencies

case "${1}" in
    '-g')

        mkdir -p ${TEMP_PATH}/

        if [ "${3-"!"}" == "!" ]; then
            kubectl get secret -o json >${TEMP_PATH}/allsecrets.json
            kubectl get configmap -o json >${TEMP_PATH}/allconfigmaps.json
        else
            kubectl get secret -l${3} -o json >${TEMP_PATH}/allsecrets.json
            kubectl get configmap -l${3} -o json >${TEMP_PATH}/allconfigmaps.json
        fi

        mkdir -p ${2}/generic
        mkdir -p ${2}/tls
        mkdir -p ${2}/docker
        mkdir -p ${2}/configmap

        writeDecodedObject secret ${2}/generic Opaque
        writeDecodedObject secret ${2}/tls kubernetes.io/tls
        writeDecodedObject secret ${2}/docker kubernetes.io/dockerconfigjson
        writeDecodedObject configmap ${2}/configmap !
        getDefaultImagePullSecret ${2}
    ;;
    '-s')
        rm -Rf ${TEMP_PATH}/createmanifests || true

        mkdir -p ${TEMP_PATH}/createmanifests
        kubectl get secret -o json >${TEMP_PATH}/allsecrets.json
        kubectl get configmap -o json >${TEMP_PATH}/allconfigmaps.json
        deleteAllExisting ${2}

        createLoop ${2}
        kubectl apply -f ${TEMP_PATH}/createmanifests
        if [ "${3-"!"}" != "!" ]; then
            kubectl label -f ${TEMP_PATH}/createmanifests ${3}
        fi
        # setDefaultImagePullSecret ${2}
    ;;
    *)
        usage
    ;;
esac

echo "Completed in ${SECONDS} seconds."