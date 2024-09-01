Original URL: <https://repost.aws/knowledge-center/eks-bottlerocket-node-group>

# How do I use the Bottlerocket AMI to create a managed node group in Amazon EKS?

I want to use eksctl to launch the Bottlerocket Amazon Machine Image (Bottlerocket AMI) to create a managed node group in Amazon Elastic Kubernetes Service (Amazon EKS).

## Resolution

### Prerequisite

Before you complete the resolution steps, confirm that you have eksctl version 0.124.0 or later.

To check your version, run the following command:
    
    
    $ eksctl version

### Create a bottlerocket.yaml file

Open the terminal where you installed eksctl. Then, use the following example to create and save the bottlerocket.yaml file.

**Note:**

  * Replace **mybottlerocket-cluster** with the name of your cluster. The name can contain only hyphens and alphanumeric characters that are case sensitive. It must start with an alphabetic character and can't be longer than 100 characters.
  * Replace **bottlerocket-nodegroup** with a name for your node group. The name can contain only hyphens and alphanumeric characters that are case sensitive. It must start with an alphabetic character and can't be longer than 100 characters.
  * Specify the instance type. For example, to deploy on an Arm instance, replace m5.xlarge with an Arm instance type.
  * Replace **eks_bottlerocket** with the name of an Amazon Elastic Compute Cloud (Amazon EC2) SSH key pair. After you launch the nodes, use SSH to connect to them.  
**Note:** If you don't have an Amazon EC2 SSH key pair, then [create one in the AWS Management Console](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html#having-ec2-create-your-key-pair>). For more information, see [Amazon EC2 key pairs and Linux instances](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html>).


    
    
    ---
    apiVersion: eksctl.io/v1alpha5
    kind: ClusterConfig
     
    metadata:
      name: mybottlerocket-cluster
      region: us-west-2
      version: '1.27'
     
    managedNodeGroups:
      - name: bottlerocket-nodegroup
        instanceType: m5.xlarge
        minSize: 2
        maxSize: 4
        desiredCapacity: 3
        amiFamily: Bottlerocket
        labels: { role: br-worker }
        tags:
           nodegroup-type: Bottlerocket
        ssh:
          allow: true
          publicKeyName: eks_bottlerocket

**Note:** You can create Bottlerocket-managed node groups for general purpose, compute-optimized, memory-optimized, and storage-optimized instance types. The Bottlerocket AMI doesn't support accelerated computing instance types.

### Create the node group and list its nodes in the EKS cluster

  1. Run the following eksctl command to create a node group:
    
        $ eksctl create nodegroup -f bottlerocket.yaml[✔]  created 1 nodegroup(s) in cluster "mybottlerocket-cluster"

  2. List the nodes in the EKS cluster and your attributes:
    
        $ kubectl get nodes -o=custom-columns=NODE:.metadata.name,ARCH:.status.nodeInfo.architecture,OS-Image:.status.nodeInfo.osImage,OS:.status.nodeInfo.operatingSystemNODE                                          ARCH    OS-Image                                OS
    ip-192-168-xx-xx.us-west-2.compute.internal   amd64   Bottlerocket OS 1.17.0 (aws-k8s-1.27)   linux
    ip-192-168-xx-xx.us-west-2.compute.internal   amd64   Bottlerocket OS 1.17.0 (aws-k8s-1.27)   linux




### Connect to the Bottlerocket AMI nodes (optional)

Connect to the new Bottlerocket nodes through an [AWS Systems Manager](<https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html>) session. AWS Systems Manager Agent (SSM Agent) runs on the node because you already turned on Systems Manager permission for the node instance role. 

Run the following command to find the instance IDs:
    
    
    $ kubectl get nodes -o=custom-columns=NODE:.metadata.name,ARCH:.status.nodeInfo.architecture,OS-Image:.status.nodeInfo.osImage,OS:.status.nodeInfo.operatingSystem,InstanceId:.spec.providerIDNODE                                           ARCH    OS-Image                                OS      InstanceId
    ip-192-168-xx-xx.us-west-2.compute.internal    amd64    Bottlerocket OS 1.17.0 (aws-k8s-1.27)   linux   aws:///us-west-2b/i-0cf32f13f60c2f501
    ip-192-168-xx-xx.us-west-2.compute.internal    amd64    Bottlerocket OS 1.17.0 (aws-k8s-1.27)   linux   aws:///us-west-2b/i-0f31328a5d21cb092
    ip-192-168-xx-xx.us-west-2.compute.internal    amd64    Bottlerocket OS 1.17.0 (aws-k8s-1.27)   linux   aws:///us-west-2b/i-08c218b729ecf9b5d

### Start a Systems Manager session

By default, Bottlerocket has a control container that runs on a separate instance of **containerd**. This container runs SSM Agent and lets you run commands or start interactive shell sessions on Bottlerocket nodes.

Choose an instance, and launch a Systems Manager session. The following example shows a Systems Manager session command for the **i-0cf32f13f60c2f501** instance:
    
    
    $ aws ssm start-session --target i-0cf32f13f60c2f501 --region us-west-2
    Starting session with SessionId: EKS-Test-User-0077e4c89ad2bc888
              Welcome to Bottlerocket's control container!

## Related information

[Launching self-managed Bottlerocket nodes](<https://docs.aws.amazon.com/eks/latest/userguide/launch-node-bottlerocket.html>)

[What is Amazon EKS?](<https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html>)

[Instance types (Amazon EC2)](<https://aws.amazon.com/ec2/instance-types/>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
