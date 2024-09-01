Original URL: <https://repost.aws/knowledge-center/resolve-eks-node-failures>

# How do I troubleshoot Amazon EKS managed node group creation failures?

My Amazon Elastic Kubernetes Service (Amazon EKS) managed node group failed to create. Nodes can't join the cluster and I received an error similar to the following: "Instances failed to join the kubernetes cluster".

## Short description

To resolve Amazon EKS [managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html>) creation failures, follow these steps:

  * Use the AWS Systems Manager automation runbook to identify common issues.
  * Confirm worker node security group traffic requirements.
  * Verify worker node Identity and Access Management (IAM) permissions.
  * Confirm that the Amazon Virtual Private Cloud (Amazon VPC) for your cluster has support for a DNS hostname and resolution.
  * Update the **aws-auth** ConfigMap with the **NodeInstanceRole** of your worker nodes.
  * Set the tags for your worker nodes.
  * Confirm that the Amazon VPC subnets for the worker node have available IP addresses.
  * Confirm that the worker nodes can reach the API server endpoint for your cluster.
  * Verify that the Amazon Elastic Compute Cloud (Amazon EC2), Amazon Elastic Container Registry (Amazon ECR), and Amazon Simple Storage Service (Amazon S3) API endpoints can reach your AWS Region.



## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### Use the Systems Manager automation runbook to identify common issues

Use the [AWSSupport-TroubleshootEKSWorkerNode](<https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awssupport-troubleshooteksworkernode.html>) runbook to find common issues that prevent worker nodes from joining your cluster.

**Important:** For the automation to work, your worker nodes must have permission to access Systems Manager and have Systems Manager running. To grant permission, attach the [AmazonSSMManagedInstanceCore](<https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview>) AWS managed policy to the IAM role that corresponds to your EC2 instance profile. This is the default configuration for EKS managed node groups that are created through eksctl.

  1. [Open the runbook](<https://console.aws.amazon.com/systems-manager/automation/execute/AWSSupport-TroubleshootEKSWorkerNode>).
  2. Check that the AWS Region in the AWS Management Console is set to the same Region as your cluster.  
**Note:** Review the **Document details** section of the runbook for more information about the runbook.
  3. In the **Input parameters** section, specify the name of your cluster in the **ClusterName** field and instance ID in the **WorkerID** field.
  4. (Optional) In the **AutomationAssumeRole** field, specify the IAM role to allow Systems Manager to perform actions. If not specified, then the IAM permissions of your current IAM entity is used to perform the actions in the runbook.
  5. Choose **Execute**.
  6. Check the **Outputs** section to see why your worker node isn't joining your cluster and steps that you can take to resolve it.



### Confirm worker node security group traffic requirements

Confirm that your control plane's security group and worker node security group are configured with the [recommended settings](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) for inbound and outbound traffic. By default, Amazon EKS applies the cluster security group to the instances in your node group to facilitate communication between nodes and the control plane. If you specify custom security groups in the launch template for your managed node group, then Amazon EKS doesn't add the cluster security group.

### Verify worker node IAM permissions

Make sure that the IAM instance role that's associated with the worker node has the [AmazonEKSWorkerNodePolicy](<https://docs.aws.amazon.com/eks/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEKSWorkerNodePolicy>) and [AmazonEC2ContainerRegistryReadOnly](<https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryReadOnly>) policies attached.

**Note:** You must attach the Amazon managed policy [AmazonEKS_CNI_Policy](<https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html>) to an IAM role. You can attach it to the node instance role. However, it's a best practice to attach the policy to a role that's associated with the **aws-node** Kubernetes service account in the **kube-system** namespace. For more information, see [Configuring the Amazon VPC CNI plugin for Kubernetes to use IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html>).

### Confirm that the Amazon VPC for your cluster has support for a DNS hostname and resolution

After you configure private access for your EKS cluster endpoint, you must turn on a DNS hostname and DNS resolution for your Amazon VPC. When you activate endpoint private access, Amazon EKS creates an Amazon Route 53 private hosted zone for you. Then, Amazon EKS associates it with your cluster's Amazon VPC. For more information, see [Amazon EKS cluster endpoint access control](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html>).

### Update the aws-auth ConfigMap with the NodeInstanceRole of your worker nodes

Verify that the aws-auth ConfigMap is configured correctly with the [IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>) of your worker nodes, not the instance profile.

### Set the tags for your worker nodes

For the **Tag** property of your worker nodes, set **key** to **kubernetes.io/cluster/clusterName** and set **value** to **owned**.

### Confirm that the Amazon VPC subnets for the worker node have available IP addresses

If your Amazon VPC is running out of IP addresses, then you can associate a secondary CIDR to your existing Amazon VPC. For more information, see [Amazon EKS VPC and subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-increase-ip-addresses>).

### Confirm that your Amazon EKS worker nodes can reach the API server endpoint for you cluster

You can launch worker nodes in any subnet within your cluster VPC or peered subnet if there's an internet route through the following gateways:

  * NAT
  * Internet
  * Transit



If your worker nodes are launched in a restricted private network, then confirm that your worker nodes can reach the Amazon EKS API server endpoint. For more information, see the [requirements](<https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html#private-cluster-requirements>) to run Amazon EKS in a private cluster without outbound internet access.

**Note** : For nodes that are in a private subnet backed by a NAT gateway, it's a best practice to create the NAT gateway in a public subnet.

If you're not using [AWS PrivateLink endpoints](<https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html#use-cases>), then verify access to API endpoints through a proxy server for the following AWS services:

  * Amazon EC2
  * Amazon ECR
  * Amazon S3



To verify that the worker node has access to the API server, connect to your worker node using SSH and run the following **netcat** command:
    
    
    nc -vz 9FCF4EA77D81408ED82517B9B7E60D52.yl4.eu-north-1.eks.amazonaws.com 443

**Note:** Replace **9FCF4EA77D81408ED82517B9B7E60D52.yl4.eu-north-1.eks.amazonaws.com** with your API server endpoint.

Check the **kubelet** logs while still connected to your instance:
    
    
    journalctl -f -u kubelet

If the **kubelet** logs don't provide information on the source of the issue, then check the status of the **kubelet** on the worker node:
    
    
    sudo systemctl status kubelet

Collect the Amazon EKS logs and the operating system logs for further troubleshooting.

### Verify that the Amazon EC2, Amazon ECR, and Amazon S3 API endpoints can reach your AWS Region

Use SSH to connect to one of the worker nodes, and then run the following commands for each service:
    
    
    $ nc -vz ec2.region.amazonaws.com 443
    
    
    $ nc -vz ecr.region.amazonaws.com 443
    
    
    $ nc -vz s3.region.amazonaws.com 443

**Note:** Replace **region** with the AWS Region for your worker node.

### Configure the user data for your worker node

For managed node group launch templates with a specified AMI, you must supply bootstrap commands for worker nodes to join your cluster. Amazon EKS doesn't merge the default bootstrap commands into your user data. For more information, see [Introducing launch template and custom AMI support in Amazon EKS Managed Node Groups](<https://aws.amazon.com/blogs/containers/introducing-launch-template-and-custom-ami-support-in-amazon-eks-managed-node-groups/>) and [Specifying an AMI](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami>).

Example launch template with bootstrap commands:
    
    
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${ClusterName} ${BootstrapArguments}

**Note:** Replace **${ClusterName}** with the name of your Amazon EKS cluster. Replace **${BootstrapArguments}** with additional bootstrap values, if needed.

## Related information

[Amazon EKS troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>)

[How can I get my worker nodes to join my Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-worker-nodes-cluster>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)[End User Computing](<https://repost.aws/topics/TAG9-8GrrnTvezb-2ifZO_-w/end-user-computing>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)[AWS Support Automation Workflows](<https://repost.aws/tags/TAHgFysm6PQZye8cyq2WRo2A/aws-support-automation-workflows>)

Language

English
