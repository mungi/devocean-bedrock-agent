Original URL: <https://repost.aws/knowledge-center/eks-connect-other-services>

# Why am I unable to connect from Amazon EKS to other AWS services?

I want to troubleshoot errors when I'm trying to connect from Amazon Elastic Kubernetes Service (Amazon EKS) to other services.

## Short description

If your pods can't connect to other services, you might receive one or more of the following errors:

  * RequestError: send request failed\\\ncaused by: Post \\\\\"https://ec2.us-west-2.amazonaws.com/\\\\\": dial tcp <IP address>: i/o timeout\"\
  * Couldn't connect to host, port: imap.mail.<region>.awsapps.com,<port>; timeout -1
  * java.net .SocketTimeoutException: connect timed out
  * Connection could not be created to jdbc:postgresql://<hostname>.<region>.rds.amazonaws.com:5432/
  * <URL>.<region>.rds.amazonaws.com (<IPaddress>:3306): Operation timed out
  * Error : java.sql.SQLNonTransientConnectionException: Could not connect to address=(host=<hostname>.<region>.rds.amazonaws.com)(port=3306)(type=master) : Socket fail to connect to host:<hostname>.<region>.rds.amazonaws.com , port:3306. connect timed out***
  * o.apache.kafka.clients.NetworkClient -[Producer clientId=producer-1] Connection to node -1 (<hostname>.c3.kafka.<region>.amazonaws.com/<IPaddress>:9092) could not be established. Broker may not be available.



You get these errors because of network connection problems that might be caused by an incorrect Amazon Virtual Private Cloud (Amazon VPC) configuration. To resolve these issues, check the security groups and network access control lists (ACLs) that are associated with the following:

  * Worker node instances
  * Services that the pods are trying to connect to



## Resolution

You get connection timeout errors typically when the security group rules or network ACLs explicitly deny the required permissions.

To resolve these errors, check that your environment is set up correctly by confirming the following:

  * Your security groups meet the Amazon EKS requirements.
  * Your security groups for pods allow pods to communicate with each other.
  * The network ACL doesn't deny the connection.
  * Your subnet has a local route for communicating within your Amazon VPC.
  * Your pods are scheduled and in the RUNNING state.
  * You have the latest available version of the Amazon VPC Container Network Interface (CNI) plugin for Kubernetes.
  * Your cluster's VPC subnets have a VPC interface endpoint for AWS services that your pods need to access.



### Your security groups meet the Amazon EKS requirements

Be sure that the inbound and outbound rules allow traffic on protocols and ports that your worker nodes use for communicating with other services. It's a best practice to allow all traffic to flow between your cluster and nodes and allow all outbound traffic to any destination. You don't need to change security group rules every time a new pod with a new port is created. For more information, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

### Your security groups for pods allow pods to communicate with each other

If you use [security groups for pods](<https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html>) or [custom networking](<https://docs.aws.amazon.com/eks/latest/userguide/cni-custom-network.html>), then you can attach any security group to your pods. In this case, confirm that the security groups allow communication between the pods.

### The network ACL doesn't deny the connection

  * Confirm that the traffic between your Amazon EKS cluster and VPC CIDR flows freely on your [network ACL](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html>).
  * Consider setting up network ACLs with rules that are similar to those in your security groups.



### Your subnet has a local route for communicating within your VPC

Confirm that your subnets have the default route for communication within your VPC. For more information, see [Amazon EKS VPC and subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html>).

### Your pods are scheduled and in the RUNNING state

Confirm that your pods are scheduled and in the RUNNING state. To troubleshoot your pod status, see [How can I troubleshoot pod status in Amazon EKS?](<https://repost.aws/knowledge-center/eks-pod-status-troubleshooting>)

### You have the latest available version of the Amazon VPC CNI plugin for Kubernetes

If you're not running the latest available version of the Amazon VPC CNI plugin for Kubernetes, then consider [updating to the latest version](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#updating-vpc-cni-eks-add-on>).

If you still experience issues, then see [How do I resolve kubelet or CNI plugin issues for Amazon EKS?](<https://repost.aws/knowledge-center/eks-cni-plugin-troubleshooting>)

### Your cluster's VPC subnets must have a VPC endpoint interface for services that your pods need to access

Some commonly used services and endpoints are listed in the following table:

|   
---|---  
**Service**| **Endpoint**  
Amazon Elastic Compute Cloud (Amazon EC2)| com.amazonaws.region-code.ec2  
Amazon Elastic Container Registry (Amazon ECR)| com.amazonaws.region-code.ecr.api com.amazonaws.region-code.ecr.dkr com.amazonaws.region-code.s3  
Elastic Load Balancing (ELB)| com.amazonaws.region-code.elasticloadbalancing  
AWS X-Ray| com.amazonaws.region-code.xray  
Amazon CloudWatch| com.amazonaws.region-code.logs  
AWS Security Token Service (AWS STS) (required when you use IAM roles for service accounts)| com.amazonaws.region-code.sts  
AWS App Mesh The App Mesh controller for Kubernetes isn't supported. For more information, see [App Mesh controller](<https://github.com/aws/aws-app-mesh-controller-for-k8s>) on the GitHub website. [Cluster Autoscaler](<https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler>) is supported. When deploying Cluster Autoscaler pods, make sure that the command line includes --aws-use-static-instance-list=true. For more information, see [Use Static Instance List](<https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#use-static-instance-list>) on the GitHub website. The worker node VPC must also include the AWS STS VPC endpoint and Amazon EC2 Auto Scaling endpoint.| com.amazonaws.region-code.appmesh-envoy-management  
  
For a complete list of endpoints, see [AWS services that integrate with AWS PrivateLink](<https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html>).

Be sure that the security group for the VPC endpoint has inbound rules that allow traffic from worker nodes.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
