Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-cluster-upgrade-fails>

# How do I troubleshoot an upgrade fail with my Amazon EKS cluster?

My Amazon Elastic Kubernetes Service (Amazon EKS) cluster fails to update. How do I resolve this?

## Short description

To resolve a failed Amazon EKS cluster update, try the following:

  * For an **IpNotAvailable** error, verify that the subnet that's associated with your cluster has enough available IP addresses.
  * For a **SubnetNotFound** error, verify that the subnets exist and are correctly tagged.
  * For a **SecurityGroupNotFound** error, verify that the security groups that are associated with the cluster exist.
  * For an **EniLimitReached** error, increase the elastic network interface quota for the AWS account.
  * For an **AccessDenied** error, verify that you have the correct permissions.
  * For an **OperationNotPermitted** error, verify that the Amazon EKS service role has the correct permissions.
  * For a **VpcIdNotFound** error, verify that the VPC that's associated with the cluster exists.
  * Verify that the resources that you used to create the cluster were deleted.
  * For clusters created with **eksctl** , verify that the AWS CloudFormation stack failed to roll back.
  * For a **ResourceInUseException** error, wait for some time before you retry the update.
  * For transient backend workflow issues, update the cluster again.



## Resolution

### Verify that the subnets have available IP addresses (IpNotAvailable)

To update an Amazon EKS cluster, you must have five available IP addresses from each of the subnets. If you don't have enough available IP addresses, then you can delete unused network interfaces within the cluster subnets. Deleting a network interface releases the IP address. For more information, see [Delete a network interface](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#delete_eni>).

To check for available IP addresses in the Amazon EKS cluster subnets:

1\. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>) in the Region where you created your cluster.

2\. Select **Clusters** from the sidebar. Then, select your **Amazon EKS cluster**.

3\. Choose the **Configuration** tab.

4\. Choose the **Networking** tab.

5\. Under **Subnets** , select a **subnet** to open the **Subnets** page.

6\. Select a **subnet** and choose the **Details** tab.

7\. Locate the **Available IPv4 addresses** to see how many available IP addresses the subnet has.

From the AWS Command Line Interface, run the following commands:

1\. Get the subnets that are associated with the cluster:
    
    
    $ aws eks describe-cluster --name cluster-name --region your-region

**Note:** Replace **cluster-name** with your cluster's name and **your-region** with your AWS Region.

Output:
    
    
    ...
       "subnetIds": [
                    "subnet-6782e71e",
                    "subnet-e7e761ac"
                ],
       ...

2\. Describe the subnets from the preceding output:
    
    
    aws ec2 describe-subnets --subnet-ids subet-id --region your-region

**Note:** Replace **subnet-id** with your subnet's ID and **your-region** with your Region.

Output:
    
    
    ...
    "AvailableIpAddressCount": 4089,
    ...

If you don't have enough available IP addresses, then you can set the environment variable in the aws-node daemonset to **WARM_IP_TARGET**. This defines how many secondary IP addresses that the Container Network Interface (CNI) must reserve for pods:
    
    
    $ kubectl set env ds aws-node -n kube-system WARM_IP_TARGET=number

**Note:** Replace **number** with the number of IP addresses that you want to reserve from the subnets.

You can also use the variable **MINIMUM_IP_TARGET** to control the minimum number of IP addresses per node.

It's a [best practice to use these configuration variables](<https://repost.aws/knowledge-center/eks-configure-cni-plugin-use-ip-address>) to control how many network interfaces and IP addresses are maintained.

### Verify that the subnets exist and are correctly tagged (SubnetNotFound)

To verify that your subnets exist, run the following command:
    
    
    aws ec2 describe-subnets --subnet-ids subet-id --region region

**Note:** Replace **subnet-id** with your subnet's ID and **region** with the Region where the subnets are located.

If the subnets don't exist, then you receive the following error:
    
    
    An error occurred (InvalidSubnetID.NotFound) when calling the DescribeSubnets operation: The subnet ID 'subnet-id' does not exist

To verify that the [subnets are correctly tagged](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-vpc>):

1\. Identify the subnets that are associated with the cluster using the steps in the **Check if you have enough available IP addresses (IpNotAvailable)** section.

2\. Open the [VPC console](<https://console.aws.amazon.com/vpc/>).

3\. Select **Subnets** from the sidebar.

4\. Select the subnets that should be associated with the cluster and choose the **Tags** tab in the **Details** pane.

5\. Verify that each subnet has the correct tags:
    
    
    Key - kubernetes.io/cluster/cluster-name

**Note:** The preceding tag is added to only [Amazon EKS cluster versions 1.18 or earlier](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-subnet-tagging>). For clusters created with Kubernetes version 1.19 and later, the tag is not mandatory. Replace **cluster-name** with your cluster's name.

The value of the tag can be either shared or owned.

If you have a Support plan, then contact the Support team to update your Amazon EKS subnets.

### Verify that the security groups that are associated with the cluster exist (SecurityGroupNotFound)

To identify the security groups that are associated with the cluster:

1\. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>) in the Region where you created your cluster.

2\. Select the **cluster**.

3\. Choose the **Configuration** tab.

4\. Choose the **Networking** tab.

5\. Select the security groups that are listed under **Cluster security group** and **Additional security groups**.

If the security group exists, then the console opens and displays the security group details.

From the AWS CLI:

1\. Get the security groups associated with the cluster:
    
    
    $ aws eks describe-cluster --name cluster-name --region your-region

**Note:** Replace **cluster-name** with your cluster's name and **your-region** with your Region.

Output:
    
    
    ...
    "securityGroupIds": [
        "sg-xxxxxxxx"
    ]
    ...

2\. Describe the security group from the preceding output:
    
    
    $ aws ec2 describe-security-groups --group-ids security-group-id --region your-region

**Note:** Replace **security-group-id** with your security group's ID and **your-region** with your Region.

### Increase the elastic network interface quota for the AWS account (EniLimitReached)

If you reached your network interface quota, then you can [remove unused network interfaces or request a limit increase](<https://repost.aws/knowledge-center/limit-reached-eni>) .

If your network interfaces are attached to a cluster, then delete the cluster to remove the network interface. If your network interfaces are attached to unused worker nodes, then [delete the Auto Scaling group](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html>) for self-managed node groups. For managed node groups, [delete the node group](<https://docs.aws.amazon.com/eks/latest/userguide/delete-managed-node-group.html>) from the Amazon EKS console. To move workloads from one node group to another node group, see [Migrating to a new node group](<https://docs.aws.amazon.com/eks/latest/userguide/migrate-stack.html>).

### Verify that you have the correct permissions (AccessDenied)

1\. Open the [IAM console](<https://console.aws.amazon.com/iamv2/home?#/home>).

2\. On the navigation pane, choose **Roles** or **Users**.

3\. Select the **role** or **user**.

4\. Verify that the IAM role or user has the [correct permissions](<https://docs.aws.amazon.com/eks/latest/userguide/security_iam_id-based-policy-examples.html#policy_example1>).

### Verify that the service role has the correct permissions (OperationNotPermitted)

1\. Open the [IAM console](<https://console.aws.amazon.com/iamv2/home?#/home>).

2\. On the navigation pane, choose **Roles**.

3\. Filter for **AWSServiceRoleForAmazonEKS** and select the role.

4\. Verify that the role has the **AmazonEKSServiceRolePolicy** policy attached.

If the policy isn't attached, see [Adding IAM identity permissions](<https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-attach-detach.html#add-policies-console>).

### Verify that the VPC associated with the cluster exists (VpcNotFound)

1\. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>) in the Region where you created your cluster.

2\. Select the cluster.

3\. Choose the **Configuration** tab.

4\. Choose the **Networking** tab.

5\. Select the **VPC ID** link to see if the VPC exists.

If the VPC doesn't exist, you must create a new cluster.

### Verify that resources associated with the cluster were deleted

If you created the cluster on the Amazon EKS console and the subnets used to create the cluster were deleted, then the cluster can't update. You must recreate the cluster and move the workloads from the old cluster to the new one. If you have a support plan, then contact the support team to update your Amazon EKS subnets.

### Verify that the AWS CloudFormation stack failed to roll back (eksctl)

If the CloudFormation stack failed to roll back, then see [How can I get my CloudFormation stack to update if it's stuck in the UPDATE_ROLLBACK_FAILED state?](<https://repost.aws/knowledge-center/cloudformation-update-rollback-failed>)

### Wait for some time before you initiate the control plane update again (ResourceInUseException)

This error occurs if an automated Amazon EKS control plane action, such as a [platform version update](<https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html>), is in progress when you initiate an update. Amazon EKS automatically detects and replaces unhealthy control plane instances, and it provides automated version upgrades and patching for them. Wait some time for the automated action to finish before you initiate the control plane update again.

**Note:** Your wait time depends on when the automated update started. If you're not sure when the automated action will resolve, then wait an hour before you retry the control plane update.

### Update the cluster again

Transient issues can cause the backend workflows to be unstable. If the preceding troubleshooting steps don't relate to your issue, then try to update the cluster again.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
