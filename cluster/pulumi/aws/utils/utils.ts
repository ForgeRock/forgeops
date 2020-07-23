import * as aws from "@pulumi/aws";

const managedPolicyArns: string[] = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
];

export function createRole(name: string, trustEntity: string = "service") : aws.iam.Role {

    let principalObj:any  = {}
    if (trustEntity.toLowerCase() == "root")
    {
        principalObj = aws.getCallerIdentity({}).then(id => aws.iam.assumeRolePolicyForPrincipal({"AWS": `arn:aws:iam::${id.accountId}:root`})) 
    }
    else
    {
        principalObj = aws.getCallerIdentity({}).then(id => aws.iam.assumeRolePolicyForPrincipal({"Service": "ec2.amazonaws.com"}))
    }

    const role = new aws.iam.Role(name, {
        assumeRolePolicy: principalObj,
    });

    if (trustEntity.toLowerCase() !== "root") //only run for service accounts
    {
        let counter = 0;
        for (const policy of managedPolicyArns) {
            // Create RolePolicyAttachment without returning it.
            const rpa = new aws.iam.RolePolicyAttachment(`${name}-policy-${counter++}`,
                { policyArn: policy, role: role },
            );
        }
    }

    return role;
}


export interface nodeGroupCredentials {
    iamRole: aws.iam.Role;
    instanceProfile: aws.iam.InstanceProfile;
};

export function createNodeGroupCredentials(namespace : string): nodeGroupCredentials{
    let iamRole = createRole(`${namespace}Role`)
    return {
        iamRole: iamRole,
        instanceProfile: new aws.iam.InstanceProfile(`${namespace}Profile`, {role: iamRole}),
    };
};