Original URL: <https://repost.aws/knowledge-center/eks-node-group-update-failures>

# How do I troubleshoot common issues with Amazon EKS node group update failures?

I want to update my Amazon Elastic Kubernetes Service (Amazon EKS) node groups using the newest Amazon Machine Image (AMI) versions.

## Short description

When you initiate a managed node group update, Amazon EKS automatically updates your nodes. If you use an Amazon EKS-optimized AMI, then Amazon EKS automatically applies the latest security patches and operating system updates to your nodes.

During this update process, you might see any of the following errors. Follow the relevant troubleshooting steps for the error that you encounter. For more information on update errors, see [Managed node update behavior](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html>).

## Resolution

### The update failed because of PodEvictionFailure

The following error indicates that a **PodEvictionFailure** is blocking the upgrade:

"Error message : Reached max retries while trying to evict pods from nodes in node group."

If the pods don't leave the node within 15 minutes and there's no force flag, then the upgrade phase fails with a **PodEvictionFailure** error.

A **PodEvictionFailure** error might occur for any of the following reasons:

**Aggressive PDB (Pod Disruption Budget)**

When there are multiple PDBs that point to the same pod, the pod has a definition of **Aggressive PDB**.

PDB indicates the number of disruptions that a class of pods can tolerate at a given time (or a "budget of faults"). When a voluntary disruption causes the pods for a service to drop below the budget, the operation pauses until it can maintain the budget. The node drain event halts temporarily until more pods become available. This makes sure that you don't exceed the budget by evicting the pods. For more information, see [Disruptions](<https://kubernetes.io/docs/concepts/workloads/pods/disruptions/>) on the Kubernetes website.

To confirm a smooth managed node group update, either remove the pod disruption budgets temporarily or use the force option to update. This option doesn't respect pod disruption budgets. Instead, it forces the nodes to restart and therefore implement the updates.

**Note:** If the app is a Quorum-based application, then the force option might cause the application to become temporarily unavailable.

To confirm that you have PDBs configured in your cluster, run the following command:
    
    
    $ kubectl get pdb --all-namespaces

Or, if you turned on audit logging in the [Amazon EKS console](<https://console.aws.amazon.com/eks/>), then follow these steps:

  1. Under the **Clusters** tab, choose the desired cluster (for example, rpam-eks-qa2-control-plane) from the list.

  2. Under the **Logging** tab, choose **Audit**. This action redirects you to the Amazon CloudWatch console.

  3. In the CloudWatch console, choose **Logs**. Then, choose **Log Insights** and run the following query:
    
        fields @timestamp, @message| filter @logStream like "kube-apiserver-audit"
    | filter ispresent(requestURI)
    | filter objectRef.subresource = "eviction" 
    | display @logStream, requestURI, responseObject.message
    | stats count(*) as retry by requestURI, responseObject.message

  4. Choose **Custom** to identify the date for the update. If there's a node group update failure due to aggressive PDB, then **resposeObject.message** describes the reason for the pod eviction failure.

  5. If PDB caused the failure, then modify the PDB. Run the following command, and then upgrade the node group again:
    
        $ kubectl edit pdb pdb_name;




**Deployment tolerating all the taints**

After every pod is evicted, the node becomes empty because the node was tainted in the earlier steps. However, if the deployment tolerates every taint, then the node is more likely to be non-empty. This leads to a pod eviction failure. For more information, see [Taints and tolerations](<https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration>) on the Kubernetes website.

### The update failed because of a non-valid release version

If you have release version that's not valid, then you might receive the following error:

"Error Message: Requested release version 1.xx is not valid for kubernetes version 1.xx."

To resolve this issue, run the upgrade command again. This command upgrades the node groups to the same version as the control plane's Kubernetes version:
    
    
    eksctl upgrade nodegroup --name=test --cluster=test --kubernetes-version=1.xx

**Note:** Replace 1.xx version with the version supported by Amazon EKS control plane.

### The update failed because the node group has health issues

If your node group has health issues, then a failed update returns the following error:

"Error message: Nodegroup has health issue other than [ AsgInstanceLaunchFailures, InstanceLimitExceeded, InsufficientFreeAddresses, ClusterUnreachable]"

This indicates that the node group's Auto Scaling group can't find the expected version of its Amazon Elastic Compute Cloud (Amazon EC2) launch template. This error occurs if you manually modify or delete the version of the template that's associated with the node group. This causes EKS to show the node group as degraded.

If you didn't delete the launch template, then manually change the launch template version of the Auto Scaling group back to the appropriate version. This action reverts the node group to a healthy and active state, and you can reinitiate the update process.

### The update failed because new nodes aren't joining the node group

This issue occurs if the node group's new nodes can't join the cluster. As a result, the node group rolls back to its previous version. In this case, you might see the following error:

"NodeCreationFailure  
Couldn't proceed with upgrade process as new nodes are not joining node group ng-backend"

There are multiple reasons why updated nodes can't join the cluster:

**You changed a security group rule that the existing node group uses**

Verify that the node's security group's outbound rules allow port 443 to the cluster's security group.

**The cluster's security group doesn't allow traffic from the node security group**

Verify that the cluster's security group's inbound rules allow port 443 from the node's security group. For more information, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

**You created your node group with a custom launch template**

If you're updating a custom launch template, then the new version of the template must have the correct user data. Also, if you use a custom AMI, then make sure that you correctly configured the AMI to join the cluster.

To troubleshoot launch template issues, create a new node group with the same launch template. Make sure that the template uses the most recent version of the custom AMI. Then, see if the node successfully joins the cluster. If the node doesn't join the cluster, then connect to the node instance with SSH and check the kubelet logs.

**There are missing IAM permissions**

Check if the AWS Identity and Access Management (IAM) role for the node group has the [necessary permissions](<https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html>).

**ACLs deny traffic**

The access control list (ACL) of a node's subnet might deny outbound traffic for port 443 or inbound traffic for an ephemeral port. Make sure to allow these rules for the node's subnet.

Similarly, the ACL of a cluster's subnet might deny inbound traffic for port 443. Make sure to allow this traffic for your cluster's subnets.

**New nodes fail to add a plugin**

An Amazon Virtual Private Cloud (Amazon VPC) CNI plugin or kube-proxy add-on might fail to appear on new nodes. For more information, see [How do I resolve kubelet or CNI plugin issues for Amazon EKS?](<https://repost.aws/knowledge-center/eks-cni-plugin-troubleshooting>)

**A subnet has connectivity issues**

The subnet where Amazon EKS creates nodes might not have connectivity to necessary endpoints. These endpoints might include Amazon Elastic Container Registry (Amazon ECR), Amazon Simple Storage Service (Amazon S3), or Amazon EC2. The connectivity might fail either through the internet or VPC endpoints. For VPC endpoints, check the security groups of the nodes and endpoints to make sure that they allow the required traffic. If you use a NAT Gateway or internet gateway, then verify that the routing rule is correct in your subnet's route table. Also, verify that the corresponding NAT gateway or internet gateway exists.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
