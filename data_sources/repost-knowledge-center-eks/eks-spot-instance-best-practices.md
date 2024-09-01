Original URL: <https://repost.aws/knowledge-center/eks-spot-instance-best-practices>

# What are some best practices for using EC2 Spot Instances with Amazon EKS?

I want to use Amazon Elastic Compute Cloud (Amazon EC2) Spot Instances with my Amazon Elastic Kubernetes Service (Amazon EKS). What are some best practices?

## Short description

The following are some best practices for using Amazon EC2 Spot Instances with Amazon EKS:

  * Don't use Spot Instances for long-running jobs or stateful applications.
  * Use managed node groups with Spot Instances.
  * Add multiple instance types to node groups.
  * Use the AWS Node Termination Handler (NTH) for self-managed node groups.



## Resolution

### Don't use Spot Instances for long-running jobs or stateful applications

The short lifespan of a Spot Instance can cause unwanted terminations to long-running jobs. It can also affect stateful applications because stateful applications can't tolerate shutdowns. Instead, use On-Demand Instances for long-running jobs.

### Use managed node groups with Spot Instances

You can set the capacity type of a managed node group as [spot](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-capacity-types-spot>). The managed node group then configures an Auto Scaling group to use [EC2 Auto Scaling Capacity Rebalancing](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html#capacity-rebalancing-how-it-works>). When EC2 Auto Scaling Capacity Rebalancing is activated and a Spot node receives a rebalance recommendation, Amazon EKS tries to replace the Spot node.

After the new Spot node is ready, Amazon EKS separates and drains the previous Spot node. This can help reduce the risk of corrupted Amazon Elastic Block Store (Amazon EBS) volumes or interrupted database connections.

### Add multiple instance types to node groups

Every Spot Instance pool consists of an unused EC2 instance capacity for a specific instance type in a specific Availability Zone. When a node group tries to provision a new node, the node group uses one of the instance types that's defined in its configuration. If the instance type doesn't have Spot capacity in any Availability Zone, then the node group fails to scale and becomes degraded.

To avoid this issue, increase the number of similar instance types in the node group.

For example, you have an m5.large (2 vCPU/8 GiB RAM) instance type. Add instances with the same vCPU and RAM values, such as m5a.large, m5n.large, and m4.large.

### Use AWS the NTH for self-managed node groups

The [AWS Node Termination Handler](<https://github.com/aws/aws-node-termination-handler#aws-node-termination-handler>) (NTH), from the GitHub website, is deployed to an Amazon EKS cluster as a deployment or DaemonSet. The NTH adds capabilities to self-managed node groups that they lack. The handler detects and appropriately responds to Amazon EC2 maintenance events, Spot interruption notices, Auto Scaling group scale-in events, and Availability Zone rebalances. Use the **Queue Processor** option to add every NTH feature to the self-managed node group.

### Use Karpenter to manage Spot Instances

Karpenter is an open-source cluster autoscaler that automatically provisions new nodes in response to unschedulable pods. Karpenter also has features to scale in and consolidate nodes to reduce waste and cost. It uses the [capacity-optimized-prioritized allocation strategy](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-fleet-allocation-strategy.html>) to provision EC2 instances.

Karpenter uses all the EC2 instance types that are available in an Amazon EKS cluster's AWS Regions and Availability Zones to optimize Spot Instances. You can use Karpenter with the EC2 Instance Selector tool to generate a list of instance types that match specific compute requirements. By using a diverse set of instance types, you can reduce the risk of insufficient capacity errors. It's also a best practice to spread instances across different Availability Zones to use different Spot pools.

For more information about Karpenter best practices and limitations, see [Karpenter best practices](<https://aws.github.io/aws-eks-best-practices/karpenter/#karpenter-best-practices_1>) on GitHub.

**Important:** Karpenter currently lacks the ability to handle the two-minute warning for the Spot Interruption Termination Notice (ITN). To address this, you can install the NTH to gracefully cordon and drain spot nodes when they're interrupted.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
