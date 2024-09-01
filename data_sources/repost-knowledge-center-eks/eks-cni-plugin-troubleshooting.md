Original URL: <https://repost.aws/knowledge-center/eks-cni-plugin-troubleshooting>

# How do I resolve kubelet or CNI plugin issues for Amazon EKS?

I want to resolve issues with my kubelet or CNI plugin for Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

To assign and run an IP address to the pod on your worker node with your [CNI plugin](<https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/>) (on the Kubernetes website), you must have the following configurations:

  * AWS Identity and Access Management (IAM) permissions, including a [CNI policy](<https://github.com/aws/amazon-vpc-cni-k8s>) that attaches to your worker node's IAM role. Or, IAM permissions that you provide through [service account IAM roles](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html>).
  * An Amazon EKS API server endpoint that's reachable from the worker node.
  * Network access to API endpoints for Amazon Elastic Compute Cloud (Amazon EC2), Amazon Elastic Container Registry (Amazon ECR), and Amazon Simple Storage Service (Amazon S3).
  * Sufficient available IP addresses in your subnet.
  * A kube-proxy that runs successfully for the aws-node pod to progress into **Ready** status.
  * The [kube-proxy version](<https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html>) and [VPC CNI version](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>) that support the Amazon EKS version.



## Resolution

### Verify that the aws-node pod is in Running status on each worker node

To verify that the aws-node pod is in **Running** status on a worker node, run the following command:
    
    
    kubectl get pods -n kube-system -l k8s-app=aws-node -o wide

If the command output shows that the **RESTARTS** count is **0** , then the aws-node pod is in **Running** status. Try the steps in the **Verify that your subnet has sufficient free IP addresses available** section.

If the command output shows that the **RESTARTS** count is greater than **0** , then verify that the worker node can reach the API server endpoint of your Amazon EKS cluster. Run the following command:
    
    
    curl -vk https://eks-api-server-endpoint-url

### Verify connectivity to your Amazon EKS cluster

1\. Verify that your worker node's security group settings for Amazon EKS are configured correctly. For more information, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

2\. Verify that your worker node's network access control list (network ACL) rules for your subnet allow communication with the Amazon EKS API server endpoint.

**Important:** Allow inbound and outbound traffic on port 443.

3\. Verify that the **kube-proxy** pod is in **Running** status on each worker node:
    
    
    kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide

4\. Verify that your worker node can access API endpoints for Amazon EC2, Amazon ECR, and Amazon S3.

**Note:** Configure these services through [public endpoints](<https://docs.aws.amazon.com/general/latest/gr/aws-service-information.html>) or [AWS PrivateLink](<https://docs.aws.amazon.com/vpc/latest/userguide/endpoint-service.html>).

### Verify that your subnet has sufficient free IP addresses available

To list available IP addresses in each subnet in the Amazon Virtual Private Cloud (Amazon VPC) ID, run the following command:
    
    
    aws ec2 describe-subnets --filters "Name=vpc-id,Values= VPCID" | jq '.Subnets[] | .SubnetId + "=" + "\(.AvailableIpAddressCount)"'

**Note:** The **AvailableIpAddressCount** must be greater than **0** for the subnet where the pods are launched.

### Check whether your security group limits have been reached

If you reach the limits of your security group's per elastic network interface, then your [pod networking](<https://github.com/aws/amazon-vpc-cni-k8s#eni-allocation>) configuration can fail.

For more information, see [Amazon VPC quotas](<https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html>).

### Verify that you're running the latest stable version of the CNI plugin

To confirm that you have the latest version of the CNI plugin, see [Updating the Amazon VPC CNI plugin for Kubernetes self-managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>).

For additional troubleshooting, see the [AWS GitHub issues page](<https://github.com/aws/amazon-vpc-cni-k8s/issues>) and [release notes](<https://github.com/aws/amazon-vpc-cni-k8s/releases>) for the CNI plugin.

### Check the logs of the VPC CNI plugin on the worker node

If you create a pod, and an IP address doesn't get assigned to the container, then you receive the following error:
    
    
    failed to assign an IP address to container

To check the logs, go to the **/var/log/aws-routed-eni/** directory, and then locate the file names **plugin.log** and **ipamd.log**.

### Verify that your kubelet pulls the Docker container images

If your kubelet doesn't pull the Docker container images for the **kube-proxy** and **amazon-k8s-cni** containers, then you receive the following error:
    
    
    network plugin is not ready: cni config uninitialized

Make sure that you can reach the Amazon EKS API server endpoint from the worker node.

### Verify that the WARM_PREFIX_TARGET value is set correctly

**Note:** This applies only if [prefix delegation](<https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html>) is turned on. If prefix delegation is turned on, then check for the following logged error message:
    
    
    Error: Setting WARM_PREFIX_TARGET = 0 is not supported while WARM_IP_TARGET/MINIMUM_IP_TARGET is not set. 
    Please configure either one of the WARM_{PREFIX/IP}_TARGET or MINIMUM_IP_TARGET env variable

**WARM_PREFIX_TARGET** must be set to a value greater than or equal to **1**. If it's set to **0** , then you receive the following error:

See [CNI configuration variables](<https://github.com/aws/amazon-vpc-cni-k8s#cni-configuration-variables>) on the GitHub website for more information.

### Check the reserved space in the subnet

**Note:** This applies only if [prefix delegation](<https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html>) is turned on. If prefix delegation is turned on, then check for the following logged error message:
    
    
    InsufficientCidrBlocks

Make sure that you have sufficient available /28 IP CIDR (16 IPs) blocks in the subnet. All 16 IPs must be contiguous. If you don't have a /28 range of continuous IPs, then you receive the **InsufficientCidrBlocks** error.

To resolve the error, create a new subnet, and launch the pods from there. Also, use an Amazon EC2 subnet CIDR reservation to reserve space within a subnet with an assigned prefix. For more information, see [Use subnet CIDR reservations](<https://docs.aws.amazon.com/vpc/latest/userguide/subnet-cidr-reservation.html>).

### Updates that are made with Infrastructure as Code (IaC) roll back with conflicts

If you use Amazon EKS managed add-ons, the update errors that use the following services roll back when the conflict method is undefined:

  * [AWS Cloud Development Kit (AWS CDK)](<https://docs.aws.amazon.com/cdk/api/v1/docs/@aws-cdk_aws-eks-legacy.CfnAddon.html>)
  * [AWS CloudFormation](<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-eks-addon.html#cfn-eks-addon-resolveconflicts>)
  * [eksctl](<https://eksctl.io/usage/schema/#addons-resolveConflicts>) (from the eksctl website)



Correct methods are **NONE** , **OVERWRITE** , or **PRESERVE**.

  * If no method is defined, then the default is **NONE**. When the system detects conflicts, the update to the CloudFormation stack rolls back, and no changes are made.
  * To set the default configuration for the add-ons, use the overwrite method. You you must use **OVERWRITE** when you move from self-managed to Amazon EKS managed add-ons.
  * Use the **PRESERVE** method when you use custom defined configurations, such as **WARM_IP_TARGET** or [custom networking](<https://aws.github.io/aws-eks-best-practices/networking/custom-networking/>).



### Nodes are in NotReady status

When you have aws-nodes that aren't in the **Running** status, it's common for nodes to be in the **NotReady** status. For more information, see [How can I change the status of my nodes from NotReady or Unknown status to Ready status?](<https://aws.amazon.com/premiumsupport/knowledge-center/eks-node-status-ready>)

### Custom networking configuration challenges

When custom networking is active for the VPC CNI, ENIConfig custom resource definitions (CRDs) must define the correct subnet and security groups.

To verify if custom networking is active, describe the aws-node pod in the kube-system namespace. Then, see if the following environment variable is set to **true** :
    
    
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG

If custom networking is active, then check that the CRDs are configured properly.
    
    
    kubectl get ENIConfig -A -o yaml

Describe each entry that matches the Availability Zone name. The subnet IDs match for the VPC and worker node placement. The security groups are accessible or shared with the cluster security group. For more information on best practices, see the Amazon [EKS Best Practices Guides](<https://aws.github.io/aws-eks-best-practices/security/docs/network/#security-groups>) [](<https://aws.github.io/aws-eks-best-practices/security/docs/network/#security-groups>)on the GitHub website.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
