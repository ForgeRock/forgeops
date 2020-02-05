import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";

export interface PkgArgs {
    version: string;
    namespaceName: string;
    provider: any;
    cluster: gcp.container.Cluster;
}

export class LocalSsdProvisioner {

    readonly version: string
    readonly provider: k8s.Provider
    readonly namespaceName: string
    readonly cluster: gcp.container.Cluster

    /**
    * Deploy Local SSD provisioner to GKE k8s cluster.
    * @param PkgArgs  Args for Local SSD provisioner
    */

    constructor(args: PkgArgs) {

        this.version = args.version;
        this.provider = args.provider;
        this.namespaceName = args.namespaceName;
        this.cluster = args.cluster;

        let yamlFile: string = 'local-ssd-provisioner/files/local-ssd-provisioner.yaml';

        // Create namespace
        const namespace = new k8s.core.v1.Namespace("localSsdProvisionerNamespace", {
            metadata: {
                name: this.namespaceName
            }
        },{provider: this.provider, dependsOn: this.cluster})

        // Update namespace fields in k8s manifests
        function addNamespace (o: any): void{
            if (o !== undefined) {
                if (o.metadata !== undefined) {
                    o.metadata.namespace = namespace.id
                }
                if (o.subjects !== undefined) {
                    o.subjects[0].namespace = namespace.id
                }       
            }
        }

        // Deploy local ssd provisioner manifests
        new k8s.yaml.ConfigFile("localSsdProvisioner", {
            file: yamlFile,
            transformations: [addNamespace]
            },{ dependsOn: namespace, provider: this.provider});
    }
}