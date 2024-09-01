Original URL: <https://repost.aws/knowledge-center/eks-load-balancers-troubleshooting>

# How do I troubleshoot load balancers created by the Kubernetes service controller in Amazon EKS?

I can't create a Kubernetes service that's backed by a load balancer on Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

Amazon EKS uses one of two controllers to manage a load balancer: AWS Load Balancer Controller or the Kubernetes service controller. The following troubleshooting steps apply only to load balancers that are managed by the Kubernetes service controller. For more information, see [The Service Controller](<https://cloud-provider-aws.sigs.k8s.io/service_controller/>) on the Kubenetes AWS Cloud Provider website and [Type LoadBalancer](<https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer>) on the Kubernetes website.

To troubleshoot your service load balancer, verify that you have the following configurations:

  * The correct tags for your Amazon Virtual Private Cloud (Amazon VPC) subnets
  * The required AWS Identity and Access Management (IAM) permissions for your cluster's IAM role
  * A valid Kubernetes service definition
  * Load balancers that stay within your account limit
  * Enough free IP addresses on your subnets
  * A correctly configured load balancer to avoid connection timeout issues
  * Healthy load balancer targets



If you still have an issue after verifying all the preceding items, then follow the steps in the **Try additional troubleshooting steps** section.

## Resolution

The following steps apply to the Classic Load Balancer and the Network Load Balancer. For the Application Load Balancer, see [Application load balancing on Amazon EKS](<https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html>).

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### Use the correct tags for your Amazon VPC subnets

1\. Open the [Amazon VPC console](<https://console.aws.amazon.com/vpc/>).

2\. On the navigation pane, choose **Subnets**.

3\. Choose the **Tags** tab for each subnet, and then confirm that a tag exists. For example:
    
    
    Key: kubernetes.io/cluster/yourEKSClusterName  
    Value: shared

**Note:** In this case, the **Value** can be **shared** or **owned**.

By default, the controller automatically discovers the subnets. If there are multiple subnets per Availability Zone, then the controller prioritizes subnets in the following order:

  * Subnets with the correct role tag: **kubernetes.io/role/elb** for public subnets and **kubernetes.io/role/internal-elb** for private subnets
  * Subnets with the cluster tag: **kubernetes.io/cluster/CLUSTER_NAME**
  * The subnet that’s first in lexicographic order



4\. For your public subnets, confirm that the following tag exists:
    
    
    Key: kubernetes.io/role/elb  
    Value: 1

**Note:** To see if a subnet is public, check the route table that's associated with the subnet. A public subnet has a route to an internet gateway (**igw-xxxxxxxxxxx**). A private subnet has a route to the internet through a NAT gateway or NAT instance, or no route to the internet at all.

**Important:** You must have the tag in **step 4** to create an internet-facing load balancer service. An internet-facing load balancer routes requests from clients to targets over the internet.

5\. For your private subnets, confirm that the following tag exists:
    
    
    Key: kubernetes.io/role/internal-elb  
    Value: 1

**Important:** You must have the tag in **step 5** to create an internal load balancer service. An internal load balancer uses private IP addresses to route requests to targets.

### Set the required AWS Identity and Access Management (IAM) permissions for your cluster's IAM role

1\. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>).

2\. On the navigation pane, choose **Clusters**.

3\. Select your cluster, and then note your **Cluster IAM Role ARN**.

4\. Open the [IAM console](<https://console.aws.amazon.com/iam/>).

5\. On the navigation pane, choose **Roles**.

6\. Select the role that matches the **Cluster IAM Role ARN** that you identified in **step 3**.

7\. Confirm that the AWS managed policy **AmazonEKSClusterPolicy** is attached to your role.

**Note:** The Amazon EKS control plane assumes the preceding IAM role to create a load balancer for your service.

### Use a valid Kubernetes service definition

In the YAML file for your Kubernetes service, verify that **spec.type** is set to **LoadBalancer**.

See the following example of a Kubernetes service that's backed by a load balancer:
    
    
    apiVersion: v1  
    kind: Service  
    metadata:  
      annotations:  
        # This annotation is only required if you are creating an internal facing ELB. Remove this annotation to create public facing ELB.  
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"  
      name: nginx-elb  
      labels:  
        app: nginx  
    spec:  
      type: LoadBalancer  
      ports:  
      - name: "http"  
        port: 80  
        targetPort: 80  
      selector:  
        app: nginx

**Note:** To customize your service with a different annotation, see [Internal load balancer](<https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer>) and [TLS support on AWS](<https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws>) on the Kubernetes website.

By default, Kubernetes built-in service controller creates a Classic Load Balancer. For Network Load Balancer provision, the service must have the annotation **service.beta.kubernetes.io/aws-load-balancer-type: "nlb"**. For more details, see [Network Load Balancer support on AWS](<https://kubernetes.io/docs/concepts/services-networking/service/#aws-nlb-support>) on the Kubernetes website.

### Verify that your load balancers are within your account limit

By default, an AWS account has a maximum of 20 load balancers per AWS Region.

To check how many load balancers that you have, open the [Amazon Elastic Compute Cloud (Amazon EC2) console](<https://console.aws.amazon.com/ec2/>). Then, choose **Load Balancers** from the navigation pane.

If you reach the maximum number of load balancers, then you can apply for an increase with [Service Quotas](<https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html>).

### Verify that there are enough free IP addresses on your subnets

To create a load balancer, each subnet of that load balancer must have a minimum of eight free IP addresses. This is required for both the Classic Load Balancer and Network Load Balancer.

### Connection timeout issues

If your load balancer is experiencing intermittent or constant timeout issues, then there might be an issue with the load balancer configuration. This can happen when the backend service can’t handle the incoming traffic, or too many requests are sent to the load balancer. For more information, see [How do I troubleshoot Elastic Load Balancing "Connection timed out" errors?](<https://repost.aws/knowledge-center/elb-troubleshoot-connection-errors>)

### Verify load balancer health checks

If you don't correctly configure the endpoint, or the backend service isn't responding to health check requests, then Load balancer health check issues occur.

To verify that the load balancer is pointing to the correct endpoint, run the AWS CLI command [describe-target-health](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/describe-target-health.html>):
    
    
    aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/my-targets/6d0ecf831eec9f09

To check the health check configuration of the target group, run the AWS CLI command [describe-target-groups](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/describe-target-groups.html>):
    
    
    aws elbv2 describe-target-groups --target-group-arns arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/my-targets/6d0ecf831eec9f09

For more information, see [Health checks for your target groups](<https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html>).

### Try additional troubleshooting steps

To check the Kubernetes service for an error message that can help you troubleshoot the issue, run the following [describe-service](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/apprunner/describe-service.html>) command:
    
    
    $ kubectl describe service my-elb-service

If the service is created successfully, then you receive an output that's similar to the following example:
    
    
    ...  
    ...  
    Events:  
      Type    Reason                Age   From                Message  
      ----    ------                ----  ----                -------  
      Normal  EnsuringLoadBalancer  47s   service-controller  Ensuring load balancer  
      Normal  EnsuredLoadBalancer   44s   service-controller  Ensured load balancer

If the service isn't created successfully, then you receive an error message.

To get more information about error messages, check the following resources:

  * Use the [Amazon EKS control plane logs](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>).
  * Find out more about the [Kubernetes LoadBalancer service](<https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer>) on the Kubernetes website.
  * Review the [AWS cloud provider](<https://github.com/kubernetes/cloud-provider-aws>) on the Kubernetes GitHub website.



## Related information

[Why does a subnet in use by load balancers in my VPC have insufficient IP addresses?](<https://repost.aws/knowledge-center/subnet-insufficient-ips>)

[Amazon EKS troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>)

[Troubleshoot your Application Load Balancers](<https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html>)

[Troubleshoot your Classic Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-troubleshooting.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
