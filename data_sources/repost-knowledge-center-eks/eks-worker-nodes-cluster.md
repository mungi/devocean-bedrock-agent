Original URL: <https://repost.aws/knowledge-center/eks-worker-nodes-cluster>

# How can I get my worker nodes to join my Amazon EKS cluster?

My worker nodes won't join my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

To get your worker nodes to join your Amazon EKS cluster, complete the following steps:

  * Use AWS Systems Manager automation runbook to Identify common issues.
  * Confirm that you have DNS support for your Amazon Virtual Private Cloud (Amazon VPC).
  * Confirm that your instance profile's worker nodes have the correct permissions.
  * Configure the user data for your worker nodes.
  * Verify that networking is configured correctly for your Amazon VPC subnets.
  * Verify that your worker nodes are in the same VPC as your EKS cluster.
  * Update the **aws-auth** ConfigMap with the **NodeInstanceRole** of your worker nodes.
  * Meet the security group requirements of your worker nodes.
  * Set the tags for your worker nodes.
  * Confirm that your worker nodes can reach the API server endpoint for your EKS cluster.
  * Confirm that the cluster role is correctly configured for your EKS cluster.
  * For AWS Regions that support AWS Security Token Service (AWS STS) endpoints, confirm that the Regional AWS STS endpoint is activated.
  * Be sure that the AMI is configured to work with Amazon EKS and includes the required components.
  * Use SSH to connect connect to your worker node's Amazon Elastic Compute Cloud (Amazon EC2) instance, and then search through **kubelet** agent logs for errors.
  * Use the Amazon EKS log collector script to troubleshoot errors.



**Important:** The following steps don't include configurations that are required to register worker nodes in environments where the following criteria aren't met:

  * In the VPC for your cluster, the configuration parameter **domain-name-servers** is set to **AmazonProvidedDNS**. For more information, see [DHCP options sets](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_DHCP_Options.html>).
  * You're using an Amazon EKS-optimized Linux Amazon Machine Image (AMI) to launch your worker nodes.  
**Note:** The [Amazon EKS-optimized Linux AMI](<https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html>) provides all necessary configurations, including a **/etc/eks/bootstrap.sh** bootstrap script, to register worker nodes to your cluster.



## Resolution

### Use the Systems Manager automation runbook to identify common issues

Use the [AWSSupport-TroubleshootEKSWorkerNode](<https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awssupport-troubleshooteksworkernode.html>) runbook to find common issues that prevent worker nodes from joining your cluster.

**Important:** For the automation to work, your worker nodes must have permission to access Systems Manager and have Systems Manager running. To grant this permission, attach the [AmazonSSMManagedInstanceCore](<https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview>) policy to the AWS Identity and Access Management (IAM) role. This is the IAM role that corresponds to your Amazon EC2 instance profile. This is the default configuration for Amazon EKS managed node groups that you create through eksctl. Use the following format for your cluster name: **[-a-zA-Z0-9]{1,100}$**.

  1. [Open the runbook](<https://console.aws.amazon.com/systems-manager/automation/execute/AWSSupport-TroubleshootEKSWorkerNode>).
  2. Check that the AWS Region in the AWS Management Console is set to the same Region as your cluster.  
**Note:** Review the **Document details** section of the runbook for more information about the runbook.
  3. In the **Input parameters** section, specify the name of your cluster in the **ClusterName** field and Amazon EC2 instance ID in the **WorkerID** field.
  4. **(Optional)** In the **AutomationAssumeRole** field, specify the IAM role to allow Systems Manager to perform actions. If you don't specify it, then the IAM permissions of your current IAM entity are used to perform the actions in the runbook.
  5. Choose **Execute**.
  6. Check the **Outputs** section to see why your worker node isn't joining your cluster and steps that you can take to resolve it.



### Confirm that you have DNS support for your Amazon VPC

Confirm that the Amazon VPC for your EKS cluster has **DNS hostnames** and **DNS resolution** turned on.

To check these attributes and turn these on, complete the following steps:

  1. Open the [Amazon VPC console](<https://console.aws.amazon.com/vpc/>).
  2. In the navigation pane, choose **Your VPCs**.
  3. Select the VPC that you want to edit.
  4. Under the **Details** tab, check if DNS hostnames and DNS resolution are turned on.
  5. If they aren't turned on, select **Enable** for both attributes.
  6. Choose **Save changes**.



For more information, see [View and update DNS attributes for your VPC](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-updating>).

### Confirm that your instance profile's worker nodes have the right permissions

Attach the following AWS managed polices to the role that's associated with your instance profile's worker nodes:

  * AmazonEKSWorkerNodePolicy
  * AmazonEKS_CNI_Policy
  * AmazonEC2ContainerRegistryReadOnly



To attach policies to roles, see [Adding IAM identity permissions (console)](<https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-attach-detach.html#add-policies-console>).

### Configure the user data for your worker nodes

**Note:** If you use AWS CloudFormation to launch your worker nodes, then you don't have to configure the user data for your worker nodes. Instead, follow the instructions for [launching self-managed Amazon Linux nodes](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html#aws-management-console>) in the AWS Management Console.

If you launch your worker nodes using managed node groups, then you don't have to configure any user data with [Amazon EKS optimized Amazon Linux AMIs](<https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html>). You must configure the user data only if you use custom AMIs to launch your worker nodes through managed node groups.

If you're using Amazon managed node groups with custom launch template, then specify the correct user data in the launch template. If the Amazon EKS cluster is a fully private cluster that uses VPC endpoints to make connections, then specify the following in the user data:

  * certificate-authority
  * api-server-endpoint
  * DNS cluster IP



If required, [provide user data to pass arguments to the bootstrap.sh file included with an Amazon EKS optimized Linux/Bottlerocket AMI](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami>).

To configure user data for your worker nodes, [specify the user data when you launch your Amazon EC2 instances](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-launch-instance-wizard>).

For example, if you use a third-party tool such as Terraform, then update the **User data** field to launch your EKS worker nodes:
    
    
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${ClusterName} ${BootstrapArguments}

**Important:**

  * Replace **${ClusterName}** with the name of your EKS cluster.
  * Replace **${BootstrapArguments}** with additional bootstrap values, or leave this property blank.



### Verify that networking is configured correctly for your Amazon VPC subnets

  * If you use an internet gateway, then be sure that it's attached to the route table correctly without any blackhole.
  * If you use a NAT gateway, then be sure that it's configured correctly in a public subnet. Also, verify that the route table doesn’t contain any blackhole.
  * If you use VPC private endpoints for a fully private cluster, then be sure that you have the following endpoints:  
com.amazonaws.region.ec2 (interface endpoint)  
com.amazonaws.region.ecr.api (interface endpoint)  
com.amazonaws.region.ecr.dkr (interface endpoint)  
com.amazonaws.region.s3 (gateway endpoint)  
com.amazonaws.region.sts (interface endpoint)
  * Pods that you configure with IAM roles for service accounts acquire credentials from an AWS Security Token Service (AWS STS) API call. If there's no outbound internet access, then you must create and use an AWS STS VPC endpoint in your VPC.
  * The security group for the VPC endpoint must have an inbound rule that allows traffic from port 443. For more information, see [Control traffic to resources using security groups](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html>).
  * Be sure that the policy that's attached to the VPC endpoint has the required permissions.



**Note:** If you're using any other AWS service, then you must create those endpoints. For some commonly used services and endpoints, see [Private cluster requirements](<https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html>). Also, you might [create an endpoint service](<https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html#create-endpoint-service-nlb>) based on your use case.

### Verify that your worker nodes are in same Amazon VPC as your EKS cluster

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>).
  2. Choose **Clusters** , and then select your cluster.
  3. In the **Networking** section, identify the subnets that are associated with your cluster.



**Note:** You can configure different subnets to launch your worker nodes in. The subnets must exist in the same Amazon VPC and be appropriately tagged. Amazon EKS automatically manages tags only for subnets that you configure during cluster creation. Therefore, make sure that you tag the subnets appropriately.

For more information, see [Subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-subnets>).

### Update the aws-auth ConfigMap with the NodeInstanceRole of your worker nodes

Verify that the **aws-auth** ConfigMap is correctly configured with your worker node's [IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>) and not the instance profile.

To check the aws-auth ConfigMap file, run the following command:
    
    
    kubectl describe configmap -n kube-system aws-auth

If the aws-auth ConfigMap isn't configured correctly, then you see the following error:
    
    
    571 reflector.go:153\] k8s.io/kubernetes/pkg/kubelet/kubelet.go:458 : Failed to list \*v1.Node: Unauthorized

### Meet the security group requirements of your worker nodes

Confirm that your control plane's security group and worker node security group are configured with [settings that are best practices](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) for inbound and outbound traffic. Also, confirm that your custom network ACL rules are configured to allow traffic to and from **0.0.0.0/0** for ports **80** , **443** , and **1025-65535**.

### Set the tags for your worker nodes

For the **Tag** property of your worker nodes, set **Key** to **kubernetes.io/cluster/clusterName** and set **Value** to **owned**.

For more information, see [VPC requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-vpc>).

### Confirm that your worker nodes can reach the API server endpoint for your EKS cluster

Consider the following points:

  * You can launch worker nodes in a subnet that's associated with a route table that routes to the API endpoint through a NAT or internet gateway.
  * If you launch your worker nodes in a restricted private network, then confirm that your worker nodes can reach the EKS API server endpoint.
  * If you launch worker nodes with an Amazon VPC that uses a custom DNS instead of **AmazonProvidedDNS** , then they might not resolve the endpoint. An unresolved endpoint happens when public access to the endpoint is deactivated, and only private access is activated. For more information, see [Turning on DNS resolution for Amazon EKS cluster endpoints](<https://aws.amazon.com/blogs/compute/enabling-dns-resolution-for-amazon-eks-cluster-endpoints/>).



### Confirm that the cluster role is correctly configured for your cluster

Your cluster must have the cluster role with the minimum **AmazonEKSClusterPolicy** permission. Also, the trust relationship of your cluster must allow **eks.amazonaws.com** service for **sts:AssumeRole**.

Example:
    
    
    {
      "Version": "2012-10-17",
      "Statement": \[
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "eks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      \]
    }

For more information, see [Amazon EKS cluster IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html>).

### Confirm that Regional STS endpoints are activated

If the cluster is in a [Region that supports STS endpoints](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html#id_credentials_region-endpoints>), then [activate the Regional STS endpoint](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html#sts-regions-activate-deactivate>) to authenticate the **kubelet**. The **kubelet** can then create the node object.

### Be sure that the AMI is configured to work with EKS and includes the required components

If the AMI used for worker nodes isn't the [Amazon EKS optimized Amazon Linux AMI](<https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html>), then confirm that the following Kubernetes components are in active state:

  * kubelet
  * AWS IAM Authenticator
  * Docker (Amazon EKS version 1.23 and earlier)
  * containerd



### Connect to your EKS worker node instance with SSH and check kubelet agent logs

The **kubelet** agent is configured as a systemd service.

1\. To validate your **kubelet** logs, run the following command:
    
    
    journalctl -f -u kubelet

2\. To resolve any issues, check the [Amazon EKS troubleshooting guide](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>) for common errors.

### Use Amazon EKS log collector script to troubleshoot errors

You can use the log files and operating system logs to troubleshoot the issues in your Amazon EKS.

You must use SSH to connect into the worker node with the issue and run the following script:
    
    
    curl -O https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/log-collector-script/linux/eks-log-collector.sh 
    
    sudo bash eks-log-collector.sh

## Related information

[How do I troubleshoot Amazon EKS managed node group creation failures?](<https://repost.aws/knowledge-center/resolve-eks-node-failures>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
