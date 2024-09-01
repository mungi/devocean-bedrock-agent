Original URL: <https://repost.aws/knowledge-center/eks-multiple-cidr-ranges>

# How do I use multiple CIDR ranges with Amazon EKS?

I want to use multiple CIDR ranges with Amazon Elastic Kubernetes Service (Amazon EKS) to resolve issues with my pods.

## Short description

Before you complete the steps in the **Resolution** section, confirm that you have the following:

  * A running [Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html>)
  * The latest version of the [AWS Command Line Interface (AWS CLI)](<https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html>)
  * [AWS Identity and Access Management (IAM) permissions](<https://docs.aws.amazon.com/vpc/latest/userguide/security-iam.html>) to manage an Amazon Virtual Private Cloud (Amazon VPC)
  * A [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>) with permissions to create custom resources and edit the DaemonsSet
  * An installed version of jq on your system  
**Note:** To download and install jq, see [Download jq](<https://jqlang.github.io/jq/download/>) on the jq website. 
  * A Unix-based system with a Bash shell
  * A VPC that's already configured



**Note:**

  * [You can associate private (RFC 1918) and public (non-RFC 1918) CIDR blocks to your VPC before or after you create your cluster](<https://aws.amazon.com/about-aws/whats-new/2019/05/amazon-eks-adds-support-for-public-ip-addresses-within-cluster-v/>).
  * In scenarios with carrier-grade network address translation (NAT), **100.64.0.0/10** is a private network range. The private network range is used in shared address space for communications between a service provider and its subscribers. For pods to communicate with the internet, you must have a NAT gateway configured at the route table. AWS Fargate clusters don't support DaemonSets. To add secondary CIDR ranges to Fargate profiles, [use subnets from your VPC's secondary CIDR blocks](<https://docs.aws.amazon.com/eks/latest/userguide/fargate.html#fargate-considerations>). Then, [tag your new subnets](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html>) before you add the subnets to your Fargate profile.



**Important:** In some situations, Amazon EKS can't communicate with nodes that you launch in subnets from CIDR blocks that you add to a VPC after you create a cluster. When you add CIDR blocks to an existing cluster, the updated range can take up to 5 hours to appear.

## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

In the following resolution, first set up your VPC. Then, configure the [CNI plugin](<https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html>) to use a new CIDR range.

### Add more CIDR ranges to expand your VPC network

Complete the following steps:

  1. Find your VPCs.  
If your VPCs have a tag, then run the following command to find your VPC:
    
        VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=yourVPCName | jq -r '.Vpcs[].VpcId')

If your VPCs don't have a tag, then run the following command to list all the VPCs in your AWS Region:
    
        aws ec2 describe-vpcs --filters  | jq -r '.Vpcs[].VpcId'

  2. To attach your VPC to a **VPC_ID** variable, run the following command:
    
        export VPC_ID=vpc-xxxxxxxxxxxx

To associate another CIDR block with the range **100.64.0.0/16** to the VPC, run the following command:
    
        aws ec2 associate-vpc-cidr-block --vpc-id $VPC_ID --cidr-block 100.64.0.0/16




### Create subnets with a new CIDR range

Complete the following steps:

  1. To list all the Availability Zones in your Region, run the following command:
    
        aws ec2 describe-availability-zones --region us-east-1 --query 'AvailabilityZones[*].ZoneName'

**Note:** Replace **us-east-1** with your Region.

  2. Choose the Availability Zone where you want to add the subnets, and then assign the Availability Zone to a variable. For example:
    
        export AZ1=us-east-1a
    export AZ2=us-east-1b
    export AZ3=us-east-1c

**Note:** To add more Availability Zones, create additional variables.

  3. To create new subnets under the VPC with the new CIDR range, run the following commands:
    
        CUST_SNET1=$(aws ec2 create-subnet --cidr-block 100.64.0.0/19 --vpc-id $VPC_ID --availability-zone $AZ1 | jq -r .Subnet.SubnetId)
    CUST_SNET2=$(aws ec2 create-subnet --cidr-block 100.64.32.0/19 --vpc-id $VPC_ID --availability-zone $AZ2 | jq -r .Subnet.SubnetId)
    CUST_SNET3=$(aws ec2 create-subnet --cidr-block 100.64.64.0/19 --vpc-id $VPC_ID --availability-zone $AZ3 | jq -r .Subnet.SubnetId)

  4. (Optional) Set a key-value pair to add a name tag for your subnets. For example:
    
        aws ec2 create-tags --resources $CUST_SNET1 --tags Key=Name,Value=SubnetA
    aws ec2 create-tags --resources $CUST_SNET2 --tags Key=Name,Value=SubnetB
    aws ec2 create-tags --resources $CUST_SNET3 --tags Key=Name,Value=SubnetC




### Associate your new subnet to a route table

Complete the following steps:

  1. To list the entire route table under the VPC, run the following command:
    
        aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID |jq -r '.RouteTables[].RouteTableId'

  2. To export the route table to the variable, run the following command:
    
        export RTASSOC_ID=rtb-abcabcabc

**Note:** Replace **rtb-abcabcabc** with the values from the previous step.

  3. Associate the route table to all new subnets. For example:
    
        aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CUST_SNET1
    aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CUST_SNET2
    aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CUST_SNET3

For more information, see the **Routing** section in [Example: VPC with servers in private subnets and NAT](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html#VPC_Scenario2_Routing>).




### Configure the CNI plugin to use the new CIDR range

Complete the following steps:

  1. Add the latest version of the [vpc-cni plugin](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>) to the cluster. To verify the version in the cluster, run the following command:
    
        kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2

To turn on the custom network configuration for the CNI plugin, run the following command:
    
        kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true

  2. To add the **ENIConfig** label to identify your worker nodes, run the following command:
    
        kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone

  3. To create an **ENIConfig** custom resource for all subnets and Availability Zones, run the following commands:
    
        cat <<EOF  | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ1
    spec:
      subnet: $CUST_SNET1
    EOF
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ2
    spec:
      subnet: $CUST_SNET2
    EOF
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ3
    spec:
      subnet: $CUST_SNET3
    EOF

**Note:** The **ENIConfig** must match the Availability Zone of your worker nodes.

  4. Launch the worker nodes so that the CNI plugin (ipamd) can allocate IP addresses from the new CIDR range to the new worker nodes.  
If you use custom networking, then the primary network interface isn't used for pod placement. In this case, you must first update **max-pods** with the following formula:
    
        maxPods = (number of interfaces - 1) \* (max IPv4 addresses per interface - 1) + 2

If you use a self-managed node group, then follow the steps in [Launching self-managed Amazon Linux nodes](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html>). Don't specify the subnets that you used in the **ENIConfig** resources. Instead, specify the following for the **BootstrapArguments** parameter:
    
        --use-max-pods false --kubelet-extra-args '--max-pods=<20>'

If you use a manager node group without a launch template or a specified Amazon Machine Image (AMI) ID, then managed node groups automatically calculate the max pods value. Follow the steps in [Creating a managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>). Or, use the Amazon EKS CLI to create the managed node group:
    
        aws eks create-nodegroup --cluster-name <sample-cluster-name> --nodegroup-name <sample-nodegroup-name> --subnets <subnet-123 subnet-456> --node-role <arn:aws:iam::123456789012:role/SampleNodeRole>

If you use a managed node group launch template with a specified AMI ID, then specify an Amazon EKS optimized AMI ID In your launch template. Or, use a custom AMI based on the Amazon EKS optimized AMI. Then, [use a launch template to deploy the node group](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami>), and provide the following user data in the launch template:
    
        #!/bin/bash
    /etc/eks/bootstrap.sh <my-cluster-name> --kubelet-extra-args <'--max-pods=20'>

  5. Note the security group for the subnet, and apply the security group to the associated **ENIConfig** :
    
        cat <<EOF  | kubectl apply -f -apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ1
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: $CUST_SNET1
    EOF
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ2
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: $CUST_SNET2
    EOF
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: $AZ3
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: $CUST_SNET3
    EOF

**Note:** replace **sg-xxxxxxxxxxxx** with your security group.

  6. [Terminate the old worker nodes](<https://repost.aws/knowledge-center/eks-worker-node-actions>).

  7. Launch a new deployment to test the configuration:
    
        kubectl create deployment nginx-test --image=nginx --replicas=10   
    kubectl get pods -o wide --selector=app=nginx-test

**Note:** In the preceding test deployment, ten new pods are added, and the new CIDR range is scheduled on new worker nodes.




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
