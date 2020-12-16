#!/bin/sh

set -eo pipefail

QUAY_ORG=kubevirt

function get_dockerhub_tags(){
    local registry="${1}"

    result=$(wget -q https://registry.hub.docker.com/v1/repositories/${registry}/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}')

    echo "${result}"
}

function import(){
    local organization="${1}"
    local registry_tag="${2}"

    docker_origin="${organization}/${registry_tag}"
    quay_target="quay.io/${QUAY_ORG}/${registry_tag}"

    docker pull "${docker_origin}"

    docker tag "${docker_origin}" "${quay_target}"

    docker push "${quay_target}"
}

function main(){
    local organization="${1}"
    local registry="${2}"

    if [ -z "${registry}" ]; then
        echo "Please, specify an origin registry"
        exit 1
    fi

    dockerhub_tags=$(get_dockerhub_tags "${organization}/${registry}")

    while IFS= read -r tag ; do

        import "${organization}" "${registry}:${tag}"

    done <<< "${dockerhub_tags}"
}

main "$@"
