import * as aws from "@pulumi/aws";
import * as eks from "@pulumi/eks";
import * as utils from "../utils/utils";
import * as config from "./config";
import * as clusterLib from "./cluster";

/************** IAM **************/
// Assign extra policies to worker groups roles

let workerNodesCredentials = utils.createNodeGroupCredentials(config.primaryNodeGroupConfig.namespace);
let dsNodesCredentials: utils.nodeGroupCredentials = workerNodesCredentials;
let frontendNodesCredentials: utils.nodeGroupCredentials = workerNodesCredentials;
let groupNeedingLBAttachment : eks.NodeGroup
let tempinstanceRoles = [workerNodesCredentials.iamRole];
let backendLabels: {[key: string]: string} = {
    "backend": "true",
    "forgerock.io/role": "backend"
}


//IF DS NODEPOOL IS ENABLED, CREATE AND ASSIGN IAM POLICIES
if (config.dsNodeGroupConfig.enable){
    dsNodesCredentials = utils.createNodeGroupCredentials(config.dsNodeGroupConfig.namespace)
    new aws.iam.RolePolicyAttachment("dsnodes-s3-policy", {
        policyArn: aws.iam.ManagedPolicies.AmazonS3FullAccess,
        role: dsNodesCredentials.iamRole.id
    }, {dependsOn: [dsNodesCredentials.instanceProfile]});

    tempinstanceRoles.push(dsNodesCredentials.iamRole)
}
else { //DS DEDICATED NODES DISABLED
    new aws.iam.RolePolicyAttachment("backend-s3-policy", {
        policyArn: aws.iam.ManagedPolicies.AmazonS3FullAccess,
        role: workerNodesCredentials.iamRole.id
    },{dependsOn: [workerNodesCredentials.instanceProfile]});
    backendLabels["ds"] = "true"; //if ds dedicated nodes are disabled, run DS pods in workers nodes
}


//IF FRONTEND NODEPOOL IS ENABLED, CREATE AND ASSIGN IAM POLICIES
if (config.frontendNodeGroupConfig.enable){
    frontendNodesCredentials = utils.createNodeGroupCredentials(config.frontendNodeGroupConfig.namespace)
    tempinstanceRoles.push(frontendNodesCredentials.iamRole)
}
else { //FRONTEND DEDICATED NODES DISABLED
    backendLabels["frontend"] = "true"; //if frontend dedicated nodes are disabled, run frontend pods in workers nodes
}

const instanceRoles = tempinstanceRoles

/************** EKS CLUSTER**************/

const cluster = clusterLib.createCluster(instanceRoles);
export const kubeconfig = cluster.kubeconfig.apply(kc => {
    kc.clusters[0].cluster.server = kc.clusters[0].cluster.server.concat("");  //placeholder if we want to modify the kubeconfig
    return kc;

});

/************** EKS NODEGROUPS**************/
//WORKER NODES
const primaryNodeGroup = clusterLib.createNodeGroup(config.primaryNodeGroupConfig, cluster,
                                                   workerNodesCredentials.instanceProfile, backendLabels);

//CREATE FRONTEND DEDICATED NODES
if (config.frontendNodeGroupConfig.enable){
    const frontendLabels = {
        "frontend": "true",
        "forgerock.io/role": "frontend"
    };

    const frontendTaints = {
        "WorkerAttachedToExtLoadBalancer": {
            value: "true",
            effect: "NoSchedule"
        }
    }
    const frontendNodeGroup = clusterLib.createNodeGroup(config.frontendNodeGroupConfig, cluster,
                                                         frontendNodesCredentials.instanceProfile,
                                                         frontendLabels, frontendTaints)

    clusterLib.addSecurityGroupRule(`${config.frontendNodeGroupConfig.namespace}30080`, 30080,
                                    frontendNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)

    clusterLib.addSecurityGroupRule(`${config.frontendNodeGroupConfig.namespace}30443`, 30443,
                                    frontendNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)

    clusterLib.addSecurityGroupRule("traffic-from-frontend8080", 8080,
                                    primaryNodeGroup.nodeSecurityGroup.id, undefined, frontendNodeGroup.nodeSecurityGroup.id);


    //if dedicatedFrontend nodes are enabled, attach LB to frontend, else attach to workerNodes
    groupNeedingLBAttachment = frontendNodeGroup;
}
else { //IF NOT USING DEDICATED FRONTEND NODES
    clusterLib.addSecurityGroupRule(`${config.primaryNodeGroupConfig.namespace}30080`, 30080,
                                    primaryNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)

    clusterLib.addSecurityGroupRule(`${config.primaryNodeGroupConfig.namespace}30443`, 30443,
                                    primaryNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)

    groupNeedingLBAttachment = primaryNodeGroup;
}

//CREATE DS DEDICATED NODES
if (config.dsNodeGroupConfig.enable){
    const dsLabels = {
        "ds": "true",
        "forgerock.io/role": "ds"
    };

    const dsTaints = {
        "WorkerDedicatedDS": {
            value: "true",
            effect: "NoSchedule"
        }
    }
    const dsNodeGroup = clusterLib.createNodeGroup(config.dsNodeGroupConfig, cluster,
                                                   dsNodesCredentials.instanceProfile,
                                                   dsLabels, dsTaints)
    let ingressPortMap: {[id: string]: number; } = { };
    ingressPortMap["admin"] = 4444;
    ingressPortMap["ldap"] = 1389;
    ingressPortMap["ldaps"] = 1636;
    ingressPortMap["http"] = 8080;
    ingressPortMap["https"] = 8443;

    new aws.ec2.SecurityGroupRule("DS-All-Traffic", {
        sourceSecurityGroupId: dsNodeGroup.nodeSecurityGroup.id,
        fromPort: 0, toPort: 65535, protocol: '-1',
        securityGroupId: primaryNodeGroup.nodeSecurityGroup.id,
        type: 'ingress',description: "DS All Traffic",
    });
    for (let portName in ingressPortMap){
        clusterLib.addSecurityGroupRule(`DS-${portName}`, ingressPortMap[portName], dsNodeGroup.nodeSecurityGroup.id,
                                        undefined, primaryNodeGroup.nodeSecurityGroup.id);
    }
}

/************** ATTACH CORRECT NODEGROUP TO LB TARGET GROUPS**************/
groupNeedingLBAttachment.cfnStack.outputs.apply(s => {
    for (let tgIndex in config.infra.loadBalancerTargetGroups) {
        new aws.autoscaling.Attachment(`asgAttachment${tgIndex}`, {
            albTargetGroupArn: config.infra.loadBalancerTargetGroups[tgIndex],
            autoscalingGroupName: `${s.NodeGroup}`,
        }, {dependsOn: groupNeedingLBAttachment});
    };
});

// ********************** STORAGE CLASSES **************
clusterLib.createStorageClasses(cluster);