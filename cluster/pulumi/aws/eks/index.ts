import * as aws from "@pulumi/aws";
import * as eks from "@pulumi/eks";
import * as k8s from "@pulumi/kubernetes";
import * as utils from "../utils/utils";
import * as config from "./config";
import * as clusterLib from "./cluster";


/************** IAM **************/
// Assign extra policies to worker groups roles

let workerNodesCredentials = utils.createNodeGroupCredentials(config.workerNodeGroupConfig.namespace);
let dsNodesCredentials: utils.nodeGroupCredentials = workerNodesCredentials;
let frontendNodesCredentials: utils.nodeGroupCredentials = workerNodesCredentials;
let groupNeedingLBAttachment : eks.NodeGroup
let tempinstanceRoles = [workerNodesCredentials.iamRole];
let backendLabels: {[key: string]: string} = {
    "backend": "true",
    "kubernetes.io/role": "backend"
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
const workerNodeGroup = clusterLib.createNodeGroup(config.workerNodeGroupConfig, cluster, 
                                                   workerNodesCredentials.instanceProfile, backendLabels);
                                                   
//CREATE FRONTEND DEDICATED NODES
if (config.frontendNodeGroupConfig.enable){
    const frontendLabels = {
        "frontend": "true",
        "kubernetes.io/role": "frontend"
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
                                    workerNodeGroup.nodeSecurityGroup.id, undefined, frontendNodeGroup.nodeSecurityGroup.id);
    
    if (config.prometheusConfig.enable){
        clusterLib.addSecurityGroupRule("prometheus-kubeproxy", 10249,
                                        frontendNodeGroup.nodeSecurityGroup.id, undefined, workerNodeGroup.nodeSecurityGroup.id);

        clusterLib.addSecurityGroupRule("prometheus-kubelet", 10250,
                                        frontendNodeGroup.nodeSecurityGroup.id, undefined, workerNodeGroup.nodeSecurityGroup.id);
    
        clusterLib.addSecurityGroupRule("prometheus-nodeexp", 9100,
                                        frontendNodeGroup.nodeSecurityGroup.id, undefined, workerNodeGroup.nodeSecurityGroup.id);
    }


    //if dedicatedFrontend nodes are enabled, attach LB to frontend, else attach to workerNodes
    groupNeedingLBAttachment = frontendNodeGroup;
}
else { //IF NOT USING DEDICATED FRONTEND NODES
    clusterLib.addSecurityGroupRule(`${config.workerNodeGroupConfig.namespace}30080`, 30080, 
                                    workerNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)

    clusterLib.addSecurityGroupRule(`${config.workerNodeGroupConfig.namespace}30443`, 30443, 
                                    workerNodeGroup.nodeSecurityGroup.id, ["0.0.0.0/0"], undefined)
    
    groupNeedingLBAttachment = workerNodeGroup;
}

//CREATE DS DEDICATED NODES
if (config.dsNodeGroupConfig.enable){
    const dsLabels = {
        "ds": "true",
        "kubernetes.io/role": "ds"
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
    
    if (config.prometheusConfig.enable){
        ingressPortMap["prometheus-kubeproxy"] = 10249
        ingressPortMap["prometheus-kubelet"] = 10250
        ingressPortMap["prometheus-nodeexp"] = 9100
    }


    for (let portName in ingressPortMap){
        clusterLib.addSecurityGroupRule(`DS-${portName}`, ingressPortMap[portName], dsNodeGroup.nodeSecurityGroup.id, 
                                        undefined, workerNodeGroup.nodeSecurityGroup.id);
    }
}

/************** ATTACH CORRECT NODEGROUP TO LB TARGET GROUPS**************/
groupNeedingLBAttachment.cfnStack.outputs.NodeGroup.apply(s => {
    for (let tgIndex in config.infra.loadBalancerTargetGroups) {
        new aws.autoscaling.Attachment(`asgAttachment${tgIndex}`, {
            albTargetGroupArn: config.infra.loadBalancerTargetGroups[tgIndex],
            autoscalingGroupName: `${s}`,
        }, {dependsOn: groupNeedingLBAttachment});
    };
});

// ********************** STORAGE CLASSES **************
clusterLib.createStorageClasses(cluster);

// ********************** INGRESS CONTROLLER **************
if (config.ingressConfig.enable){
    clusterLib.createNginxIngress(cluster)
}

// ********************** CERTIFICATE MANAGER ************** 
if (config.cmConfig.enable){
    clusterLib.createCertManager(cluster);
}

// ********************** PROMETHEUS ************** 
if (config.prometheusConfig.enable){
    clusterLib.createPrometheus(cluster);
}
