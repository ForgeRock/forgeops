#!/usr/bin/env bash


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
    # Note this is dangerous so be careful before uncommenting
    # kubectl delete pvc --all --force --grace-period=0

    # Sometimes statefulsets linger
    # kubectl get statefulset --namespace=${NAMESPACE}
    # kubectl delete statefulset --namespace=${NAMESPACE}

    # Delete secrets
    # kubect get secrets
    # kubectl delete secrets --all

    # Delete ConfigMaps
    # kubectl delete configmap --all

    # Delete jobs that linger around
    # kubectl delete job.batch/userstore-bak-1533079800

    echo "This should show any resources...if it does then delete it manually"
    kubectl get all
}

if [ $# -lt 2 ]; then
    print_help
    exit 0
fi

parse_commandline "$@"
delete_all
