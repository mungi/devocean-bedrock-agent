Original URL: <https://repost.aws/knowledge-center/eks-multiple-node-groups-eksctl>

# How do I create multiple node groups for Amazon EKS nodes with eksctl?

I want to create multiple node groups for Amazon Elastic Kubernetes Service (Amazon EKS) nodes with eksctl.

## Short description

You can create a node group with [eksctl](<https://eksctl.io/>) and default parameters. Or, create one with custom parameters and a configuration file for multiple node groups.

To install the latest version of eksctl, see [Installation](<https://eksctl.io/installation/>) on the eksctl website.

To confirm that **eksctl** is configured and installed on the terminal with the correct permissions, run the following command:
    
    
    $ eksctl version

Then, choose one of the following resolutions based on the type of parameters you want to use.

## Resolution

### Create a node group with default parameters

  1. To create an additional node group with default parameters, run this command:
    
        $ eksctl create nodegroup --cluster=yourClusterName --name=yourNodeGroupName --region yourRegionName

  2. The following are the default parameters:
    
        Instance type = m5.largeAMI : lastest AWS EKS AMI
    Nodes-desired capacity = 2
    Nodes-min capacity =2 
    Nodes-max capacity=2

**Note:** By default, new node groups inherit the version of Kubernetes from the control plane (**–version=auto**). You can specify a different version of Kubernetes (for example, **version=1.27**). To use the latest version of Kubernetes, run the **–version=latest** command.

  3. To confirm that the new node groups are attached to the cluster and verify that the nodes have joined the cluster, run these commands:
    
        $ kubectl get nodes
    $ eksctl get nodegroups --cluster yourClusterName --region yourRegionName

In the output, confirm that the node's status is READY and the node group status is ACTIVE. For example:

**Nodegroup status**
    
        $ eksctl get nodegroups --cluster yourClusterName --region yourRegionName
    
    CLUSTER      NODEGROUP  STATUS  CREATED   MIN SIZE  MAX SIZE  DESIRED CAPACITY    INSTANCE TYPE    IMAGE ID    ASG NAME   TYPE  
    clusterName  ngWorkers  ACTIVE  Date&Time    *        *              *             m5.large      AL2_x86_64   ASGNAME   managed
    

****Node status

* * *
    
        $ kubectl get nodes
    
    NAME                                    STATUS ROLES AGE VERSION         
    ip-***-**-**-***.region.compute.internal Ready <none> 4h v1.2x.x-eks-xx  
    ip-***-**-***-**.region.compute.internal Ready <none> 4h v1.2x.x-eks-xx
    
    Create a node group with custom parameters
    
    




### Create a node group with custom parameters

  1. Define the parameters for the new node group in a configuration file. For example:
    
        kind: ClusterConfig
    apiVersion: eksctl.io/v1alpha5
    metadata:
        name: clusterName
        region: region
    nodeGroups:
      - name: ngWorkers
        availabilityZones: ["az-name"]
        desiredCapacity: 3
        instanceType: m5.large
        iam:
          instanceProfileARN: "arn:aws:iam::11111:instance-profile/eks-nodes-base-role" #Attaching IAM role
          instanceRoleARN: "arn:aws:iam::1111:role/eks-nodes-base-role"
        privateNetworking: true
        securityGroups:
          withShared: true
          withLocal: true
          attachIDs: ['sg-11111', 'sg-11112']
        ssh:
          publicKeyName: 'my-instance-key'
        kubeletExtraConfig:
            kubeReserved:
                cpu: "300m"
                memory: "300Mi"
                ephemeral-storage: "1Gi"
            kubeReservedCgroup: "/kube-reserved"
            systemReserved:
                cpu: "300m"
                memory: "300Mi"
                ephemeral-storage: "1Gi"
        tags:
          'environment': 'development'
      - name: ng-2-builders #example of a nodegroup that uses 50% spot instances and 50% on demand instances:
        minSize: 2
        maxSize: 5
        instancesDistribution:
          maxPrice: 0.017
          instanceTypes: ["t3.small", "t3.medium"] # At least two instance types should be specified
          onDemandBaseCapacity: 0
          onDemandPercentageAboveBaseCapacity: 50
          spotInstancePools: 2
        tags:
          'environment': 'production'

For more information on supported parameters and nodegroup types, see [Nodegroups](<https://eksctl.io/usage/nodegroups/>) on the eksctl website.

  2. To create an additional node group with the configuration file, run the following command:
    
        $ eksctl create nodegroup --config-file=yourConfigFileName

  3. (Optional) The command in step 2 deploys an AWS CloudFormation stack to create resources for EKS node group. To check the stack status, access the [CloudFormation console](<https://console.aws.amazon.com/cloudformation/>) and confirm that the AWS Region is the same as the cluster's.   
After the stack is in a **CREATE_COMPLETE** state, the eksctl command exits successfully.

  4. To confirm that the new node groups are attached to the cluster and to verify that the nodes joined the cluster, run these commands:
    
        $ kubectl get nodes
    $ eksctl get nodegroups --cluster yourClusterName --region yourRegionName

In the output, confirm that the node's status is READY and the node group status is ACTIVE. For example:  
**Nodegroup status**
    
        $ eksctl get nodegroups --cluster yourClusterName --region yourRegionName
    
    CLUSTER      NODEGROUP  STATUS  CREATED   MIN SIZE  MAX SIZE  DESIRED CAPACITY    INSTANCE TYPE    IMAGE ID    ASG NAME   TYPE  
    clusterName  ngWorkers  ACTIVE  Date&Time    *        *              *             m5.large      AL2_x86_64   ASGNAME   managed

**Node status**
    
        $ kubectl get nodes
    
    NAME                                    STATUS ROLES AGE VERSION         
    ip-***-**-**-***.region.compute.internal Ready <none> 4h v1.2x.x-eks-xx  
    ip-***-**-***-**.region.compute.internal Ready <none> 4h v1.2x.x-eks-xx




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
