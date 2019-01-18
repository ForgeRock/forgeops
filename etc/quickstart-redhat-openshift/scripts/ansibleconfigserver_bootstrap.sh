#!/bin/bash -xe

source ${P}

export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
qs_cloudwatch_install
systemctl stop awslogs || true
cat << EOF > /var/awslogs/etc/awslogs.conf
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/messages]
buffer_duration = 5000
log_group_name = ${LOG_GROUP}
file = /var/log/messages
log_stream_name = ${INSTANCE_ID}/var/log/messages
initial_position = start_of_file
datetime_format = %b %d %H:%M:%S

[/var/log/ansible.log]
buffer_duration = 5000
log_group_name = ${LOG_GROUP}
file = /var/log/ansible.log
log_stream_name = ${INSTANCE_ID}/var/log/ansible.log
initial_position = start_of_file
datetime_format = %b %d %H:%M:%S

[/var/log/openshift-quickstart-scaling.log]
buffer_duration = 5000
log_group_name = ${LOG_GROUP}
file = /var/log/openshift-quickstart-scaling.log
log_stream_name = ${INSTANCE_ID}/var/log/openshift-quickstart-scaling.log
initial_position = start_of_file
datetime_format = %b %d %H:%M:%S
EOF
systemctl start awslogs || true

if [ -f /quickstart/pre-install.sh ]
then
  /quickstart/pre-install.sh
fi

qs_enable_epel &> /var/log/userdata.qs_enable_epel.log

qs_retry_command 10 yum -y install jq
qs_retry_command 25 aws s3 cp ${QS_S3URI}scripts/redhat_ose-register-${OCP_VERSION}.sh ~/redhat_ose-register.sh
chmod 755 ~/redhat_ose-register.sh
qs_retry_command 20 ~/redhat_ose-register.sh ${RH_CREDS_ARN}

qs_retry_command 10 yum -y install yum-versionlock

qs_retry_command 10 yum -y install ansible-${ANSIBLE_VERSION}

yum versionlock add ansible
sed -i 's/#host_key_checking = False/host_key_checking = False/g' /etc/ansible/ansible.cfg
yum repolist -v | grep OpenShift

qs_retry_command 10 pip install boto3 &> /var/log/userdata.boto3_install.log
mkdir -p /root/ose_scaling/aws_openshift_quickstart
mkdir -p /root/ose_scaling/bin
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/aws_openshift_quickstart/__init__.py /root/ose_scaling/aws_openshift_quickstart/__init__.py
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/aws_openshift_quickstart/logger.py /root/ose_scaling/aws_openshift_quickstart/logger.py
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/aws_openshift_quickstart/scaler.py /root/ose_scaling/aws_openshift_quickstart/scaler.py
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/aws_openshift_quickstart/utils.py /root/ose_scaling/aws_openshift_quickstart/utils.py
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/bin/aws-ose-qs-scale /root/ose_scaling/bin/aws-ose-qs-scale
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaling/setup.py /root/ose_scaling/setup.py

qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/predefined_openshift_vars_${OCP_VERSION}.txt /tmp/openshift_inventory_predefined_vars

pip install /root/ose_scaling

qs_retry_command 10 cfn-init -v --stack ${AWS_STACKNAME} --resource AnsibleConfigServer --configsets cfg_node_keys --region ${AWS_REGION}

echo openshift_master_cluster_hostname=${INTERNAL_MASTER_ELBDNSNAME} >> /tmp/openshift_inventory_userdata_vars
echo openshift_master_cluster_public_hostname=${MASTER_ELBDNSNAME} >> /tmp/openshift_inventory_userdata_vars

if [ "$(echo ${MASTER_ELBDNSNAME} | grep -c '\.elb\.amazonaws\.com')" == "0" ] ; then
    echo openshift_master_default_subdomain=${MASTER_ELBDNSNAME} >> /tmp/openshift_inventory_userdata_vars
fi

if [ "${ENABLE_HAWKULAR}" == "True" ] ; then
    if [ "$(echo ${MASTER_ELBDNSNAME} | grep -c '\.elb\.amazonaws\.com')" == "0" ] ; then
        echo openshift_metrics_hawkular_hostname=metrics.${MASTER_ELBDNSNAME} >> /tmp/openshift_inventory_userdata_vars
    else
        echo openshift_metrics_hawkular_hostname=metrics.router.default.svc.cluster.local >> /tmp/openshift_inventory_userdata_vars
    fi
    echo openshift_metrics_install_metrics=true >> /tmp/openshift_inventory_userdata_vars
    echo openshift_metrics_start_cluster=true >> /tmp/openshift_inventory_userdata_vars
    echo openshift_metrics_cassandra_storage_type=dynamic >> /tmp/openshift_inventory_userdata_vars
    qs_retry_command 10 yum install -y httpd-tools java-1.8.0-openjdk-headless
fi

if [ "${ENABLE_AUTOMATIONBROKER}" == "Disabled" ] ; then
    echo ansible_service_broker_install=false >> /tmp/openshift_inventory_userdata_vars
fi

if [ "${ENABLE_CLUSTERCONSOLE}" == "Disabled" ] && [ "${OCP_VERSION}" == "3.11" ] ; then
    echo openshift_console_install=false >> /tmp/openshift_inventory_userdata_vars
fi

echo openshift_hosted_registry_storage_s3_bucket=${REGISTRY_BUCKET} >> /tmp/openshift_inventory_userdata_vars
echo openshift_hosted_registry_storage_s3_region=${AWS_REGION} >> /tmp/openshift_inventory_userdata_vars

echo openshift_master_api_port=443 >> /tmp/openshift_inventory_userdata_vars
echo openshift_master_console_port=443 >> /tmp/openshift_inventory_userdata_vars

qs_retry_command 10 yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
# Workaround this not-a-bug https://bugzilla.redhat.com/show_bug.cgi?id=1187057
pip uninstall -y urllib3
qs_retry_command 10 yum -y update
qs_retry_command 10 pip install urllib3
qs_retry_command 10 yum -y install atomic-openshift-excluder atomic-openshift-docker-excluder

cd /tmp
qs_retry_command 10 wget https://s3-us-west-1.amazonaws.com/amazon-ssm-us-west-1/latest/linux_amd64/amazon-ssm-agent.rpm
qs_retry_command 10 yum install -y ./amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
rm ./amazon-ssm-agent.rpm
cd -

if [ "${GET_ANSIBLE_FROM_GIT}" == "True" ]; then
  CURRENT_PLAYBOOK_VERSION=https://github.com/openshift/openshift-ansible/archive/openshift-ansible-${OCP_ANSIBLE_RELEASE}.tar.gz
  curl  --retry 5  -Ls ${CURRENT_PLAYBOOK_VERSION} -o openshift-ansible.tar.gz
  tar -zxf openshift-ansible.tar.gz
  rm -rf /usr/share/ansible
  mkdir -p /usr/share/ansible
  mv openshift-ansible-* /usr/share/ansible/openshift-ansible
else
  qs_retry_command 10 yum -y install openshift-ansible
fi

qs_retry_command 10 yum -y install atomic-openshift-excluder atomic-openshift-docker-excluder
atomic-openshift-excluder unexclude

qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/scaleup_wrapper.yml  /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/bootstrap_wrapper.yml /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/playbooks/post_scaledown.yml /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/playbooks/post_scaleup.yml /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/playbooks/pre_scaleup.yml /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/playbooks/pre_scaledown.yml /usr/share/ansible/openshift-ansible/
qs_retry_command 10 aws s3 cp ${QS_S3URI}scripts/playbooks/remove_node_from_etcd_cluster.yml /usr/share/ansible/openshift-ansible/

ASG_COUNT=3
if [ "${ENABLE_GLUSTERFS}" == "Enabled" ] ; then
    ASG_COUNT=4
fi
while [ $(aws cloudformation describe-stack-events --stack-name ${AWS_STACKNAME} --region ${AWS_REGION} --query 'StackEvents[?ResourceStatus == `CREATE_COMPLETE` && ResourceType == `AWS::AutoScaling::AutoScalingGroup`].LogicalResourceId' --output json | grep -c 'OpenShift') -lt ${ASG_COUNT} ] ; do
    echo "Waiting for ASG's to complete provisioning..."
    sleep 120
done

export OPENSHIFTMASTERASG=$(aws cloudformation describe-stack-resources --stack-name ${AWS_STACKNAME} --region ${AWS_REGION} --query 'StackResources[? ResourceStatus == `CREATE_COMPLETE` && LogicalResourceId == `OpenShiftMasterASG`].PhysicalResourceId' --output text)

qs_retry_command 10 aws autoscaling suspend-processes --auto-scaling-group-name ${OPENSHIFTMASTERASG} --scaling-processes HealthCheck --region ${AWS_REGION}
qs_retry_command 10 aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name ${OPENSHIFTMASTERASG} --target-group-arns ${OPENSHIFTMASTERINTERNALTGARN} --region ${AWS_REGION}

/bin/aws-ose-qs-scale --generate-initial-inventory --ocp-version ${OCP_VERSION} --write-hosts-to-tempfiles --debug
cat /tmp/openshift_ansible_inventory* >> /tmp/openshift_inventory_userdata_vars || true
sed -i 's/#pipelining = False/pipelining = True/g' /etc/ansible/ansible.cfg
sed -i 's/#log_path/log_path/g' /etc/ansible/ansible.cfg
sed -i 's/#stdout_callback.*/stdout_callback = json/g' /etc/ansible/ansible.cfg
sed -i 's/#deprecation_warnings = True/deprecation_warnings = False/g' /etc/ansible/ansible.cfg

qs_retry_command 50 ansible -m ping all

ansible-playbook /usr/share/ansible/openshift-ansible/bootstrap_wrapper.yml > /var/log/bootstrap.log
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml >> /var/log/bootstrap.log
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml >> /var/log/bootstrap.log

aws autoscaling resume-processes --auto-scaling-group-name ${OPENSHIFTMASTERASG} --scaling-processes HealthCheck --region ${AWS_REGION}

qs_retry_command 10 yum install -y atomic-openshift-clients
AWSSB_SETUP_HOST=$(head -n 1 /tmp/openshift_initial_masters)

set +x
OCP_PASS=$(aws secretsmanager get-secret-value --secret-id  ${OCP_PASS_ARN} --region ${AWS_REGION} --query SecretString --output text)
ansible masters -a "htpasswd -b /etc/origin/master/htpasswd admin ${OCP_PASS}"
ansible masters -a "htpasswd -b /etc/origin/master/htpasswd forgerock ${OCP_PASS}"
set -x

mkdir -p ~/.kube/
scp $AWSSB_SETUP_HOST:/etc/origin/master/admin.kubeconfig ~/.kube/config

if [ "${ENABLE_AWSSB}" == "Enabled" ]; then
    mkdir -p ~/aws_broker_install
    cd ~/aws_broker_install
    qs_retry_command 10 wget https://raw.githubusercontent.com/awslabs/aws-servicebroker/release-${SB_VERSION}/packaging/openshift/deploy.sh
    qs_retry_command 10 wget https://raw.githubusercontent.com/awslabs/aws-servicebroker/release-${SB_VERSION}/packaging/openshift/aws-servicebroker.yaml
    qs_retry_command 10 wget https://raw.githubusercontent.com/awslabs/aws-servicebroker/release-${SB_VERSION}/packaging/openshift/parameters.env
    chmod +x deploy.sh
    sed -i "s/TABLENAME=awssb/TABLENAME=${SB_TABLE}/" parameters.env
    sed -i "s/TARGETACCOUNTID=/TARGETACCOUNTID=${SB_ACCOUNTID}/" parameters.env
    sed -i "s/TARGETROLENAME=/TARGETROLENAME=${SB_ROLE}/" parameters.env
    sed -i "s/VPCID=/VPCID=${VPCID}/" parameters.env
    sed -i "s/^REGION=us-east-1$/REGION=${AWS_REGION}/" parameters.env
    export KUBECONFIG=/root/.kube/config
    ./deploy.sh
    cd ../
    rm -rf ./aws_broker_install/
fi

rm -rf /tmp/openshift_initial_*

if [ -f /quickstart/post-install.sh ]
then
  /quickstart/post-install.sh
fi
