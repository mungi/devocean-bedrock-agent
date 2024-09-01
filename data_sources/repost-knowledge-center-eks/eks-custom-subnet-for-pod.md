Original URL: <https://repost.aws/knowledge-center/eks-custom-subnet-for-pod>

# How do I choose specific IP subnets to be used for pods in my Amazon EKS cluster?

I want to use custom subnets or IP ranges for my pods in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

Sometimes pods don't use all the available subnets in your Amazon EKS cluster. This happens when some node subnets have no available IP addresses but other subnets in the Amazon Virtual Private Cloud (Amazon VPC) remain underutilized.

Nodes and pods in Amazon EKS use IP addresses from the same address space: the IP CIDR ranges associated with the cluster VPC. Specifically, Amazon EKS assigns IPs for pods from the same subnet of the worker node where the pods are scheduled.

For example, let's say that node-1 is launched in subnet-1. That is, the node's primary elastic network interface is in subnet-1. Later, pod-A may get deployed and scheduled to node-1. By default, the Amazon VPC CNI plugin, allocates secondary elastic network interfaces and IPs in subnet-1 to assign an IP address to pod-A.

As a result, users have no direct control over custom allocation of pods to IP subnets because pods and nodes use the same subnet. If nodes have sufficient compute capacity to run many pods, then pods might use all the available IP addresses in the node subnet. New pods fail to run due to depleted IP addresses in the node subnet. This occurs even when other subnets in Amazon VPC may have available IP addresses.

## Resolution

You can fix this problem by using the custom networking component of Amazon VPC CNI. This feature lets you define specific subnets in the Amazon VPC cluster for use by your pods. It differentiates your subnets from those used by the worker nodes. As an added benefit, you can define security groups for your pods. See [Tutorial: Custom networking](<https://docs.aws.amazon.com/eks/latest/userguide/cni-custom-network.html>) for more information on custom networking use cases.

### Prerequisite

Before you begin, do the following:

As a best practice, make sure you have the latest version of Amazon VPC CNI plugin running in your cluster. Run the following command to verify the version in your Amazon VPC cluster:
    
    
    kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2

**Note:** For more information on the best version to use, see [Updating the Amazon VPC CNI plugin for self-managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>).

### Configure your custom subnet and IP ranges

Follow these steps to use the Amazon VPC CNI custom networking feature:

1\. Turn on the Amazon VPC CNI custom networking feature:
    
    
    kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true

2\. Create ENIConfig objects to define subnets and security groups for the pods to use.

An ENIConfig object defines one subnet and a list of security groups. When a node is annotated or labeled with only one ENIConfig object, all pods scheduled to that node use the subnet and security groups defined in that ENIConfig object.

You can automatically or manually associate an ENIConfig object with a node.

**Automatically associate ENIConfig objects with nodes**

This option allows only one ENIConfig object (one subnet) per Availability Zone (AZ). The ENIConfig name must be the name of the AZ.

1\. Create ENIConfig objects with the AZ name:
    
    
    cat <<EOF  | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: us-east-2a
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: subnet-XXXXXXXX
    EOF
    
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: us-east-2b
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: subnet-YYYYYYYYY
    EOF

2\. Enable Amazon VPC-CNI to automatically label nodes with the ENIConfig object that matches the node AZ.
    
    
    kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone

**Manually associate ENIConfig objects with nodes**

This option allows multiple ENIConfig objects per Availability Zone. Note that you can use a custom name for each ENIConfig object. Make sure that the node and the associated ENIConfig object are in the same Availability Zone.

**Note:** You can annotate only one node with one ENIConfig object, but you can annotate multiple nodes with the same ENIConfig object.

1\. Create ENIConfig objects with custom names, as follows:
    
    
    cat <<EOF  | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: my-conf-1-us-east-2a
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: subnet-XXXXXXXX
    EOF
    
    
    cat <<EOF | kubectl apply -f -
    apiVersion: crd.k8s.amazonaws.com/v1alpha1
    kind: ENIConfig
    metadata:
     name: my-conf-2-us-east-2a
    spec:
      securityGroups: 
        - sg-xxxxxxxxxxxx
      subnet: subnet-ZZZZZZZZZZ
    EOF

2\. Manually annotate nodes with **ENIConfig** objects. Make sure that the node and the subnet in the associated **ENIConfig** object are in the same Availability Zone.
    
    
    kubectl annotate node ip-192-168-0-126.us-east-2.compute.internal k8s.amazonaws.com/eniConfig=my-conf-1-us-east-2a

This manual annotation takes precedence over the label added automatically by Amazon VPC CNI.

### Launch new nodes to replace current worker node

Existing worker nodes may have secondary elastic network interfaces and IPs from the node subnet before you turned on the custom networking feature in Amazon VPC CNI. For this reason, you must launch new nodes so they can allocate secondary elastic network interfaces and IPs from the subnets defined in the ENIConfig object associated with the node

1\. Verify if you are using either of these node group options:

  * self-managed node group
  * managed node group with custom AMI ID



**Note:** If you're creating nodes in these node groups types, continue to Step 2 to manually define the maximum number of pods for your nodes. If you're launching nodes in the Managed Nodes Group without specifying a custom AMI, then Amazon EKS automatically updates the maximum number of pods for your nodes. See [Managed node groups](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html>) for more information.

2\. Determine the maximum number of pods per node. When using custom networking, the node’s primary network interface isn't used for pod IPs. To determine the max pods value using the max pods calculator script, see [Amazon EKS recommended maximum pods for each EC2 instance type](<https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html#determine-max-pods>).

**Note:** Use the cni-custom-networking-enabled flag with the above script to launch pods in a subnet other than in your own instance.

3\. Update the User Data script on your new nodes to include the required flags. For example:
    
    
    #!/bin/bash
    /etc/eks/bootstrap.sh my_cluster_name --use-max-pods false --kubelet-extra-args '--max-pods=20'

**Note:** Replace my_cluster_name with your EKS cluster name. For more information on Bootstrap functionality, see [awslabs/amazon-eks-ami](<https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh>) on the GitHub website.

4\. Recreate the pods to use the new pod custom networking configuration.

### Additional considerations

  * By default, traffic from pods to IP addresses external to the cluster VPC CIDR uses the node’s main interface and IP address. Therefore, this traffic doesn't use the subnet and security groups defined in the ENIConfig. Instead the traffic uses the security groups and subnet of the node's primary network interface. See [SNAT for pods](<https://docs.aws.amazon.com/eks/latest/userguide/external-snat.html>) for more information.
  * If you also use security groups for pods, then the security group that's specified in a SecurityGroupPolicy is used instead of the security group that's specified in the ENIConfig objects **.**
  * See [Simplify CNI custom networking](<https://github.com/aws/containers-roadmap/issues/867>) for the latest updates on the GitHub website.
  * To add more IP CIDR ranges to your VPC, follow the steps in [How do I use multiple CIDR ranges in Amazon EKS?](<https://repost.aws/knowledge-center/eks-multiple-cidr-ranges>)



* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
