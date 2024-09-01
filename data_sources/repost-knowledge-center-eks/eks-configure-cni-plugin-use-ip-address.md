Original URL: <https://repost.aws/knowledge-center/eks-configure-cni-plugin-use-ip-address>

# How do I configure the Amazon VPC CNI plugin to use an IP address in VPC subnets with Amazon EKS?

I want to configure the Amazon Virtual Private Cloud (VPC) Container Network Interface (CNI) plugin to use an IP address control number in VPC subnets with Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

One of the primary components of the Amazon VPC CNI is the L-IPAM daemon that allocates IP addresses to nodes.

If a new pod is scheduled on a node, then the Container Runtime invokes the CNI binary. The CNI binary calls the L-IPAMD to get an IP address for the new pod. Then, the pod tracks the elastic network interfaces and IP addresses that are attached to the instance.

You can use certain configuration variables to control how many network interfaces and IP addresses are maintained. For more information, see [WARM_ENI_TARGET, WARM_IP_TARGET and MINIMUM_IP_TARGET](<https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/eni-and-ip-target.md>) and [WARM_PREFIX_TARGET, WARM_IP_TARGET and MINIMUM_IP_TARGET](<https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/prefix-and-ip-target.md>) on the GitHub website.

## Resolution

The following are best practices for each of the configuration variables that control the maintenance of network interfaces and IP addresses.

### WARM_ENI_TARGET

Use the **WARM_ENI_TARGET** variable to determine how many elastic network interfaces the L-IPAMD keeps available. This is so that pods are immediately assigned an IP address when scheduled on a node.

The following are best practices for **WARM_ENI_TARGET** : 

  * Check the worker node instance type and the maximum number of network interfaces and private IPv4 addresses per interface. This prevents the depletion of the available subnet IP addresses.
  * If you expect your application to scale greatly, then use **WARM_ENI_TARGET** to quickly accommodate newly scheduled pods.



### WARM_IP_TARGET

Use the **WARM_IP_TARGET** variable to make sure that you always have a defined number of available IP addresses in the L-IPAMD's warm pool.

The following are best practices for **WARM_IP_TARGET** : 

  * For clusters with low productivity, use **WARM_IP_TARGET**. This means that only the required number of IP addresses are assigned to the network interface.
  * Don't use this setting for large clusters, or if the cluster has high pod churn. This setting can cause additional calls to the Amazon Elastic Compute Cloud (Amazon EC2) API and can throttle requests. It's a best practice to set a **MINIMUM_IP_TARGET** when you use **WARM_IP_TARGET**.
  * When a **MINIMUM_IP_TARGET** is set, it's a best practice for **WARM_IP_TARGET** to be greater than 0.



### MINIMUM_IP_TARGET

Use the **MINIMUM_IP_TARGET** to make sure that a minimum number of IP addresses are assigned to a node when it's created. This variable is generally used with the **WARM_IP_TARGET** variable.

The following are best practices for **MINIMUM_IP_TARGET** : 

  * If you know the minimum number of pods that you want to run per node, then use **MINIMUM_IP_TARGET**. This makes sure that the required number of IP addresses are assigned.
  * Set this variable with **WARM_IP_TARGET** to make sure that there are available IP addresses on the node for future pods.



### WARM_PREFIX_TARGET

Use the **WARM_PREFIX_TARGET** variable to make sure that you always have a defined number of prefixes (/28 CIDR blocks) added to the instance's network interface. You can use **WARM_PREFIX_TARGET** only for CNI version 1.9.0 or later, and you must activate the [Amazon VPC CNI IP address prefix assignment capability](<https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html>).

The following are best practices for **WARM_PREFIX_TARGET** : 

  * If you use the IP address prefix assignment, then make sure that the **WARM_PREFIX_TARGET** variable is set to a value greater than or equal to **1**. If it's set to **0** , then you receive the following error:

"Error: Setting WARM_PREFIX_TARGET = 0 is not supported while WARM_IP_TARGET/MINIMUM_IP_TARGET is not set. Please configure either one of the WARM_{PREFIX/IP}_TARGET or MINIMUM_IP_TARGET env variables."

  * For smaller subnets, use **WARM_IP_TARGET** with **WARM_PREFIX_TARGET**. This avoids the allocation of too many prefixes that can deplete available IP addresses.




To learn more about how these configuration variables affect IP address utilization, see [CNI configuration variables](<https://github.com/aws/amazon-vpc-cni-k8s#cni-configuration-variables>) on the GitHub website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
