Original URL: <https://repost.aws/knowledge-center/eks-resolve-http-503-errors-kubernetes>

# How do I resolve HTTP 503 (Service unavailable) errors when I access a Kubernetes Service in an Amazon EKS cluster?

I get HTTP 503 (Service unavailable) errors when I connect to a Kubernetes Service that runs in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

HTTP 503 errors are server-side errors. They occur when you connect to a Kubernetes Service pod located in an Amazon EKS cluster that's configured for a load balancer.

To troubleshoot HTTP 504 errors, see [How do I resolve HTTP 504 errors in Amazon EKS?](<https://repost.aws/knowledge-center/eks-http-504-errors>)

To troubleshoot HTTP 503 errors, complete the following troubleshooting steps.

## Resolution

### Check if the pod label matches the value that's specified in Kubernetes Service selector

1\. Run the following command to get the value of the selector:
    
    
    $ kubectl describe service service_name -n your_namespace

**Note:** Replace **service_name** with your service name and **your_namespace** with your service namespace.

Example output:
    
    
    Name:                     service-name
    Namespace:                pod-name
    Labels:                   none
    Annotations:              none
    Selector:                 app.kubernetes.io/name=namespace
    Type:                     NodePort
    IP Families:              none
    IP:                       10.100.17.189
    IPs:                      10.100.17.189
    Port:                     unset  80/TCP
    TargetPort:               80/TCP
    NodePort:                 unset  31560/TCP
    Endpoints:                none
    Session Affinity:         none
    External Traffic Policy:  Cluster
    Events:                   none

In the preceding output, the example selector value is **app.kubernetes.io/name=namespace**.

2\. Check if there are pods with the label **app.kubernetes.io/name=namespace** :
    
    
    $ kubectl get pods -n your_namespace -l "app.kubernetes.io/name=namespace"

Example output:
    
    
    No resources found in your_namespace namespace.

If no resources are found with the value you searched for, then you get an HTTP 503 error.

### Verify that the pods defined for the Kubernetes Service are running

Use the label in the Kubernetes Service selector to verify that the pods exist and are in **Running** state:
    
    
    $ kubectl -n your_namespace get pods -l "app.kubernetes.io/name=your_namespace"

Output:
    
    
    NAME                               READY   STATUS             RESTARTS   AGE
    POD_NAME                           0/1     ImagePullBackOff   0          3m54s

### Check if the pods can pass the readiness probe for your Kubernetes deployment

1\. Verify that the application pods can pass the readiness probe. For more information, see [Configure liveness, readiness, and startup probes](<https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/>) (from the Kubernetes website).

2\. Check the readiness probe for the pod:
    
    
    $ kubectl describe pod pod_name -n your_namespace | grep -i readiness

**Note:** replace **pod_name** with your pad name and **your_namespace** with your namespace.

Example output:
    
    
    Readiness:      tcp-socket :8080 delay=5s timeout=1s period=2s #success=1 #failure=3
    Warning  Unhealthy  2m13s (x298 over 12m)  kubelet            Readiness probe failed:

In the preceding output, you can see **Readiness probe failed**.

**Note:** This step provides helpful output only if the application is listening on the right path and port. Check the curl output with the **curl -Ivk** command, and make sure the path defined at the service level is getting a valid response. For example, 200 ms is a good response.

### Check the capacity for your Classic Load Balancer

If you get an intermittent HTTP 503 error, then your Classic Load Balancer doesn't have enough capacity to handle the request. To resolve this issue, make sure that your Classic Load Balancer has enough capacity and your worker nodes can handle the request rate.

### Verify that your instances are registered

You also get an HTTP 503 error if there are no registered instances. To resolve this issue, try the following solutions:

  * Verify that the security groups for the worker node have an inbound rule that allows port access on the node port to worker nodes. Also, verify that no NAT rules are blocking network traffic on the node port ranges.
  * Verify that the custom security group that's specified for the Classic Load Balancer is allowed inbound access on the worker nodes.
  * Make sure that there are worker nodes in every Availability Zone that's specified by the subnets.



* * *

## Related information

[Why did I receive an HTTP 5xx error when connecting to web servers running on EC2 instances configured to use Classic Load Balancing?](<https://repost.aws/knowledge-center/troubleshoot-http-5xx>)

[HTTP 503: Service unavailable](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ts-elb-error-message.html#ts-elb-errorcodes-http503>)

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
