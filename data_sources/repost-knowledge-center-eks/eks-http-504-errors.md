Original URL: <https://repost.aws/knowledge-center/eks-http-504-errors>

# How do I resolve 504 HTTP errors in Amazon EKS?

I get HTTP 504 (Gateway timeout) errors when I connect to a Kubernetes Service that runs in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

You get HTTP 504 errors when you connect to a Kubernetes Service pod that's located in an Amazon EKS cluster configured for a load balancer.

To resolve HTTP 503 errors, see [How do I resolve HTTP 503 (Service unavailable) errors when I access a Kubernetes Service in an Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-resolve-http-503-errors-kubernetes>)

To resolve HTTP 504 errors, complete the following troubleshooting steps.

## Resolution

### Verify that your load balancer's idle timeout is set correctly

The load balancer established a connection to the target, but the target didn't respond before the idle timeout period elapsed. By default, the idle timeout for the [Classic Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-cloudwatch-metrics.html#ViewingDataUsingCloudWatch>) and [Application Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html#view-metric-data>) is 60 seconds.

1\. Review the Amazon CloudWatch metrics for your Classic Load Balancer or Application Load Balancer.

**Note:** At least one request has timed out when:

  * The latency data points are equal to your currently configured load balancer timeout value.
  * There are data points in the **HTTPCode_ELB_5XX metric**.



2\. Modify the idle timeout for your load balancer so that the HTTP request can complete within the idle timeout period. Or configure your application to respond quicker.

To modify the idle timeout for your Classic Load Balancer, update the service definition to include the **service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout** annotation.

To modify the idle timeout for your Application Load Balancer, update the Ingress definition to include the **alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds** annotation.

### Verify that your backend instances have no backend connection errors

If a backend instance closes a TCP connection before it's reached the idle timeout value, then the load balancer fails to fulfill the request.

1\. Review the **CloudWatch BackendConnectionErrors** metrics for your Classic Load Balancer and the target group's **TargetConnectionErrorCount** for your Application Load Balancer.

2\. [Activate keep-alive settings](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html>) on your backend worker node or pods, and set the keep-alive timeout to a value greater than the load balancer's idle timeout.

To see if the keep-alive timeout is less than the idle timeout, verify the keep-alive value in your pods or worker node. See the following example for pods and nodes.

For pods:
    
    
    $ kubectl exec your-pod-name -- sysctl net.ipv4.tcp_keepalive_time net.ipv4.tcp_keepalive_intvl net.ipv4.tcp_keepalive_probes

For nodes:
    
    
    $ sysctl net.ipv4.tcp_keepalive_time net.ipv4.tcp_keepalive_intvl net.ipv4.tcp_keepalive_probes

Output:
    
    
    net.ipv4.tcp_keepalive_time = 7200
    net.ipv4.tcp_keepalive_intvl = 75
    net.ipv4.tcp_keepalive_probes = 9

### Verify that your backend targets can receive traffic from the load balancer over the ephemeral port range

The network access control list (ACL) for the subnet doesn't allow traffic from the targets to the load balancer nodes on the [ephemeral ports](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-ephemeral-ports>) (1024-65535).

You must configure security groups and network ACLs to allow data to move between the load balancer and the backend targets. For example, depending on the load balancer type, these targets can be IP addresses or instances.

You must configure the security groups for ephemeral port access. To do so, connect the security group egress rule of your nodes and pods to the security group of your load balancer. For more information, see [Security groups for your Amazon Virtual Private Cloud (Amazon VPC)](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#WorkingWithSecurityGroups>) and [Add and delete rules](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#Rules>).

* * *

## Related information

[I receive HTTP 5xx errors when connecting to web servers running on EC2 instances configured to use Classic Load Balancing. How do I troubleshoot these errors?](<https://repost.aws/knowledge-center/troubleshoot-http-5xx>)

[HTTP 504: Gateway timeout](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ts-elb-error-message.html#ts-elb-errorcodes-http504>)

[Monitor your Classic Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-monitor-logs.html>)

[Monitor your Application Load Balancers](<https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-monitoring.html>)

[Troubleshoot a Classic Load Balancer: HTTP errors](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ts-elb-error-message.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
