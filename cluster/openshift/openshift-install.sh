#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset -x
CLUSTER_DIR="${1}"
mkdir -p "${CLUSTER_DIR}" # build config
# TODO take config as arg
# need source dir
yq -y -s '.[0] * .[1]' cluster/openshift/installer-config.yaml \
            cluster/openshift/env/local.yaml \
            > "${CLUSTER_DIR}/install-config.yaml"

OS_NAME=$(yq -r '.metadata.name' "${CLUSTER_DIR}/install-config.yaml")
openshift-install create cluster --dir "${CLUSTER_DIR}"

for i in am idm ds-cts amster ds-idrepo ig;
do
    repo_name="forgeops/${i}"
    if [[ $(aws ecr describe-repositories --repository-names "${repo_name}" | jq '.[] | length') -ne 1 ]];
    then
        aws ecr create-repository --repository-name "${repo_name}"
    fi
done
PROFILE_ARN=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${OS_NAME}*" "Name=tag:Name,Values=*worker*" \
              | jq -r '.Reservations[].Instances[].IamInstanceProfile.Arn' \
              | uniq)
PROFILE_NAME=$(echo "${PROFILE_ARN}" | cut -d '/' -f2)
ROLE_ARN=$(aws iam get-instance-profile  --instance-profile-name "${PROFILE_NAME}" | jq -r '.InstanceProfile.Roles[].RoleName')
ROLE_NAME=$(echo "${ROLE_ARN}" | cut -d '/' -f2)
echo "attaching ${ROLE_NAME} to ${PROFILE_NAME}"
aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
echo "installation log ${CLUSTER_DIR}/.openshift_install.log"
grep "access\|kubeadmin" "${CLUSTER_DIR}/.openshift_install.log"
