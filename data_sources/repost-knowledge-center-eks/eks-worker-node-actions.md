Original URL: <https://repost.aws/knowledge-center/eks-worker-node-actions>

# How do I check, scale, delete, or drain my worker nodes in Amazon EKS?

I used eksctl or the AWS Management Console to launch my Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes. Now I want to check, scale, drain, or delete my worker nodes.

## Resolution

### Check your worker nodes

To list the worker nodes that are registered to the Amazon EKS control plane, run the following command:
    
    
    kubectl get nodes -o wide

The output returns the name, Kubernetes version, operating system (OS), and IP address of the worker nodes.

To get additional information on a single worker node, run the following command:
    
    
    kubectl describe node/node_name

**Note:** Replace **node_name** with your value, for example: **ip-XX-XX-XX-XX.us-east-1.compute.internal**.

The output shows more information about the worker node, including labels, taints, system information, and status.

### Scale your worker nodes

**Note:** If your [node groups](<https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html>) appear in the Amazon EKS console, then use a managed node group. Otherwise, use an unmanaged node group.

Use one of the following methods to scale your worker nodes.

**Scale worker notes with eksctl**

To use **eksctl** to scale your managed or unmanaged worker nodes, run the following command:
    
    
    eksctl scale nodegroup --cluster=clusterName --nodes=desiredCount --name=nodegroupName

**Note:** Replace **clusterName** , **desiredCount** , and **nodegroupName** with your values.

**Scale worker nodes without eksctl**

To scale your managed worker nodes without **eksctl** , [edit the node group configuration](<https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html#mng-edit>).

**Scale worker nodes with CloudFormation**

To use AWS CloudFormation to scale your unmanaged worker nodes, complete the following steps:

  1. Use a CloudFormation template to launch your worker nodes for [Windows](<https://docs.aws.amazon.com/eks/latest/userguide/launch-windows-workers.html#w243aac15c37c11b3>) or [Linux](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html#w243aac15c35c11b5>).
  2. Modify the **NodeAutoScalingGroupDesiredCapacity** , **NodeAutoScalingGroupMinSize** , or **NodeAutoScalingGroupMaxSize** parameters in your CloudFormation stack.



### Drain your worker nodes

**Important:** The drain action isolates the worker node, and Kubernetes no longer schedules any new pods on the node. Pods that run on the target node are removed from draining nodes and are stopped.

You can drain either an entire node group or a single worker node.

**Drain the entire node group**

If you use **eksctl** to launch your worker nodes, then run the following command:
    
    
    eksctl drain nodegroup --cluster=clusterName --name=nodegroupName

**Note:** Replace **clusterName** and **nodegroupName** with your values.

To drain the node group, run the following command:
    
    
    eksctl drain nodegroup --cluster=clusterName --name=nodegroupName --undo

**Note:** Replace **clusterName** and **nodegroupName** with your values.

If you don't use **eksctl** to launch your worker nodes, then identify and drain all the nodes of a particular Kubernetes version. For example:
    
    
    #!/bin/bashK8S_VERSION=1.18.8-eks-7c9bda
    nodes=$(kubectl get nodes -o jsonpath="{.items[?(@.status.nodeInfo.kubeletVersion==\"v$K8S_VERSION\")].metadata.name}")
    for node in ${nodes[@]}
    do
        echo "Draining $node"
        kubectl drain $node --ignore-daemonsets --delete-local-data
    done

To identify and drain all the nodes of a particular Kubernetes version, use the following code:
    
    
    #!/bin/bashK8S_VERSION=1.18.8-eks-7c9bda
    nodes=$(kubectl get nodes -o jsonpath="{.items[?(@.status.nodeInfo.kubeletVersion==\"v$K8S_VERSION\")].metadata.name}")
    for node in ${nodes[@]}
    do
        echo "Uncordon $node"
        kubectl uncordon $node
    done

**Note:** To get the version of your worker node, run the following command. The version number appears in the **VERSION** column:
    
    
    $ kubectl get nodesNAME                                      STATUS   ROLES    AGE     VERSION
    ip-XXX-XXX-XX-XXX.ec2.internal            Ready    <none>   6d4h    v1.18.8-eks-7c9bda
    ip-XXX-XXX-XX-XXX.ec2.internal            Ready    <none>   6d4h    v1.18.8-eks-7c9bda

**Drain a single worker node**

If you don't use **eksctl** to launch your worker nodes or you want to drain only a specific node, then gracefully isolate your worker node:
    
    
    kubectl drain node_name --ignore-daemonsets

**Note:** Replace **node_name** with your value.

To undo the isolation, run the following command:
    
    
    kubectl uncordon node_name

**Note:** Replace **node_name** with your value.

To migrate your existing applications to a new worker node group, see [Migrating to a new node group](<https://docs.aws.amazon.com/eks/latest/userguide/migrate-stack.html>).

### Delete your worker nodes

**Important:** The delete action is unrecoverable.

If you use **eksctl** , then run the following command:
    
    
    eksctl delete nodegroup --cluster=clusterName --name=nodegroupName

If you have a managed node group, then complete the steps in [Deleting a managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/delete-managed-node-group.html>).

If you have an unmanaged node group and you used a CloudFormation template to launch your worker nodes, then delete the stack. You must delete the stack that you created for your node group for Windows or Linux.

If you have an unmanaged node group and didn't use a CloudFormation template to launch your worker nodes, then [delete the Auto Scaling group](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html#as-shutdown-lbs-delete-asg-cli>). If you didn't use an Auto Scaling group, then [terminate the instance](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#terminating-instances-console>) directly.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
