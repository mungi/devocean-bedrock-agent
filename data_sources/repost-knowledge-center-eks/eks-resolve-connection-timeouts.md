Original URL: <https://repost.aws/knowledge-center/eks-resolve-connection-timeouts>

# How do I resolve connection timeouts when I connect to my Service that's hosted in Amazon EKS?

I get connection timeouts when I connect to my Service that's hosted in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

The most common Service connection issues occur because the security group or network access control list (network ACL) restricts traffic from the pod endpoints.

To resolve this, check the security groups and network ACLs that are associated with your worker node instances and load balancer. If you use a Network Load Balancer, then verify that your Service has the correct labels selected for your pods.

**Note:** The following resolutions apply to inaccessible Services. To learn more about Kubernetes Service types, see [How do I expose the Kubernetes Services running on my Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-kubernetes-services-cluster>)

## Resolution

### Check your security group and network ACLs

**Cluster IP**

The cluster IP Service type is used for communication between microservices that run in the same Amazon EKS cluster. Make sure that the security group for the destination pod's instance has an inbound rule that allows the client's pod instance to communicate.

In most cases, there's a **self** rule that allows all communication over all ports in the worker node security groups. If you use multiple node groups, each with its own security group, then allow all communication between the security groups. This lets the microservices that run across the multiple nodes to communicate easily.

To learn more, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

**Node port**

The worker node security group must allow incoming traffic on the port specified in the **NodePort** Service definition. If it's not specified in the Service definition, then the value of the port parameter is the same as the **targetPort** parameter. The port is exposed on all nodes in the Amazon EKS cluster.

Check the network ACLS that are linked to the worker node subnets. Make sure that your client IP address is on the allow list over the port that the Service uses.

If you access the Kubernetes Service over the internet, then confirm that your nodes have a Public IP address. To access the Service, you must use the node's Public IP address and port combination.

**Load balancer**

Make sure the following are true:

  * The load balancer security group allows inbound listener ports.
  * The load balancer security group allows outbound traffic on the target traffic port.
  * The worker node security group allows incoming traffic from the load balancer security group over the port where the application container runs.
  * If you use a Network Load Balancer without a security group association that uses Client IP preservation, then the worker nodes allow client traffic.
  * The worker node allows traffic that matches the **targetPort** if different than port mapped at the Service.
  * The [network ACLs](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-rules>) allow your client IP address to reach the load balancer at the listener port.
  * If you access the load balancer over the internet, then you created an internet-facing load balancer.



### Confirm that your Service selected the pod endpoints correctly

If your pods aren't registered as backends for the Service, then you can receive a timeout error. This can happen when you access the Service from a browser. Or, it can happen when you run the **curl podIP:podPort** command.

Check the labels for the pods and verify that the Service has the appropriate label selectors. For more information, see [Labels and selectors](<https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/>) on the Kubernetes website.

Run the following commands to verify that your Kubernetes Service is correctly selected and registered your pods.

Command:
    
    
    kubectl get pods -o wide

Example output:
    
    
    NAME                    READY   STATUS    RESTARTS   AGE       IP                           NODE                         NOMINATED NODE   READINESS GATESnginx-6799fc88d8-2rtn8   1/1     Running     0       3h4m   172.31.33.214   ip-172-31-33-109.us-west-2.compute.internal       none          none

Command:
    
    
    kubectl describe svc your_service_name -n your_namespace

**Note:** Replace **your_service_name** with your Service name and **your_namespace** with your namespace.

Example output:
    
    
    Events:            noneSession Affinity:  none
    Endpoints:         172.31.33.214:80
    ....

In the example output, **172.31.33.214** is the pod IP address that is returned from the **kubectl get pods -o wide** command. The **172.31.33.214** IP address also serves as the backend to a Service that runs in an Amazon EKS cluster.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
