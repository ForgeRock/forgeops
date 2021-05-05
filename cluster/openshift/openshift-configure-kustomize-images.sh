ACCT_ID=$(aws sts get-caller-identity | jq -r .Account)
REGISTRY="${REGISTRY:-${ACCT_ID}.dkr.ecr.us-east-1.amazonaws.com/forgeops}"

cd kustomize/overlay/7.0/openshift || exit
kustomize edit set image "amster=${REGISTRY}/amster:latest" \
                         "am=${REGISTRY}/am:latest" \
                         "ds-cts=${REGISTRY}/ds-cts:latest" \
                         "ds-idrepo=${REGISTRY}/ds-idrepo:latest" \
                         "idm=${REGISTRY}/idm:latest"
cd - || exit
