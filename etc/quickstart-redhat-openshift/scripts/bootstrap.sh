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

EOF
systemctl start awslogs || true

if [ -f /quickstart/pre-install.sh ]
then
  /quickstart/pre-install.sh
fi

qs_enable_epel &> /var/log/userdata.qs_enable_epel.log || true

qs_retry_command 10 yum -y install jq
qs_retry_command 25 aws s3 cp ${QS_S3URI}scripts/redhat_ose-register-${OCP_VERSION}.sh ~/redhat_ose-register.sh
chmod 755 ~/redhat_ose-register.sh
qs_retry_command 25 ~/redhat_ose-register.sh ${RH_CREDS_ARN}

mkdir -p /etc/aws/
printf "[Global]\nZone = $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)\n" > /etc/aws/aws.conf
printf "KubernetesClusterTag='kubernetes.io/cluster/${AWS_STACKNAME}-${AWS_REGION}'\n" >> /etc/aws/aws.conf
printf "KubernetesClusterID=owned\n" >> /etc/aws/aws.conf

if [ "${LAUNCH_CONFIG}" != "OpenShiftEtcdLaunchConfig" ]; then
    qs_retry_command 10 yum install docker-client-1.13.1 docker-common-1.13.1 docker-rhel-push-plugin-1.13.1 docker-1.13.1 -y
    systemctl enable docker.service
    qs_retry_command 20 'systemctl start docker.service'
    echo "CONTAINER_THINPOOL=docker-pool" >> /etc/sysconfig/docker-storage-setup
    echo "DEVS=/dev/xvdb" >> /etc/sysconfig/docker-storage-setup
    echo "VG=docker-vg" >>/etc/sysconfig/docker-storage-setup
    echo "STORAGE_DRIVER=devicemapper" >> /etc/sysconfig/docker-storage-setup
    systemctl stop docker
    rm -rf /var/lib/docker
    docker-storage-setup
    qs_retry_command 10 systemctl start docker
fi

qs_retry_command 10 cfn-init -v  --stack ${AWS_STACKNAME} --resource ${LAUNCH_CONFIG} --configsets quickstart --region ${AWS_REGION}
qs_retry_command 10 yum install -y wget atomic-openshift-docker-excluder atomic-openshift-node \
    atomic-openshift-sdn-ovs ceph-common conntrack-tools dnsmasq glusterfs \
    glusterfs-client-xlators glusterfs-fuse glusterfs-libs iptables-services \
    iscsi-initiator-utils iscsi-initiator-utils-iscsiuio tuned-profiles-atomic-openshift-node

systemctl restart dbus
systemctl restart dnsmasq
qs_retry_command 25 ls /var/run/dbus/system_bus_socket
systemctl restart NetworkManager
systemctl restart systemd-logind

cd /tmp
qs_retry_command 10 wget https://s3-us-west-1.amazonaws.com/amazon-ssm-us-west-1/latest/linux_amd64/amazon-ssm-agent.rpm
qs_retry_command 10 yum install -y ./amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
rm ./amazon-ssm-agent.rpm

if [ -f /quickstart/post-install.sh ]
then
  /quickstart/post-install.sh
fi
