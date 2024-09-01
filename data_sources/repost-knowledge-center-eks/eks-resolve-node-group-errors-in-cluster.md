Original URL: <https://repost.aws/knowledge-center/eks-resolve-node-group-errors-in-cluster>

# How do I resolve managed node group errors in an Amazon EKS cluster?

I have issues with my managed node group in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

The following are common causes for managed node group errors in an Amazon EKS cluster:

  * Incorrect DHCP options: You receive an error when you register a node with the API server
  * Missing AWS Key Management Service (AWS KMS) key permissions: You receive an error when you launch an Amazon Elastic Compute Cloud (Amazon EC2) instance in an Auto Scaling group with an Amazon Elastic Block Store (Amazon EBS) volume that's encrypted with an AWS KMS key
  * Incorrect launch template: Because the EC2 launch template doesn't match the version that Amazon EKS created, your managed node group is in **Degraded** status



## Resolution

### Check your DHCP options

If you use an incorrect DHCP option in your custom DNS, then you might receive the following error:

"Node "ip-x-x-x-x.eu-region.compute.internal" is invalid: metadata.labels: Invalid value"

Verify that your hostname contains no more than 63 characters. To review your DHCP options, see [DHCP option sets in Amazon VPC](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_DHCP_Options.html#DHCPOptionSet>). Specify your hostname to match the AWS Region. For an AmazonProvidedDNS server in us-east-1, specify **ec2.internal**. For an AmazonProvidedDNS server in other Regions, specify **region.compute.internal**.

Example of a DHCP option set in us-east-1:

**domain-name:** ec2.internal  
**domain-name-servers:** AmazonProvidedDNS

Example of a DHCP option set in other Regions:

**domain-name:** region.compute.internal  
**domain-name-servers:** AmazonProvidedDNS

Example of a DHCP option set from a custom DNS:

**domain-name:** custom DNS name  
**domain-name-servers:** domain name server

**Note:** Replace **region** with your Region, **custom DNS name** with your DNS name, and **domain name server** with your domain name server.

For more information, see [DHCP option set concepts](<https://docs.aws.amazon.com/vpc/latest/userguide/DHCPOptionSetConcepts.html>). If your DHCP options set is associated with a VPC that has instances with multiple operating systems, then it's a best practice to specify only one domain name.

### Configure a key policy for your EBS volume encryption

If the Auto Scaling group service role is missing permissions, you might see the following error:

"AccessDeniedException: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/AWSServiceRoleForAutoScaling/AutoScaling is not authorized to perform: kms:GenerateDataKeyWithoutPlaintext on resource: ARN of KMS key"

If a managed node uses an AWS KMS key-encrypted Amazon EBS volume, then the Auto Scaling group service role doesn't have access to it.

The Auto Scaling group service role must have the following permissions to work with encrypted EBS volumes:

  * **kms:Encrypt**
  * **kms:Decrypt**
  * **kms:ReEncrypt***
  * **kms:GenerateDataKey***
  * **kms:DescribeKey**
  * **kms:CreateGrant**



To configure the correct KMS key policy, see [Required AWS KMS key policy for use with encrypted volumes](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html>). To allow more IAM roles to work with encrypted EBS volumes, you can modify the key policies. For more information, see [Allows key users to use the KMS key](<https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users>). For more information on KMS key access management, see [AWS Key Management Service](<https://docs.aws.amazon.com/kms/latest/developerguide/overview.html>).

### Update the launch template version

**Note:** Before you update your EC2 launch template from the managed node group, create a new version. For more information, see [Create a new launch template using parameters you define](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-launch-template.html#create-launch-template-define-parameters>).

If you manually update the launch template directly from the Auto Scaling group, then you might receive the following error:

"Ec2LaunchTemplateVersionMismatch"

To update your EC2 launch template from the managed node group, complete the following steps:

  1. Open the [EKS console](<https://console.aws.amazon.com/eks/home#/clusters>).
  2. Select the cluster that contains the node group to update.
  3. Choose the **Configuration** tab, and then choose the **Compute** tab.
  4. On the node groups page under launch templates, choose **Change version**.
  5. Select the version to apply to your node group. Make sure that the update strategy is set to **Rolling Update**.
  6. Choose **Update**.



**Note:** It's a best practice to update the node group with the new version of the EC2 launch template.

If you haven't used a custom launch template and you get the **Ec2LaunchTemplateVersionMismatch** error, then check your launch template version. Your worker nodes and EKS node group might not use the same launch template version. To resolve this issue, go to the Auto Scaling console to revert to the version that EKS created. For more information, see [Managed node group errors](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#troubleshoot-managed-node-groups>). For other resolutions of failed nodes in managed node groups, see [How can I get my worker nodes to join my Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-worker-nodes-cluster>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
