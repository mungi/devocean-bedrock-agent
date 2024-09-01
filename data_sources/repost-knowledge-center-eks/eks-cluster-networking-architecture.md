Original URL: <https://repost.aws/knowledge-center/eks-cluster-networking-architecture>

# FAQs: Cluster networking architecture in Amazon EKS

I have some questions about the cluster networking architecture in Amazon Elastic Kubernetes Service (Amazon EKS).

**Q:** What are the cluster endpoint networking modes that are available in Amazon EKS?

Amazon EKS offers three networking modes that include public endpoint only, public and private endpoints, and private endpoint only. The endpoint setting that you configure determines how your nodes connect to the Kubernetes control plane. For more information, see [De-mystifying cluster networking for Amazon EKS worker nodes](<https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/>).

**Q:** How do my Amazon EKS nodes connect to the control plane in public only endpoint mode?

When you turn on public only endpoint mode for your cluster, your nodes must have one of the following routes to connect to the Kubernetes control plane:

  * A public IP route through an internet gateway
  * A private IP route through a NAT gateway



**Q:** How do the CIDR restrictions that I add to my cluster control access to a public endpoint?

The CIDR restrictions limit the client IP addresses that can connect to a public endpoint. For more information, see [Modifying cluster endpoint access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#modify-endpoint-access>).

**Q:** What happens when I turn on both public and private endpoints for my cluster?

Turning on public and private endpoints allows Kubernetes API requests from the cluster's virtual private cloud (VPC) to communicate with the control plane through managed elastic network interfaces. Your cluster's API server is then accessible from the internet.

**Q:** Do I need to deploy my Amazon EKS worker nodes in the same subnets that I specified when I created my cluster?

No. You can deploy your worker nodes in other subnets within the same Amazon Virtual Private Cloud (Amazon VPC) of your cluster.

**Q:** Can I customize the managed elastic network interfaces for my Amazon EKS cluster?

Yes. However, it's not a best practice. Amazon EKS manages the customization of managed elastic network interfaces. When you customize the managed elastic network interfaces for your cluster, you might affect cluster availability.

**Q:** What do I do if my Amazon EKS worker nodes can't connect to the Kubernetes control plane through managed elastic network interfaces?

If your worker nodes experience connectivity issues, then take the following actions:

  * Make sure that managed elastic networking interfaces are in your cluster's VPC.
  * Make sure that your cluster's security group or network access control list (network ACL) allows inbound traffic from nodes on port 443.



**Q:** How soon can I use the new CIDR block that I added to my cluster's VPC?

You can use the new CIDR block immediately after you add it. However, because the control plane recognizes the new CIDR block only after the reconciliation is complete, run the **kubectl exec** and **kubectl logs** commands only afterward. Reconciliation takes approximately 5 hours. Also, if you have Pods that operate as a webhook backend, then you must wait for the control plane reconciliation to complete. For more information, see [VPC requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-vpc>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
