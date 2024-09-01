Original URL: <https://repost.aws/knowledge-center/eks-anywhere-bootstrapping-process>

# How does EKS Anywhere cluster bootstrapping work?

I want to understand the bootstrapping process for Amazon Elastic Kubernetes Service (Amazon EKS) Anywhere.

## Resolution

### The bootstrap cluster

When you create an initial standalone cluster or management cluster, Amazon EKS Anywhere also creates a bootstrap cluster. This is a temporary, single node Kubernetes in Docker (KinD) cluster that's created on a separate [Administrative machine](<https://anywhere.eks.amazonaws.com/docs/concepts/clusterworkflow/#administrative-machine>) to facilitate your main cluster's creation.

EKS Anywhere creates a bootstrap cluster on the Administrative machine that hosts CAPI and CAPX operators. To create the bootstrap cluster, EKS Anywhere must complete the following steps:

  * Pull the KinD node image
  * Prepare the node
  * Write the configuration
  * Start the control plane
  * Install the CNI
  * Install the StorageClass on the KinD-based single node cluster



### Cluster creation

When the bootstrap cluster is running and properly configured on the Administrative machine, the creation of the target cluster begins. EKS Anywhere uses kubectl to apply a target cluster configuration in the following process:

1\. After etcd, the control plane, and the worker nodes are ready, the target cluster receives its networking configuration.

2\. The target cluster receives its default storage class installation.

3\. CAPI providers are configured on the target cluster. This allows the target cluster to control and run the components that it needs to manage itself.

4\. After CAPI runs on the target cluster, CAPI objects are moved from the bootstrap cluster to the target cluster's CAPI service. This happens internally with the **clusterctl** command.

5\. The target cluster receives Kubernetes CRDs and other add-ons that are specific to EKS Anywhere.

6\. The cluster configuration is saved.

The bootstrapping process creates a YAML file that's located in **CLUSTER_NAME/generated/****CLUSTER_NAME**** -eks-a-cluster.yaml.**

When boostrapping succeeds, this YAML file moves to **CLUSTER_NAME/CLUSTER_NAME-eks-a-cluster.yaml**

Similarly, Kubeconfig moves from **CLUSTER_NAME/generated/CLUSTER_NAME.kind.kubeconfig** to **CLUSTER_NAME/CLUSTER_NAME-eks-a-cluster.kubeconfig**.

When etcd, the control plane, and the worker nodes are ready, the workload cluster receives its networking configuration. When the cluster is active and the CAPI service is running on the new cluster, the bootstrap cluster is no longer needed. Then, the service deletes the bootstrap cluster.

### Package workflows

During the bootstrapping process, EKS Anywhere uses the following logic in its workflows for the target cluster creation, cluster upgrade, and cluster deletion.

**Cluster creation**

For the full package workflow during cluster creation, see [create.go](<https://github.com/aws/eks-anywhere/blob/cd4814bfdef844df0bab9be4a5d034c89ad41548/pkg/workflows/create.go>) on GitHub. During this workflow, EKS Anywhere uses the following logic:

  * Setups and validations  
**Note:** If this step fails, then either preflights failed or the registry isn't set up properly.
  * Create a new bootstrap cluster  
Create a new KinD cluster  
Provider specific pre-capi-install-setup on the bootstrap cluster  
Install cluster-api providers on bootstrap cluster  
Provider specific post-setup
  * Create a new workload cluster  
Wait for external etcd to be ready  
Wait for control plane to become available  
Wait for workload kubeconfig generation  
Install networking the on workload cluster  
Install machine health checks on the bootstrap cluster  
Wait for control plane and worker machines to be ready
  * Install resources on management
  * Install the eks-a components task
  * Install the Git ops manager
  * Move cluster management
  * Write ClusterConfig
  * Delete the bootstrap cluster
  * Install curated packages



**Cluster upgrade**

For the full package workflow during a cluster upgrade, see [upgrade.go](<https://github.com/aws/eks-anywhere/blob/cd4814bfdef844df0bab9be4a5d034c89ad41548/pkg/workflows/upgrade.go>) on GitHub. During this workflow, EKS Anywhere uses the following logic:

  * Setups and validations
  * Update secrets
  * Verify etcd CAPI components exist
  * Upgrade core components
  * Verify the needed upgrade
  * Pause eks-a reconciliation
  * Create the bootstrap cluster
  * Install CAPI
  * Move management to the bootstrap cluster
  * Move management to the workload cluster
  * Upgrade the workload cluster
  * Delete the bootstrap cluster
  * Update the workload cluster and Git resources
  * Resume eks-a reconciliation
  * Write ClusterConfig



**Cluster deletion**

For the full package workflow during a cluster's deletion, see [delete.go](<https://github.com/aws/eks-anywhere/blob/cd4814bfdef844df0bab9be4a5d034c89ad41548/pkg/workflows/delete.go>) on GitHub. During this workflow, EKS Anywhere uses the following logic:

  * Setups and validatations
  * Create a management cluster
  * Install CAPI
  * Move cluster management
  * Delete the workload cluster
  * Clean up the Git repository
  * Delete package resources
  * Delete the management cluster



### Errors during cluster creation

If you encounter issues or errors, then look for logs in the Administrative machine and the capc-controller-manager. View the capc-controller-manager logs with kubectl in the capc-system namespace. For further troubleshooting, check the status of the CAPI objects for your cluster, located in the eksa-system namespace.

You might also find related information on errors in the logs of other CAPI managers, such as capi-kubeadm-bootstrap-controller, capi-kubeadm-control-plane-controller and capi-controller-manager. These managers work together, and you can locate each in their own namespace with the kubectl **get pods -A** command. For more information, see the [troubleshooting guide for EKS Anywhere](<https://anywhere.eks.amazonaws.com/docs/tasks/troubleshoot/troubleshooting/>).

For a script to fix linting errors during the bootstrapping process, see [bootstrapper.go](<https://github.com/aws/eks-anywhere/blob/cd4814bfdef844df0bab9be4a5d034c89ad41548/pkg/bootstrapper/bootstrapper.go>) on GitHub.

## Related information

[KinD quick start](<https://kind.sigs.k8s.io/docs/user/quick-start/>) (on the KinD website)

[Cluster creation workflow](<https://anywhere.eks.amazonaws.com/docs/concepts/clusterworkflow/>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
