Original URL: <https://repost.aws/knowledge-center/eks-custom-launch-template>

# How do I troubleshoot custom launch template issues with managed node groups in Amazon EKS?

I want to troubleshoot errors when using custom launch template with managed node groups in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

When you use a custom launch template with managed node groups in your Amazon EKS cluster, you might get one of the following errors:

  * "Client.InternalError: Client error on launch"
  * "SourceEc2LaunchTemplateNotFound or The Amazon EC2 Launch Template lt-xxxxxxxxxxxxxxxxx version x was not found"
  * "Node group entered a DEGRADED status"



## Resolution

### Client.InternalError: Client error on launch

This error occurs when you use encrypted Amazon Elastic Block Store (Amazon EBS) volumes in the custom launch template with incorrect permissions. To check the encryption status and AWS Identity and Access Management (IAM) permissions or policies, complete the following tasks:

  * [Activate the AWS Key Management Service (AWS KMS) key](<https://docs.aws.amazon.com/kms/latest/developerguide/enabling-keys.html>) that's used to encrypt the volume.
  * Make sure that the AWS KMS key has the [correct key policies](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html>). To allow more IAM roles to work with encrypted Amazon EBS volumes, modify the key policies. For more information, see [Allows key users to use the KMS key](<https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users>).



### SourceEc2LaunchTemplateNotFound or The Amazon EC2 Launch Template lt-xxxxxxxxxxxxxxxxx version x was not found

This error occurs when you manually change the custom launch template version through the Auto Scaling group of the node instead of Amazon EKS. To resolve this issue, you must use Amazon EKS to [update the launch template version](<https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html>).

To update your EC2 launch template from the managed node group, complete the following steps:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>).
  2. In the navigation pane, choose **Clusters**.
  3. Under **Cluster name** , choose the cluster that contains the node group to update.
  4. Choose the **Compute** tab.
  5. For Node groups, choose your node and then choose **Change version**.
  6. Select the version to apply to your node group. Make sure that the update strategy is set to **Rolling Update**.
  7. Choose **Update**.



This error also occurs if you delete a reference template when you create a node group with a custom launch template. When you create a node group with a custom launch template, Amazon EKS replicates the template. If you delete the original template, then you must recreate the node group.

To recreate the node group, complete the following steps:

  1. [Launch a new node group](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>).

  2. Run the following command to verify that all nodes are healthy, in the **Ready** state, and joined the cluster:
    
        $ kubectl get nodes

  3. [Drain your worker nodes](<https://repost.aws/knowledge-center/eks-worker-node-actions>).

  4. [Delete the original node group](<https://docs.aws.amazon.com/eks/latest/userguide/delete-managed-node-group.html>).




### The Node group enters a DEGRADED status after it creates a new launch template

A node group can enter a **DEGRADED** status with a message similar to the following error:

"The Amazon EC2 Launch Template : lt-xxxxxxxxxxxxxxxxx has a new version associated with your Autoscaling group, which is not managed by Amazon EKS. Expected Launch Template version: x".

This error occurs when the Amazon EC2 launch template version for your managed node group doesn't match the version that Amazon EKS creates. Existing node groups that don't use a custom launch template can't be directly updated. To resolve this error, create a launch template and version with your preferred settings. Then, use the launch template to create the node group. If the new node group is launched from your custom template, then create new versions of the template. You can use this template without placing the node group in a **DEGRADED** status.

## Related information

[Customizing managed nodes with launch templates](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html>)

[Launch template configuration basics](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
