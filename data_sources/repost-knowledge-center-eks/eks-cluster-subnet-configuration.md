Original URL: <https://repost.aws/knowledge-center/eks-cluster-subnet-configuration>

# How do I configure my subnets for an Amazon EKS cluster?

I want to configure my subnets to work with my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

Choose one of the following configuration options:

  * To get outbound and inbound internet access from your worker nodes, complete the steps in the **Configure a public subnet** section.
  * To get only outbound internet access from your worker nodes, complete the steps in the **Configure a private subnet with outbound internet access** section.
  * To restrict both outbound and inbound internet access from your worker nodes, complete the steps in the **Configure a private subnet with no internet access** section. For example, you choose this resolution for a private Amazon EKS cluster.



## Resolution

### Configure a public subnet

When you create a subnet for your Amazon EKS cluster, consider the following:

1\. [Associate your subnet with a route table](<https://docs.aws.amazon.com/vpc/latest/userguide/WorkWithRouteTables.html#AssociateSubnet>) that's configured to route traffic to the **0.0.0.0/0** destination through an internet gateway. For example: **igw-xxxxxxxx**

2\. Activate the [auto-assign public IPV4 address](<https://docs.aws.amazon.com/vpc/latest/userguide/working-with-subnets.html#subnet-public-ip>) attribute for your subnet.

3\. Complete the steps in the **Restrict deployment of load balancers with subnet tagging** section.

### Configure a private subnet with outbound internet access

When you create a subnet for your Amazon EKS cluster, consider the following:

1\. [Associate your subnet with a route table](<https://docs.aws.amazon.com/vpc/latest/userguide/WorkWithRouteTables.html#AssociateSubnet>) that's configured to route traffic to a NAT gateway to allow only outbound connectivity to the internet.

2\. Verify that the [auto-assign public IPv4 address](<https://docs.aws.amazon.com/vpc/latest/userguide/working-with-subnets.html#subnet-public-ip>) for your subnet isn't activated.

3\. Complete the steps in the **Restrict deployment of load balancers with subnet tagging** section.

### Configure a private subnet with no internet access

1\. Verify that your subnet isn't associated with a route table that's configured to route traffic to either a NAT gateway or internet gateway. This makes sure that internet access is blocked from your worker nodes.

2\. Verify that the [auto-assign public IPv4 address](<https://docs.aws.amazon.com/vpc/latest/userguide/working-with-subnets.html#subnet-public-ip>) isn't activated.

3\. [Create Amazon Virtual Private Cloud (Amazon VPC) endpoints](<https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html#create-interface-endpoint>) for your VPC. The following VPC endpoints are required for your worker nodes to join your Amazon EKS cluster:
    
    
    com.amazonaws.your_region.ec2
    com.amazonaws.your_region.ecr.api
    com.amazonaws.your_region.ecr.dkr
    com.amazonaws.your_region.s3

**Note:** Replace **your_region** with your AWS Region.

4\. (If required) Create additional VPC endpoints based on your application requirements. See the following examples.

For Amazon CloudWatch Logs:
    
    
    com.amazonaws.your_region.logs

For a Kubernetes Cluster Autoscaler or AWS Identity and Access Management (IAM) roles for service accounts:
    
    
    com.amazonaws.your_region.sts

For an Application Load Balancer:
    
    
    com.amazonaws.your_region.elasticloadbalancing

For a Kubernetes Cluster Autoscaler:
    
    
    com.amazonaws.your_region.autoscaling

For AWS App Mesh:
    
    
    com.amazonaws.your_region.appmesh-envoy-management

For AWS X-Ray:
    
    
    com.amazonaws.your_region.xray

**Note:** Replace **your_region** with your AWS Region.

5\. Complete the steps in the **Restrict deployment of load balancers with subnet tagging** section.

### Restrict deployment of load balancers with subnet tagging

Subnet tagging tells the [AWS Load Balancer Controller](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>) what subnet can be used to create the external or internal load balancer.

**For public subnets:**

To restrict the deployment of external load balancers using the AWS Load Balancer Controller on a specific public subnet on your VPC, tag that subnet as follows:
    
    
    Key - kubernetes.io/role/elb
    Value - 1

**For private subnets:**

To restrict the deployment of internal load balancers using the AWS Load Balancer Controller on a specific private subnet, tag that subnet as follows:
    
    
    Key - kubernetes.io/role/internal-elb
    Value - 1

**Note:** You can deploy nodes and Kubernetes resources to the same subnets that you specify when you create your cluster. You can also deploy nodes and Kubernetes resources to subnets that you didn't specify when you created the cluster. Any subnet that you deploy nodes and Kubernetes resources to must meet the relevant requirements. For detailed information, see [Subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-subnets>).

* * *

## Related information

[Amazon EKS VPC and subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html>)

[AWS PrivateLink concepts](<https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html>)

[Private cluster requirements](<https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html>)

[Application load balancing on Amazon EKS](<https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
