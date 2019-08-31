import * as eks from "@pulumi/eks";
import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import { vpc } from "./vpc";
import {
    ami,
    k8sVersion,
    clusterName,
    minNodes,
    maxNodes,
    machineType,
    nodeCount,
    diskSize,
    k8sDashboard,
    pubKey
} from "./config";
import { AmazonS3FullAccess } from "@pulumi/aws/iam";

// Create an IAM Role and add user
function createIAMRole(name: string): aws.iam.Role {

    return new aws.iam.Role(`${name}`, {
        assumeRolePolicy: `{
            "Version": "2012-10-17",
            "Statement":[
              {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                  "AWS": "arn:aws:iam::048497731163:root"
                },
                "Action": "sts:AssumeRole"
              }
            ]
           }
        `,
        tags: {
           "clusterAccess": `${name}-usr`,
        }
    });
};

// Administrator AWS IAM clusterAdminRole with full access to all AWS resources
const clusterAdminRole = createIAMRole("clusterAdminRole");

const allVpcSubnets = vpc.privateSubnetIds.concat(vpc.publicSubnetIds);

// Create EKS cluster
export const cluster = new eks.Cluster(clusterName, {
    vpcId: vpc.id,
    subnetIds: allVpcSubnets,
    nodeAmiId: ami,
    version: k8sVersion,
    desiredCapacity: nodeCount,
    minSize: minNodes,
    maxSize: maxNodes,
    storageClasses: "gp2",
    nodePublicKey: pubKey,
    instanceType: machineType,
    nodeRootVolumeSize: diskSize,
    deployDashboard: k8sDashboard,
    //nodeAssociatePublicIpAddress: false,
    roleMappings: [
        {
            groups    : ["system:masters"],
            roleArn   : clusterAdminRole.arn,
            username  : "pulumi:admin-usr",            
        }
    ]
});

if (cluster.core.instanceProfile !== undefined) {
    new aws.iam.RolePolicyAttachment("s3-sync-policy", { 
        policyArn: AmazonS3FullAccess, 
        role: cluster.core.instanceProfile.role
    },
);
};

if (cluster.core.cluster.roleArn !== undefined) {
    let eksRole = cluster.core.cluster.roleArn.apply(role => role.split("/")[1]);
    new aws.iam.RolePolicyAttachment("s3-sync-policy-eks", { 
        policyArn: AmazonS3FullAccess,
        role: eksRole
    },
);
};


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


// Add inbound SSH access to worker nodes
new aws.ec2.SecurityGroupRule("allow_all", {
    cidrBlocks: ['0.0.0.0/0'],
    toPort: 22,
    fromPort: 22,
    protocol: 'tcp',
    securityGroupId: cluster.nodeSecurityGroup.id,
    type: 'ingress',
    description: 'Allow SSH inbound access to worker nodes',
});
