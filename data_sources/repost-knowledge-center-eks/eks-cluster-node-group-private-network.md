Original URL: <https://repost.aws/knowledge-center/eks-cluster-node-group-private-network>

# How do I create an Amazon EKS cluster and node groups that don't require access to the internet?

I want to create an Amazon Elastic Kubernetes Service (Amazon EKS) cluster and node groups with PrivateOnly networking. I don't want to use an internet gateway or network address translation (NAT) gateway.

## Short description

Use AWS PrivateLink to create an Amazon EKS cluster and its node group without using a route to the internet.

## Resolution

**Create an Amazon Virtual Private Cloud (Amazon VPC) for your Amazon EKS cluster**

1\. [Create an AWS CloudFormation stack](<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html#cfn-using-console-initiating-stack-creation>) using the following template:
    
    
    https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-06-10/amazon-eks-fully-private-vpc.yaml

The stack creates a VPC with three PrivateOnly subnets and [VPC endpoints](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html>) for the required services. A PrivateOnly subnet has a route table with a default [local route](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#RouteTables>) and no access to the internet.

**Important:** Although the AWS CloudFormation template creates the VPC endpoints with a full access policy, you can further restrict the [policy](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints-access.html#vpc-endpoint-policies>) based on your requirements.

**Tip:** To review all the VPC endpoints after the stack is created, open the [Amazon VPC console](<https://console.aws.amazon.com/vpc/>), and then choose Endpoints from the navigation pane.

2\. Open the [AWS CloudFormation console](<https://console.aws.amazon.com/cloudformation/>).

3\. In the navigation pane, choose **Stacks**.

4\. Choose your stack, and then choose the **Outputs** tab. This tab has information on your subnets that you'll need later, including the VPC ID.

**Configure the Amazon EKS cluster config file, and then create the cluster and node group**

1\. In the following config file, update the AWS Region and three PrivateOnly subnets that you created in the Create a VPC for your Amazon EKS cluster section. You can also modify other attributes, or add more attributes, in the config file. For example, you can update **name** , **instanceType** , or **desiredCapacity**.

Example config file:
    
    
    apiVersion: eksctl.io/v1alpha5
    kind: ClusterConfig
    metadata:
      name: prod
      region: us-east-1   
    nodeGroups:
      - name: ng-1
        instanceType: m5.xlarge
        desiredCapacity: 2
        privateNetworking: true
    vpc:
      subnets:
        private:
          us-east-1a:
            id: "subnet-0111111111111111"
          us-east-1b:
            id: "subnet-0222222222222222"
          us-east-1c:
            id: "subnet-0333333333333333"
      clusterEndpoints:
        publicAccess:  true
        privateAccess: true

In the preceding config file, for **nodeGroups** , set **privateNetworking** to **true**. For **clusterEndpoints** , set **privateAccess** to **true**.

**Important:** The **eksctl** tool isn't required for the resolution. You can use other tools or the Amazon EKS console to create the Amazon EKS cluster and nodes. However, if you use other tools or the console to create a [node](<https://docs.aws.amazon.com/eks/latest/userguide/worker.html>), you must pass the CA certificate and API server endpoint of the Amazon EKS cluster as arguments, while calling the [bootstrap script](<https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh#L235>) for the node.

2\. To create an Amazon EKS cluster and node group based on the updated config file in step 1, run the following command:
    
    
    $ eksctl create cluster -f config.yaml

**Note** : Some **eksctl** versions can cause errors with creating the Kubeconfig file when the file mentions **client.authentication.k8s.io/v1alpha1**. You can update Kubeconfig file by running the [update-kubeconfig](<https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html>) command (make sure that you are using the latest [AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions>) for this).

The preceding command creates an Amazon EKS cluster and node group in a PrivateOnly network using AWS PrivateLink with no access to internet. The process takes approximately 30 minutes.

The output is similar to the following:
    
    
    Output
    [ℹ]  eksctl version 0.21.0
    [ℹ]  using region us-east-1
    [✔]  using existing VPC (vpc-01234567) and subnets (private:[subnet-01111111111111111 subnet-02222222222222222 subnet-03333333333333333] public:[])
    [!]  custom VPC/subnets will be used; if resulting cluster doesn't function as expected, make sure to review the configuration of VPC/subnets
    [ℹ]  nodegroup "ng-1" will use "ami-0ee0652ac0722f0e3" [AmazonLinux2/1.16]
    [ℹ]  using Kubernetes version 1.16
    [ℹ]  creating EKS cluster "prod" in "us-east-1" region with un-managed nodes
    [ℹ]  1 nodegroup (ng-1) was included (based on the include/exclude rules)
    [ℹ]  will create a CloudFormation stack for cluster itself and 1 nodegroup stack(s)
    [ℹ]  will create a CloudFormation stack for cluster itself and 0 managed nodegroup stack(s)
    [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=prod'
    [ℹ]  CloudWatch logging will not be enabled for cluster "prod" in "us-east-1"
    [ℹ]  you can enable it with 'eksctl utils update-cluster-logging --region=us-east-1 --cluster=prod'
    [ℹ]  Kubernetes API endpoint access will use provided values {publicAccess=true, privateAccess=true} for cluster "prod" in "us-east-1"
    [ℹ]  2 sequential tasks: { create cluster control plane "prod", 2 sequential sub-tasks: { update cluster VPC endpoint access configuration, create nodegroup "ng-1" } }
    [ℹ]  building cluster stack "eksctl-prod-cluster"
    [ℹ]  deploying stack "eksctl-prod-cluster"
    [ℹ]  building nodegroup stack "eksctl-prod-nodegroup-ng-1"
    [ℹ]  --nodes-min=2 was set automatically for nodegroup ng-1
    [ℹ]  --nodes-max=2 was set automatically for nodegroup ng-1
    [ℹ]  deploying stack "eksctl-prod-nodegroup-ng-1"
    [✔]  all EKS cluster resources for "prod" have been created
    [✔]  saved kubeconfig as "/Users/garpunee/.kube/config"
    [ℹ]  adding identity "arn:aws:iam::444444444444:role/eksctl-prod-nodegroup-ng-1-NodeInstanceRole-H37FWX4H84GH" to auth ConfigMap
    [ℹ]  nodegroup "ng-1" has 0 node(s)
    [ℹ]  waiting for at least 2 node(s) to become ready in "ng-1"
    [ℹ]  nodegroup "ng-1" has 2 node(s)
    [ℹ]  node "ip-192-168-254-139.ec2.internal" is ready
    [ℹ]  node "ip-192-168-60-191.ec2.internal" is ready
    [ℹ]  kubectl command should work with "/Users/<>/.kube/config", try 'kubectl get nodes'
    [✔]  EKS cluster "prod" in "us-east-1" region is ready

**Note:** You can also create managed or unmanaged node groups within your cluster using either the [AWS Management Console](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>) or **eksctl**. For more information on **eksctl** , see [Managing nodegroups](<https://eksctl.io/usage/managing-nodegroups/#managing-nodegroups>) on the Weaveworks website.

* * *

## Related information

[Modifying cluster endpoint access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#modify-endpoint-access>)

[Using config files (eksctl)](<https://eksctl.io/usage/creating-and-managing-clusters/#using-config-files>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
