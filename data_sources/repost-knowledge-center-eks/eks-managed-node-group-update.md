Original URL: <https://repost.aws/knowledge-center/eks-managed-node-group-update>

# How can I troubleshoot managed node group update issues for Amazon EKS?

I'm trying to update my Amazon Elastic Kubernetes Service (Amazon EKS) managed node group and am experiencing issues.

## Short description

[When you update your Amazon EKS managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html>), you might receive one of the following errors:

  * "PodEvictionFailure Reached max retries while trying to evict pods from nodes in node group nodegroup-1234"
  * "Error: Nodegroup health has issues other than AsgInstanceLaunchFailures, InstanceLimitExceeded, InsufficientFreeAddresses, ClusterUnreachable"
  * "Error: InvalidParameterException: Launch template details can't be null for Custom ami type node group"



-or-

"An error occurred (InvalidParameterException) when calling the UpdateNodegroupVersion operation: You cannot specify the field kubernetesVersion when using custom AMIs"

  * "UPDATE_FAILED Resource handler returned message: Requested release version 1.xx is not valid for kubernetes version 1.yy"



## Resolution

To resolve Amazon EKS managed node group update errors, follow these troubleshooting steps.

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### PodEvictionFailure Reached max retries while trying to evict pods from nodes in node group nodegroup-1234

The [PodEvictionFailure](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html#managed-node-update-upgrade>) error occurs when the upgrade can't drain all the pods from the node. If a [pod disruption budget (PDB)](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-patching.html>) is preventing pods from being drained from the node, then this can cause the issue. For example, if an application has a PDB of two, then at least two pods for that application must be running.

To check if your application is using a PDB, run the following [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>) command:
    
    
    $ kubectl get pdb —all-namespaces

If you're using a PDB, then take one of the following actions:

  * [Increase the number of available IP addresses for your Amazon Elastic Compute Cloud (Amazon EC2) nodes](<https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html>) to increase the number of pods.
  * Temporarily remove the PDB.
  * Use the force update option.



The force update option doesn't recognize PDBs. Updates occur regardless of PDB issues by forcing the node to restart.

**Note:** If pods from a Kubernetes controller aren't spread across the nodes, then this option might cause downtime for your applications.

To use the force option, run the AWS CLI command similar to the following one:
    
    
    $ aws eks update-nodegroup-version --cluster-name cluster-123 --nodegroup-name nodegroup-1234 --force

-or-

Run the following [eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>) command:
    
    
    $ eksctl upgrade nodegroup --cluster OneCluster --name managed-ng --force-upgrade

### Troubleshooting PodDisruptionBudget eviction failures with CloudWatch Logs Insights

You can use Amazon CloudWatch Logs Insights to search through the Amazon EKS control plane log data. For more information, see [Analyzing log data with CloudWatch Logs Insights](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html>).

**Important:** You can view log events in CloudWatch Logs only after you turn on control plane logging in a cluster. Before you select a time range to run queries in CloudWatch Logs Insights, verify that you turned on control plane logging. For more information, see [How can I retrieve Amazon EKS control plane logs from CloudWatch Logs?](<https://repost.aws/knowledge-center/eks-get-control-plane-logs>)

To identify the pod that failed eviction and the failure count, run a query similar to the following one:
    
    
    fields @timestamp, @message 
    | stats count(*) as count by objectRef.name
    | filter @logStream like /audit/ 
    | filter user.username == "eks:node-manager" and requestURI like "eviction" and requestURI like "pod" and responseStatus.code > 400
    | sort count desc

The maximum number of retries for an eviction pod is 20. If the count for a displayed pod is greater than or equal to 20 failures, then this is the pod that failed eviction.

To identify the pod disruption budget name that's blocking the preceding pod from being evicted, run the following query.
    
    
    filter @logStream like /^kube-apiserver-audit/
      | fields @logStream, @timestamp, @message
      | sort @timestamp desc
      | filter user.username == "eks:node-manager" and requestURI like "eviction" and requestURI like "pod_name" and responseStatus.code > 400
      | limit 999
      | display responseObject.details.causes.0.message,objectRef.name,objectRef.namespace,objectRef.resource

**Note:** Replace **pod_name** with your pod name.

The output has a message similar to following one, where **pod_distruption_budget** is the object that's causing the eviction failures:
    
    
    The disruption budget pod_distruption_budget needs 1 healthy pods and has 1 currently

### Error: Nodegroup health has issues other than AsgInstanceLaunchFailures, InstanceLimitExceeded, InsufficientFreeAddresses, ClusterUnreachable

If you receive this error message, then check the managed node group details and locate the health issues. For more information and troubleshooting, check for [managed node group errors](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#troubleshoot-managed-node-groups>) and the [Amazon EKS issue API reference](<https://docs.aws.amazon.com/eks/latest/APIReference/API_Issue.html>).

### Error: InvalidParameterException: Launch template details can't be null for Custom ami type node group

-or-

### An error occurred (InvalidParameterException) when calling the UpdateNodegroupVersion operation: You cannot specify the field kubernetesVersion when using custom AMIs.

For managed node groups with a custom AMI, you must create a new AMI version with the Kubernetes version that you want to upgrade to. During the upgrade, specify the launch template and the version.

If you're using the AWS CLI, then use the flag **\--launch-template**. For [eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>), use the flag **\--launch-template-version**.

**Note:** Avoid using the **\--kubernetes-version** flag with these commands.

### UPDATE_FAILED Resource handler returned message: "Requested release version 1.xx is not valid for kubernetes version 1.yy"

This error occurs when upgrading the managed node group with the Amazon EKS cluster from the same AWS CloudFormation stack with the [UpdateStack](<https://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_UpdateStack.html>) API call.

CloudFormation tries to roll back the stack, but it fails because the Amazon EKS cluster upgraded successfully and can't be reverted. The Amazon EKS cluster can't match 1.xx with 1.yy (for example, 1.21 and 1.22).

Check the first error that occurred for the node group in the CloudFormation stack for more details on how to fix the issue. Then, [update your CloudFormation stack](<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks.html>) again.

For more information, see [Managed node update behavior](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html>).

* * *

## Related information

[How do I troubleshoot Amazon EKS managed node group creation failures?](<https://repost.aws/knowledge-center/resolve-eks-node-failures>)

[How do I resolve managed node group errors in an Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-resolve-node-group-errors-in-cluster>)

[Amazon EKS troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
