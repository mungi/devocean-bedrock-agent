Original URL: <https://repost.aws/knowledge-center/eks-plan-upgrade-cluster>

# How do I plan an upgrade strategy for an Amazon EKS cluster?

When I upgrade my Amazon Elastic Kubernetes Service (Amazon EKS) cluster, I want to follow best practices.

## Short description

New Kubernetes versions can introduce significant changes to your Amazon EKS cluster. After you upgrade a cluster, you can't downgrade your cluster. When you upgrade to a newer Kubernetes version, you can migrate to new clusters instead of performing in-place cluster upgrades. If you choose to migrate to new clusters, then cluster backup and restore tools like VMware's Velero can help you migrate. For more information, see [Velero](<https://github.com/vmware-tanzu/velero>) on the GitHub website.

To see current and past versions of Kubernetes that are available for Amazon EKS, see the [Amazon EKS Kubernetes release calendar](<https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar>).

## Resolution

### Prepare for an upgrade

Before you begin your cluster upgrade, note the following requirements:

  * Amazon EKS requires up to five available IP addresses from the subnets that you specified when you created your cluster.
  * The cluster's [AWS Identity and Access Management (IAM) role](<https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html>) and [security group](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) must exist in your AWS account.
  * If you activate [secrets encryption](<https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html>), then the cluster IAM role must have AWS Key Management Service (AWS KMS) key permissions.



**Review major updates for Amazon EKS and Kubernetes**

Review all documented changes for the upgrade version, and note any required upgrade steps. Also, note any requirements or procedures that are specific to Amazon EKS managed clusters.

Refer to the following resources for any major updates to Amazon EKS clusters platform versions and Kubernetes versions:

  * [Updating an Amazon EKS cluster Kubernetes version](<https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html>)
  * [Amazon EKS Kubernetes versions](<https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html>)
  * [Amazon EKS platform versions](<https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html>)



For more information on Kubernetes upstream versions and major updates, see the following documentation:

  * [Kubernetes release notes](<https://relnotes.k8s.io/>) on the Kubernetes website
  * [Changelog](<https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG>) on the GitHub website



**Understand the Kubernetes deprecation policy**

When an API is upgraded, the earlier API is deprecated and eventually removed. To understand how APIs might be deprecated in a newer version of Kubernetes, read the [deprecation policy](<https://kubernetes.io/docs/reference/using-api/deprecation-policy/>) on the Kubernetes website.

To check whether you use any deprecated API versions in your cluster, use the [Kube No Trouble (kubent)](<https://github.com/doitintl/kube-no-trouble>) on the GitHub website. If you use deprecated API versions, then upgrade your workloads before you upgrade your Kubernetes cluster.

To convert Kubernetes manifest files between different API versions, use the **kubectl convert** plugin. For more information, see [Install kubectl convert plugin](<https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-convert-plugin>) on the Kubernetes website.

**What to expect during a Kubernetes upgrade**

When you upgrade your cluster, Amazon EKS launches new API server nodes with the upgraded Kubernetes version to replace the existing nodes. If any of these checks fail, then Amazon EKS rolls back the infrastructure deployment, and your cluster remains on the previous Kubernetes version. However, this rollback doesn't affect any applications that are running, and you can recover any clusters, if needed. During the upgrade process, you might experience minor service interruptions.

### Upgrade the control plane and data plane

To upgrade an Amazon EKS cluster, you must update two main components: the control plane and the data plane. When you upgrade these components, keep the following considerations in mind.

**In-place Amazon EKS cluster upgrades**

For in-place upgrades, you can upgrade only to the next highest Kubernetes minor version. If there are multiple versions between your current cluster version and the target version, then you must upgrade to each version sequentially. For each in-place Kubernetes cluster upgrade, complete the following tasks:

  * Update your Kubernetes manifests and update deprecated or removed APIs, as required.
  * Upgrade the cluster control plane.
  * Upgrade the nodes in your cluster.
  * Update your Kubernetes add-ons and custom controllers, as required.



For more information, see **Planning and executing Kubernetes version upgrades in Amazon EKS** in [Planning Kubernetes upgrades with Amazon EKS](<https://aws.amazon.com/blogs/containers/planning-kubernetes-upgrades-with-amazon-eks/>). Also, see [Best practices for cluster upgrades](<https://aws.github.io/aws-eks-best-practices/upgrades/#best-practices-for-cluster-upgrades>) on the GitHub website.

**Blue/green or canary Amazon EKS clusters migration**

A blue/green or canary upgrade strategy can be more complex, but the strategy allows upgrades with easy rollback capability and no downtime. For a blue/green or canary upgrade, see [Blue/green or canary Amazon EKS clusters migration for stateless ArgoCD workloads](<https://aws.amazon.com/blogs/containers/blue-green-or-canary-amazon-eks-clusters-migration-for-stateless-argocd-workloads/>).

**Upgrade Amazon EKS managed node groups**

**Important:** A node's kubelet can't be newer than **kube-apiserver**. Also, it can't be more than two minor versions earlier than **kube-apiserver**. For example, suppose that **kube-apiserver** is at version 1.24. In this case, a kubelet is supported only at versions 1.24, 1.23, and 1.22.

To completely upgrade your managed node groups, complete the following steps:

  1. [Upgrade your Amazon EKS cluster control plane components to the latest version](<https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html>).
  2. [Update your nodes in the managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html>).



**Migrate to Amazon EKS managed node groups**

If you use self-managed node groups, then you can migrate your workload to Amazon EKS managed node groups with no downtime. For more information, see [Seamlessly migrate workloads from EKS self-managed node group to EKS-managed node groups](<https://aws.amazon.com/blogs/containers/seamlessly-migrate-workloads-from-eks-self-managed-node-group-to-eks-managed-node-groups/>).

### Identify and upgrade downstream dependencies (add-ons)

Clusters often contain outside products, such as ingress controllers, continuous delivery systems, monitoring tools, and other workflows. When you update your Amazon EKS cluster, you must also update your add-ons and third-party tools. Make sure you understand [how add-ons work with your cluster and how they're updated](<https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html>).

**Note:** It's a best practice to use managed add-ons instead of self-managed add-ons.

Review the following examples of common add-ons and relevant upgrade documentation:

  * **Amazon VPC CNI:** For the suggested version of the Amazon VPC CNI add-on to use for each cluster version, see [Working with the Amazon VPC CNI plugin for Kubernetes Amazon EKS add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>). Also, see [Update the aws-node daemonset to use IRSA](<https://aws.github.io/aws-eks-best-practices/security/docs/iam/#update-the-aws-node-daemonset-to-use-irsa>) on the GitHub website.
  * **kube-proxy self-managed add-on:** Update to the latest available kube-proxy container image version for each Amazon EKS cluster version. For more information, see [Working with the Kubernetes kube-proxy add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html>).
  * **CoreDNS:** Update to the latest available CoreDNS container image version for each Amazon EKS cluster version. For more information, see [Updating the self-managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html#coredns-add-on-self-managed-update>).
  * **AWS Load Balancer Controller:** Versions 2.5.0 or later of AWS Load Balancer Controller require Kubernetes versions 1.22 or later. For more information, see [AWS Load Balancer Controller releases](<https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases>) on the GitHub website. For installation information, [Installing the AWS Load Balancer Controller add-on](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>).
  * **Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) driver:** Versions 1.25.0 or later of the Amazon EBS CSI driver require Kubernetes versions 1.23 or later. For more information, see [Amazon EBS CSI driver releases](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/releases>) on the GitHub website. For installation and upgrade information, see [Managing the Amazon EBS CSI driver as an Amazon EKS add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html>).
  * **Amazon Elastic File System (Amazon EFS) Container Storage Interface (CSI) driver:** Versions 1.5.8 or later of the Amazon EFS CSI driver require Kubernetes versions 1.22 or later. For more information, see [Amazon EFS CSI driver releases](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases>) on the GitHub website. For installation and upgrade information, see [Amazon EFS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>).



### Upgrade AWS Fargate nodes

To update a Fargate node, delete the pod that the node represents. Then, after you update your control plane, redeploy the pod. Any new pods that you launch on Fargate have a kubelet version that matches your cluster version. Existing Fargate pods aren't changed.

**Note:** To keep Fargate pods secure, Amazon EKS must periodically patch them. Amazon EKS tries to update the pods in a way that reduces its effects. However, if pods can't be successfully evicted, then Amazon EKS deletes them. To minimize disruption, see [Fargate OS patching](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-patching.html>).

### Upgrade groupless nodes that Karpenter creates

When you set a value for **ttlSecondsUntilExpired** , this value activates node expiry. After nodes reach the defined age in seconds, Amazon EKS deletes them. This deletion occurs even if the nodes are in use. This process allows you to replace nodes with newly provisioned instances, and therefore upgrade them. When a node is replaced, Karpenter uses the latest Amazon EKS optimized AMIs. For more information, see [Disruption](<https://karpenter.sh/preview/concepts/deprovisioning/>) on the Karpenter website.

The following example shows a node that's deprovisioned with **ttlSecondsUntilExpired** , and then replaced with an upgraded instance:
    
    
    apiVersion: karpenter.sh/v1alpha5kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: karpenter.sh/capacity-type         # optional, set to on-demand by default, spot if both are listed
          operator: In
          values: ["spot"]
      limits:
        resources:
          cpu: 1000                               # optional, recommended to limit total provisioned CPUs
          memory: 1000Gi
      ttlSecondsAfterEmpty: 30                    # optional, but never scales down if not set
      ttlSecondsUntilExpired: 2592000             # optional, nodes are recycled after 30 days but never expires if not set
      provider:
            subnetSelector:
          karpenter.sh/discovery/CLUSTER_NAME: '*'
        securityGroupSelector:
          kubernetes.io/cluster/CLUSTER_NAME: '*'

**Note:** Karpenter doesn't automatically add jitter to this value. If you create multiple instances in a short amount of time, then the instances expire near the same time. To prevent excessive workload disruption, define a pod disruption budget. For more information, see [Specifying a disruption budget for your application](<https://kubernetes.io/docs/tasks/run-application/configure-pdb/>) on the Kubernetes website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
