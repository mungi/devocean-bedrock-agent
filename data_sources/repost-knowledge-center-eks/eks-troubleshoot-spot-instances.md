Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-spot-instances>

# How do I launch and troubleshoot Spot Instances using Amazon EKS managed node groups?

I want to create a managed node group with Spot capacity for my Amazon Elastic Kubernetes Service (Amazon EKS) cluster and troubleshoot issues.

## Resolution

1\. [Install eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html#installing-eksctl>).

**Important:** Make sure to check all AWS Command Line Interface (AWS CLI) commands before using them and replace instances of **example** strings with your values. For example, replace **example_cluster** with your cluster name.

2\. Create a managed node group with Spot capacity in your existing cluster by running the following command:
    
    
    #eksctl create nodegroup --cluster=<example_cluster> --spot --instance-types=<Comma-separated list of instance types> --region <EKS cluster AWS region. Defaults to the value set in your AWS config (~/.aws/config)>

Example:
    
    
    #eksctl create nodegroup --cluster=demo --spot --instance-types=c3.large,c4.large,c5.large --region us-east-1

**Note:** There are other flags you can set up while creating a Spot managed node group, like **\--name** , **\--nodes** , **\--nodes-min** , and **\--nodes-max**. Get the complete list of all available flags by running the following command:
    
    
    #eksctl create nodegroup --help

3\. If you maintain an **eksctl** **ClusterConfig** config file for your cluster, then you can also create a Spot managed node group with that file. Create Spot Instances using managed node groups with a **spot-cluster.yaml** config fileby running the following command:
    
    
    apiVersion: eksctl.io/v1alpha5
    kind: ClusterConfig
    metadata:
      name: <example_cluster>
      region: <example_region>
    managedNodeGroups:
    - name: spot
      instanceTypes: ["c3.large","c4.large","c5.large","c5d.large","c5n.large","c5a.large"]
      spot: true

4\. Create a node group using the config file by running the following command:
    
    
    # eksctl create nodegroup -f spot-cluster.yaml

### Troubleshooting issues related to Spot Instances in Amazon EKS

Check the health of a managed node group by using **eksctl** or the Amazon EKS console as follows:
    
    
    $ eksctl utils nodegroup-health --name=<example_nodegroup> --cluster=<example_cluster>

The health of Spot managed node groups can degrade with an error, due to a lack of Spot capacity for used instance types. See the following error for example:
    
    
    AsgInstanceLaunchFailures Could not launch Spot Instances. UnfulfillableCapacity - Unable to fulfill capacity due to your request configuration. Please adjust your request and try again. Launching EC2 instance failed.

**Note:** To successfully adopt Spot Instances, it's a best practice to implement Spot Instance diversification as part of your Spot managed node group configuration. Spot Instance diversification helps to get capacity from multiple Spot Instance pools. Getting this capacity is for both scaling up and replacing Spot Instances that might receive a Spot Instance termination notification.

If your cluster Spot node groups must be provisioned with instance types that adhere to a 1 vCPU:4 GB of RAM ratio, then diversify your Spot Instance pools. Diversify your instance pools by using one of the following strategies:

  * Create multiple node groups with each having different sizes. For example, a node group of size 4 vCPUs and 16 GB of RAM, and another node group of 8 vCPUs and 32 GB of RAM.
  * Implement instance diversification within the node groups. Do this by selecting a mix of instance types and families from different Spot Instance pools that meet the same vCPUs and memory criteria.



Use amazon-ec2-instance-selector to select the relevant instance types and families with sufficient number of vCPUs and RAM by running the following command:
    
    
    curl -Lo ec2-instance-selector https://github.com/aws/amazon-ec2-instance-selector/releases/download/v2.0.3/ec2-instance-selector-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && chmod +x ec2-instance-selector
    sudo mv ec2-instance-selector /usr/local/bin/
    ec2-instance-selector --version

Example:
    
    
    ec2-instance-selector --vcpus 4 --memory 16 --gpus 0 --current-generation -a x86_64 --deny-list '.*[ni].*'

The preceding command displays a list similar to the following. Use these instances as part of one of your node groups.

  * **m4.xlarge**
  * **m5.xlarge**
  * **m5a.xlarge**
  * **m5ad.xlarge**
  * **m5d.xlarge**
  * **t2.xlarge**
  * **t3.xlarge**
  * **t3a.xlarge**



**Note:** Instance types of existing node groups can't be changed using Amazon EKS API. It's a best practice to create a new Spot node group with your desired instance types. Enter the following into the **eksctl create nodegroup** command. Note the new **eksctl** flag to indicate that a node group runs Spot Instances: **\--spot**.
    
    
    $eksctl create nodegroup --cluster=<example_cluster> --spot --instance-types m5.xlarge,m4.xlarge,m5a.xlarge,m5d.xlarge,m5n.xlarge,m5ad.xlarge --region <example_region>

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
