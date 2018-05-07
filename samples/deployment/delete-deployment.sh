#!/usr/bin/env bash

NAMESPACE="bench"

print_help()
{
    printf 'Usage: \t%s\t[-n|--namespace <namespace>]\n' "$0"
}

parse_commandline()
{
    while test $# -gt 0
    do
        case "$1" in
            -n|--namespace)
                NAMESPACE="$2"
                shift
                ;;
            -h|--help|*)
                print_help
                exit 0
                ;;
        esac
        shift
    done
}

delete_all() 
{
    echo "=> Deleting all helm charts from \"${NAMESPACE}\""
    # Delete all charts
    helm delete --purge $(helm list -q --all --namespace=${NAMESPACE})

    # Delete all persistent volume claims
    kubectl delete pvc --all
}

parse_commandline "$@"
delete_all
