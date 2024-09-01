Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-eksctl-cluster-node>

# How do I troubleshoot eksctl issues with Amazon EKS clusters and node groups?

When I use eksctl to create or update my Amazon Elastic Kubernetes Service (Amazon EKS), I encounter issues.

## Short description

The following are common issues you might encounter when you use **eksctl** to create or manage an Amazon EKS cluster or node group:

  * You don't know how to create a cluster with **eksctl**. See [Getting started with Amazon EKS - eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>) and the **eksctl** **section** of [Creating an Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html>).
  * You don't know how to specify kubelet bootstrap options for managed node groups. Follow the steps in the **Specify kubelet bootstrap options** Resolution section.
  * You don't how to change the instance type of an existing node group. You must create a new node group. See [Migrating to a new node group](<https://docs.aws.amazon.com/eks/latest/userguide/migrate-stack.html>) and [Nodegroup immutability](<https://eksctl.io/usage/managing-nodegroups/#nodegroup-immutability>) (from the **eskctl** website).
  * You reached the maximum number of AWS resources. Check your resources to see if you can delete ones that you're not using. If you still need more capacity, then see, [Requesting a quota increase](<https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html>).
  * You launch control plane instances in an Availability Zone with limited capacity. See [How do I resolve cluster creation errors in Amazon EKS?](<https://repost.aws/knowledge-center/eks-cluster-creation-errors>)
  * Your nodes fail to move to **Ready** state. Follow the steps in the **Resolve operation timeout issues** Resolution section.
  * Export values don't exist for the cluster. Follow the steps in the **Create the node group in private subnets** Resolution section.
  * You used an unsupported instance type to create a cluster or node group. Follow the steps in the **Check if your instance type is supported** Resolution section.



## Resolution

### Specify kubelet bootstrap options

By default, **eksctl** creates a bootstrap script and adds it to the launch template that the worker nodes run during the bootstrap process. To specify your own kubelet bootstrap options, use the **overrideBootstrapCommand** specification to override the **eksctl** bootstrap script. Use the **overrideBootstrapCommand** for managed and self-managed node groups.

Config file specification:
    
    
    managedNodeGroups:
      name: custom-ng
      ami: ami-0e124de4755b2734d
      securityGroups:
        attachIDs: ["sg-1234"]
      maxPodsPerNode: 80
      ssh:
        allow: true
      volumeSize: 100
      volumeName: /dev/xvda
      volumeEncrypted: true
      disableIMDSv1: true
      overrideBootstrapCommand: |
      #!/bin/bash
      /etc/eks/bootstrap.sh managed-cluster --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=custom-ng,eks.amazonaws.com/nodegroup-image=ami-0e124de4755b2734d'

**Note:** You can use **overrideBootstrapCommand** only when using a custom AMI. If you don't specify an AMI ID, then cluster creation fails.

**A custom AMI ID wasn't specified**

If you don't specify a custom AMI ID when creating managed node groups, then by default Amazon EKS uses an Amazon EKS-optimized AMI and bootstrap script. To use an Amazon EKS-optimized AMI with custom user data to specify bootstrap parameters, specify the AMI ID in your managed node group configuration.

To get the latest AMI ID for the latest Amazon EKS optimized AMI, run the following command:
    
    
    aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.21/amazon-linux-2/recommended/image_id --region Region --query "Parameter.Value" --output text

**Note:** Replace **Region** with your AWS Region.

### Resolve operation timeout issues

If you receive the following error when creating a node, then your node group may have timeout issues:
    
    
    waiting for at least 1 node(s) to become ready in "nodegroup"

When you create an EKS node group with **eksctl** , the **eksctl** CLI connects to the API server to continuously check for the Kubernetes node status. The CLI waits for the nodes to move to **Ready** state and eventually times out if the nodes fail to move.

The following are reasons why the nodes fail to move to **Ready** state:

  * The kubelet can't communicate or authenticate with the EKS API server endpoint during the bootstrapping process.
  * The **aws-node** and **kube-proxy** pods are not in **Running** state.
  * The Amazon Elastic Compute Cloud (Amazon EC2) worker node user data wasn't successfully run.



**The kubelet can't communicate with the EKS API server endpoint**

If the kubelet can't communicate with the EKS API server endpoint during the bootstrapping process, then get the EKS API server endpoint.

Run the following command on your worker node:
    
    
    curl -k https://123456DC0A12EC12DE0C12BC312FCC1A.yl4.us-east-1.eks.amazonaws.com
    {
      "kind": "Status",
      "apiVersion": "v1",
      "metadata": {
        
      },
      "status": "Failure",
      "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
      "reason": "Forbidden",
      "details": {
        
      },
      "code": 403
    }

The preceding command should return the HTTP 403 status code. If the command times out, you might have a network connectivity issue between the EKS API server and worker nodes.

To resolve the connectivity issue, complete one of the following steps that relates to your use case:

  * If the worker nodes are in a private subnet, then check that the EKS API server endpoint is in **Private** or **Public and Private access** mode.
  * If the EKS API server endpoint is set to **Private** , then you must apply certain rules for the private hosted zone to route traffic to the API server. The Amazon Virtual Private Cloud (Amazon VPC) attributes **enableDnsHostnames** and **enableDnsSupport** must be set to **True**. Also, the DHCP options set for the Amazon VPC must include **AmazonProvideDNS** in its domain list.
  * If you created the node group in public subnets, then make sure that the subnets' IPv4 public addressing attribute is set to **True**. If you don't set the attribute to **True** , then the worker nodes aren't assigned a public IP address and can't access the internet.
  * Check if the Amazon EKS cluster security group allows ingress requests to port 443 from the worker node security group.



**The kubelet can't authenticate with the EKS API server endpoint**

If the kubelet can't authenticate with the EKS API server endpoint during the bootstrapping process, then complete the following steps.

1\. Run the following command to verify that the worker node has access to the STS endpoint:
    
    
    telnet sts.region.amazonaws.com 443

**Note:** Replace **region** with your AWS Region.

2\. Make sure that the worker node's AWS Identity and Access Management (IAM) role was added to the **aws-auth** ConfigMap.

For example:
    
    
    apiVersion:v1 kind:ConfigMap metadata:name:aws-auth namespace:kube-system data:mapRoles:|
        - rolearn: ARN of instance role (not instance profile)
          username: system:node:{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes

**Note:** For Microsoft Windows node groups, you must add an additional **eks:kube-proxy-windows** RBAC group to the **mapRoles** section for the node group IAM role.

**The aws-node and kube-proxy pods aren't in Running state**

To check whether the **aws-node** and **kube-proxy** pods are in **Running** state, run the following command:
    
    
    kubectl get pods -n kube-system

If the **aws-node** pod is in **Failing** state, then check the connection between the worker node and the Amazon EC2 endpoint:
    
    
    ec2.region.amazonaws.com

**Note:** Replace **region** with your AWS Region.

Check that the AWS managed policies **AmazonEKSWorkerNodePolicy** and **AmazonEC2ContainerRegistryReadOnly** are attached to the node group's IAM role.

If the nodes are in a private subnet, then configure [Amazon ECR VPC endpoints](<https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html>) to allow image pulls from Amazon Elastic Container Registry (Amazon ECR).

If you use IRSA for your Amazon VPC CNI, then attach the **AmazonEKS_CNI_Policy** AWS managed policy to the IAM role that the **aws-node** pods use. You must also attach the policy to the node group's IAM role without IRSA.

**The EC2 worker node user data wasn't successfully run**

To check whether any errors occurred when the user data was run, review the cloud-init logs at **/var/log/cloud-init.log** and **/var/log/cloud-init-output.log**.

For more information, run the [EKS Logs Collector script](<https://github.com/awslabs/amazon-eks-ami/tree/master/log-collector-script>) on the worker nodes.

### Create the node group in private subnets

If you receive the following error when creating a node group, create the node group in private subnets:
    
    
    No export named eksctl--cluster::SubnetsPublic found. Rollack requested by user

If you created the Amazon EKS cluster with **PrivateOnly** networking, then AWS CloudFormation can't create public subnets. This means that export values won't exist for public subnets. If export values don't exist for the cluster, then node group creation fails.

To resolve this issue, you can include the **\--node-private-networking** flag when using the **eksctl** inline command. You can also use the **privateNetworking: true** specification within the node group configuration to request node group creation in private subnets.

### Update your eksctl version or specify the correct AWS Region

If you receive the following error, check your AWS Region:
    
    
    no eksctl-managed CloudFormation stacks found for "cluster-name"

If you use an **eksctl** version that's earlier than 0.40.0, then you can only view or manage Amazon EKS resources that you created with **eksctl**. To manage resources that weren't created with **eksctl** , update **eksctl** to version 0.40.0 or later. To learn about the commands that you can run for clusters that weren't created with **eksctl** , see [Non eksctl-created clusters](<https://eksctl.io/usage/unowned-clusters/>) (from the **eksctl** website).

Also, **eksctl** -managed CloudFormation stacks aren't found if you specify an incorrect AWS Region. To resolve this issue, make sure that you specify the correct Region where your Amazon EKS resources are located.

### Check if your instance type is supported

If you used an unsupported instance type to create a cluster or node, then you receive the following error:
    
    
    You must use a valid fully-formed launch template. The requested configuration is currently not supported. Please check the documentation for supported configurations'

To check if your instance type or other configurations are supported in a specific AWS Region, run the following command:
    
    
    aws ec2 describe-instance-type-offerings --region Region --query 'InstanceTypeOfferings[*].{InstanceType:InstanceType}'

**Note:** Replace **Region** with your AWS Region.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
