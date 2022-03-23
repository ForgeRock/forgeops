#!/usr/bin/env bash
# Script uses port-forwarding to connect to either Prometheus or Grafana.
# Use connect-prometheus.sh -P to connect to Prometheus. Type localhost:9090 to access Prometheus UI.
# Use connect-prometheus.sh -G to connect to Grafana. Type localhost:3000 to access Grafana UI.
# Use connect-prometheus.sh -A to connect to Alertmanager. Type localhost:9093 to access Alertmanager UI.
# Script defaults to monitoring namespace and the ports mentioned above but can be overriden. Run connect-prometheus.sh -h for guidance.

USAGE="Usage: $0: [-G | -P | -A] [-n <namespace>] [-p <port>]"

if [ $# -lt 1 ] || [ $1 == "-h" ];then
    echo "Usage: $0 [-G | -P] -n <namespace>\n"
    echo "-G                port-forward to Grafana"
    echo "-P                port-forward to Prometheus"
    echo "-A                port-forward to Alertmanager"
    echo "-n <namespace>    namespace"
    echo "-p <port>         port"
    exit
fi

while getopts :GPAn:p: option; do
    case "${option}" in
        G) GRAFANA=1;;
        P) PROMETHEUS=1;;
        A) ALERTMANAGER=1;;
        n) NAMESPACE=${OPTARG};;
        p) PORT=${OPTARG};;
        \?) echo "Error: Incorrect usage"
            echo $USAGE
            exit 1;;
    esac
done

if [[ $2 != "-n" ]]; then
    NAMESPACE=monitoring
fi

# Check if both optional flags have been included
if [[ $GRAFANA -eq 1 ]] && [[ $PROMETHEUS -eq 1 ]]; then
    echo "Invalid choice: Must select EITHER option -G to connect to Grafana or -P to to connect to Prometheus"
    echo $USAGE
    exit 1
fi

# Port forward to Grafana
if [[ $GRAFANA -eq 1 ]]; then
    # check to see if port arg was set
    if ! [[ $PORT ]]; then
        PORT=3000
    fi

    kubectl port-forward $(kubectl get  pods --selector="app.kubernetes.io/name=grafana" --field-selector status.phase=Running --output=jsonpath="{.items..metadata.name}" --namespace=$NAMESPACE) $PORT:3000 --namespace=$NAMESPACE
fi

# Port forward to Grafana
if [[ $PROMETHEUS -eq 1 ]]; then
    # check to see if port arg was set

    if ! [[ $PORT ]]; then
        PORT=9090
    fi

    kubectl port-forward $(kubectl get  pods --selector="app.kubernetes.io/name=prometheus" --output=jsonpath="{.items..metadata.name}" --namespace=$NAMESPACE) $PORT:9090 --namespace=$NAMESPACE
fi

# Port forward to Alertmanager
if [[ $ALERTMANAGER -eq 1 ]]; then
    # check to see if port arg was set
    if ! [[ $PORT ]]; then
        PORT=9093
    fi

    kubectl port-forward  $(kubectl get  pods --selector="app.kubernetes.io/name=alertmanager" --output=jsonpath="{.items..metadata.name}" --namespace=$NAMESPACE) $PORT:9093 --namespace=$NAMESPACE
fi

echo "Incorrect usage: "
echo $USAGE

