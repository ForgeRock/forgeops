import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as eks from "@pulumi/eks";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config"

export function createStorageClasses(cluster: eks.Cluster){
    new k8s.storage.v1.StorageClass("sc-standard", {
        metadata: {
            name: "standard",
        },
        provisioner: "kubernetes.io/aws-ebs",
        parameters: {
            type: "gp2"
        }
    }, {provider: cluster.provider});

    new k8s.storage.v1.StorageClass("sc-fast", {
        metadata: {
            name: "fast",
        },
        provisioner: "kubernetes.io/aws-ebs",
        parameters: {
            type: "io1",
            fstype: "ext4",
            iopsPerGB: "10"
        }
    }, {provider: cluster.provider});

    new k8s.storage.v1.StorageClass("sc-fast10", {
        metadata: {
            name: "fast10",
        },
        provisioner: "kubernetes.io/aws-ebs",
        parameters: {
            type: "io1",
            fstype: "ext4",
            iopsPerGB: "10"
        }
    }, {provider: cluster.provider});

    new k8s.storage.v1.StorageClass("sc-nfs", {
        metadata: {
            name: "nfs",
        },
        provisioner: "kubernetes.io/aws-efs",
    }, {provider: cluster.provider});
}


export function createCluster(instanceRoles: aws.iam.Role[]): eks.Cluster{
    let cluster = new eks.Cluster(pulumi.getStack(), {
        vpcId: config.infra.vpcid,
        publicSubnetIds: config.infra.vpcPublicSubnetIds,
        privateSubnetIds: config.infra.vpcPrivateSubnetIds,
        instanceRoles: instanceRoles,
        version: config.clusterConfig.k8sVersion,
        deployDashboard: config.clusterConfig.k8sDashboard,
        endpointPrivateAccess: true,
        endpointPublicAccess: true,
        roleMappings: [
            {
                groups    : ["system:masters"],
                roleArn   : config.infra.clusterAdminRole.arn,
                username  : "pulumi:admin-usr",
            }
        ],
        skipDefaultNodeGroup: true,
    }, {dependsOn:instanceRoles});

    // Grant cluster admin access to all admins with k8s ClusterRole and ClusterRoleBinding
    new k8s.rbac.v1.ClusterRole("clusterAdminRole", {
        metadata: {
        name: "clusterAdminRole",
        },
        rules: [{
        apiGroups: ["*"],
        resources: ["*"],
        verbs: ["*"],
        }]
    }, {provider: cluster.provider});

    // Create cluster role binding for above cluster admin role
    new k8s.rbac.v1.ClusterRoleBinding("cluster-admin-binding", {
        metadata: {
        name: "cluster-admin-binding",
        },
        subjects: [{
        kind: "User",
        name: "pulumi:admin-usr",
        apiGroup: "rbac.authorization.k8s.io",
        }],
        roleRef: {
        kind: "ClusterRole",
        name: "clusterAdminRole",
        apiGroup: "rbac.authorization.k8s.io",
        },
    }, {provider: cluster.provider});

    // if (cluster.core.instanceProfile !== undefined) {
    //     new aws.iam.RolePolicyAttachment("s3-sync-policy", {
    //         policyArn: aws.iam.ManagedPolicies.AmazonS3FullAccess,
    //         role: cluster.core.instanceProfile.role
    //     },
    // );
    // };
    // if (cluster.core.cluster.roleArn !== undefined) {
    //     let eksRole = cluster.core.cluster.roleArn.apply(role => role.split("/")[1]);
    //     new aws.iam.RolePolicyAttachment("s3-sync-policy-eks", {
    //         policyArn: aws.iam.ManagedPolicies.AmazonS3FullAccess,
    //         role: eksRole
    //     },
    // );
    // };


    new k8s.core.v1.Namespace("prodNamespace", {
        metadata: {
            name: "prod"
        }},
        {provider: cluster.provider, dependsOn:cluster})

    return cluster;
}

export function createNodeGroup(nodeGroupConfig: config.nodeGroupConfiguration, cluster: eks.Cluster, instanceProfile: aws.iam.InstanceProfile,
                                labels:{[key: string]: string}, taints?: {[key: string]: any}){
    let ng = new eks.NodeGroup(`${nodeGroupConfig.namespace}Worker`, {
        amiId: nodeGroupConfig.ami,
        cluster: cluster,
        desiredCapacity: nodeGroupConfig.nodeCount,
        instanceType: nodeGroupConfig.instanceType,
        nodePublicKey: nodeGroupConfig.publickey,
        nodeAssociatePublicIpAddress: false,
        minSize: nodeGroupConfig.minNodes,
        maxSize: nodeGroupConfig.maxNodes,
        instanceProfile: instanceProfile,
        nodeRootVolumeSize: nodeGroupConfig.diskSizeGb,
        nodeSubnetIds: config.infra.vpcPrivateSubnetIds,
        cloudFormationTags: labels,
        labels: labels,
        taints: taints,
        version: config.clusterConfig.k8sVersion
    }, {dependsOn: [cluster]});

    config.infra.bastionEnable.apply(enabled => {
        if (enabled == true) {
            addSecurityGroupRule(`${nodeGroupConfig.namespace}SSH`, 22, ng.nodeSecurityGroup.id, undefined, config.infra.bastionSgId)
        }
    });
    return ng;
}


export function addSecurityGroupRule(name: string, port : number, sgId: pulumi.Output<string>,
                                     sourceCIDR?: string[], sourceSecGroup?: pulumi.Output<any>){
    new aws.ec2.SecurityGroupRule(name, {
        cidrBlocks: sourceCIDR, //["0.0.0.0/0"],
        sourceSecurityGroupId: sourceSecGroup,
        toPort: port,
        fromPort: port,
        protocol: 'tcp',
        securityGroupId: sgId,
        type: 'ingress',
        description: `${name} Traffic`,
    });
}
