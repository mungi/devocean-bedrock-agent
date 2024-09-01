Original URL: <https://repost.aws/knowledge-center/eks-cluster-creation-errors>

# How do I troubleshoot cluster creation errors in Amazon EKS?

I get service errors when I use AWS CloudFormation or eksctl to provision an Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

The following are common issues you might get when you provision an Amazon EKS cluster:

  * The Availability Zone doesn't have sufficient capacity
  * The subnet resides in a disallowed Availability Zone
  * You're not authorized to create a cluster on the resource
  * You exceed your resource limits for your Amazon Virtual Private Cloud (Amazon VPC)
  * eksctl gets a time-out error



## Resolution

### The Availability Zone doesn't have sufficient capacity

If you launch control plane instances in an Availability Zone with limited capacity, then you might receive an error that's similar to the following:

"Cannot create cluster 'sample-cluster' because us-east-1d, the targeted availability zone, does not currently have sufficient capacity to support the cluster. Retry and choose from these availability zones: us-east-1a, us-east-1b, us-east-1c".

To fix this error, recreate the cluster in a different Availability Zone.

If you use AWS CloudFormation to provision your cluster, then add subnet values in the **Subnets** parameter that match the Availability Zones.

-or-

If you use the eksctl command-line tool, then use the **\--zones** flag to add the values for the Availability Zones. For example:
    
    
    $ eksctl create cluster 'sample-cluster' --zones us-east-1a,us-east-1b,us-east-1c

**Note:** Replace **sample-cluster** with your cluster name. Replace **us-east-1a** , **us-east-1b** , and **us-east-1c** with your Availability Zones.

### The subnet resides in a disallowed Availability Zone

If you create or update a subnet in a disallowed Availability Zone, then you get an error that's similar to the following:

"UnsupportedAvailabilityZoneException".

Subnets that you specify when you create or update a cluster can't reside in the following Availability Zones:

AWS Region| Region name| Disallowed Availability Zone IDs  
---|---|---  
us-east-1| US East (N. Virginia)| use1-az3  
us-west-1| US West (N. California)| usw1-az2  
ca-central-1| Canada (Central)| cac1-az3  
  
To fix this error, recreate the cluster in a different Availability Zone.

If you use AWS CloudFormation to provision your cluster, then add subnet values in the **Subnets** parameter that match the Availability Zones.

-or-

If you use eksctl, then use the **\--zones** flag to add the values for the Availability Zones. For example:
    
    
    $ eksctl create cluster 'sample-cluster' --zones us-east-1a,us-east-1b,us-east-1c

**Note:** Replace **sample-cluster** with your cluster name. Replace **us-east-1a** , **us-east-1b** , and **us-east-1c** with your Availability Zones.

### You're not authorized to create a cluster on the resource

If you create a cluster and don't have the correct AWS Identity and Access Management permissions, then you get an error similar to the following:

"API: iam:CreateRole User: arn:aws:iam::your-account-id:user/your-user-name is not authorized to perform: iam:CreateRole on resource: arn:aws:iam::your-account-id:role/eksctl-newtest22-cluster-ServiceRole-10NXBYLSN4ULP"

Before you create a cluster, verify that you have the correct IAM permissions and policies for the [Amazon EKS service IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html>).

Use **eksctl** to create the prerequisite resources for your cluster, such as the IAM roles and security groups. The required minimum permissions depend on the **eksctl** configuration that you launch. For more information, see [Document minimum IAM requirements](<https://github.com/eksctl-io/eksctl/issues/204>) on the GitHub website.

To resolve the error, review the [Minimum IAM policies](<https://eksctl.io/usage/minimum-iam-policies/>) on the eksctl website. Also, see [Identity and Access Management for Amazon EKS](<https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html>), and [How can I troubleshoot access denied or unauthorized operation errors with an IAM policy?](<https://repost.aws/knowledge-center/troubleshoot-iam-policy-issues>)

### You exceed your resource limits for your Amazon Virtual Private Cloud (Amazon VPC)

If your cluster has issues with your Amazon VPC limits, then you can receive the following error message:

"The maximum number of VPCs has been reached. (Service: AmazonEC2; Status Code: 400; Error Code: VpcLimitExceeded; Request ID: a12b34cd-567e-890-123f-ghi4j56k7lmn)"

When you create a cluster, **eksctl** creates a new Amazon VPC by default. If you don't want **eksctl** to create a new Amazon VPC, then you must specify your custom Amazon VPC and subnets in the configuration file. For more information, see [Use config files](<https://eksctl.io/usage/creating-and-managing-clusters/#using-config-files>) on the eksctl website.

To resolve the error, monitor your resources. For example, check the number of Amazon VPCs in your AWS Region or the internet gateways in each Region where you create the cluster. For more information, see [Amazon VPC quotas](<https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html>).

For issues related to resource constraints on the number of Amazon VPC resources in your Region, consider one of the following options:

**Use an existing Amazon VPC to overcome resource constraints**

Create a configuration file that specifies the Amazon VPC and subnets where you want to provision your cluster's worker nodes:
    
    
    $ eksctl create cluster sample-cluster -f cluster.yaml

**Request a service quota increase to overcome resource constraints**

[Request a service quota increase](<https://repost.aws/knowledge-center/manage-service-limits>) for the resources in the CloudFormation stack events of the cluster that **eksctl** provisioned.

### eksctl gets a time-out error

If your worker nodes don't reach the control plane or do not have a valid IAM role, then you can receive the following error:

"timed out (after 25m0s) waiting for at least 4 nodes to join the cluster and become ready in "eksfbots-ng1"

When **eksctl** deploys your cluster, the eksctl tool waits for the launched worker nodes to join the cluster and reach **Ready** status.

To resolve the error, [get your worker nodes to join the cluster](<https://repost.aws/knowledge-center/eks-worker-nodes-cluster>), and then [confirm that your worker nodes are in Ready status](<https://repost.aws/knowledge-center/eks-node-status-ready>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
