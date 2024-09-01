Original URL: <https://repost.aws/knowledge-center/eks-resolve-failed-health-check-alb-nlb>

# How do I resolve a failed health check for a load balancer in Amazon EKS?

My load balancer fails the health check in my Amazon Elastic Kubernetes Service (Amazon EKS).

## Resolution

To troubleshoot health check issues with the load balancer in Amazon EKS, complete the steps in the following sections.

### Check the status of the pod

Check if the pod is in **Running** status and the containers in the pods are ready:
    
    
    $ kubectl get pod -n YOUR_NAMESPACE

**Note:** Replace **YOUR_NAMESPACE** with your Kubernetes namespace.

Example output:
    
    
    NAME                           READY   STATUS    RESTARTS   AGEpodname                        1/1     Running   0          16s

If the application container in the pod's status isn't **Running** , then the load balancer health check isn't answered and fails.

### Check the pod and service label selectors

For pod labels, run the following command:
    
    
    $ kubectl get pod -n YOUR_NAMESPACE --show-labels

Example output:
    
    
    NAME                           READY   STATUS    RESTARTS   AGE     LABELSalb-instance-6cc5cd9b9-prnxw   1/1     Running   0          2d19h   app=alb-instance,pod-template-hash=6cc5cd9b9

To verify that your Kubernetes Service uses the pod labels, run the following command to check that the output matches the pod labels:
    
    
    $ kubectl get svc SERVICE_NAME -n YOUR_NAMESPACE -o=jsonpath='{.spec.selector}{"\n"}'

**Note:** Replace **SERVICE_NAME** with your Kubernetes Service and **YOUR_NAMESPACE** with your Kubernetes namespace.

Example output:.
    
    
    {"app":"alb-instance"}

### Check for missing endpoints

The Kubernetes controller for the service selector continuously scans for pods that match its selector, and then posts updates to an endpoint object. If you selected an incorrect label, then no endpoint appears.

Run the following command:
    
    
    $ kubectl describe svc SERVICE_NAME -n YOUR_NAMESPACE

Example output:
    
    
    Name:                     alb-instanceNamespace:                default
    Labels:                   <none>
    Annotations:              <none>
    Selector:                 app=alb-instance-1      
    Type:                     NodePort
    IP Family Policy:         SingleStack
    IP Families:              IPv4
    IP:                       10.100.44.151
    IPs:                      10.100.44.151
    Port:                     http  80/TCP
    TargetPort:               80/TCP
    NodePort:                 http  32663/TCP
    Endpoints:                <none>                 
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:                   <none>

Check if there's a missing endpoint:
    
    
    $ kubectl get endpoints SERVICE_NAME -n YOUR_NAMESPACE

Example output:
    
    
    NAME           ENDPOINTS                                AGEalb-instance   <none>                                   2d20h

### Check the service traffic policy and cluster security groups for issues with Application Load Balancers

Unhealthy targets in the Application Load Balancer target groups happen for two reasons:

  * The service traffic policy, **spec.externalTrafficPolicy** is set to **Local** instead of **Cluster**.
  * The node groups in a cluster have different cluster security groups associated with them, and traffic can't flow freely between the node groups.



Verify that the traffic policy is correctly configured:
    
    
    $ kubectl get svc SERVICE_NAME -n YOUR_NAMESPACE -o=jsonpath='{.spec.externalTrafficPolicy}{"\n"}'

Example output:
    
    
    Local

Change the setting to **Cluster** :
    
    
    $ kubectl edit svc SERVICE_NAME -n YOUR_NAMESPACE

**Check the cluster security groups**

Complete the following steps:

  1. Open the [Amazon EC2 console](<https://console.aws.amazon.com/ec2/>).
  2. Select the healthy instance.
  3. Choose the **Security** tab, and then check the security group ingress rules.
  4. Select the unhealthy instance.
  5. Choose the **Security** tab, and then check the security group ingress rules.  
If the security group for each instance is different, then you must modify the security ingress rule in the security group console:  
From the **Security** tab, select the security group ID.  
Choose **Edit inbound rules** to modify ingress rules.  
Add inbound rules to allow traffic from the other node groups in the cluster.



### Verify that your service is configured for targetPort

Your **targetPort** must match the **containerPort** in the pod that the service sends traffic to.

To verify what your **targetPort** is configured to, run the following command:
    
    
    $ kubectl get svc  SERVICE_NAME -n YOUR_NAMESPACE -o=jsonpath="{.items[*]}{.metadata.name}{'\t'}{.spec.ports[].targetPort}{'\t'}{.spec.ports[].protocol}{'\n'}"

Example output:
    
    
    alb-instance    8080    TCP

In the example output, the **targetPort** is configured to 8080. However, because the **containerPort** is set to 80, you must configure the **targetPort** to 80.

### Verify that your AWS Load Balancer Controller has the correct permissions

The AWS Load Balancer Controller must have the correct permissions to update security groups to allow traffic from the load balancer to instances or pods. If the controller doesn't have the correct permissions, then you receive errors.

Check for errors in the AWS Load Balancer Controller deployment logs:
    
    
    $ kubectl logs deploy/aws-load-balancer-controller -n kube-system

Check for errors in the individual controller pod logs:
    
    
    $ kubectl logs CONTROLLER_POD_NAME -n YOUR_NAMESPACE

**Note:** Replace **CONTROLLER_POD_NAME** with your controller pod name and **YOUR_NAMESPACE** with your Kubernetes namespace.

### Check the ingress annotations for issues with Application Load Balancers

For issues with the Application Load Balancer, check the Kubernetes ingress annotations:
    
    
    $ kubectl describe ing INGRESS_NAME -n YOUR_NAMESPACE

**Note:** Replace **INGRESS_NAME** with the name of your Kubernetes Ingress and **YOUR_NAMESPACE** with your Kubernetes namespace.

Example output:
    
    
    Name:             alb-instance-ingressNamespace:        default
    Address:          k8s-default-albinsta-fcb010af73-2014729787.ap-southeast-2.elb.amazonaws.com
    Default backend:  alb-instance:80 (192.168.81.137:8080)
    Rules:
      Host          Path  Backends
      ----          ----  --------
      awssite.cyou
                    /   alb-instance:80 (192.168.81.137:8080)
    Annotations:    alb.ingress.kubernetes.io/scheme: internet-facing        
                    kubernetes.io/ingress.class: alb                         
    Events:
      Type    Reason                  Age                  From     Message
      ----    ------                  ----                 ----     -------
      Normal  SuccessfullyReconciled  25m (x7 over 2d21h)  ingress  Successfully reconciled

To find ingress annotations that are specific to your use case, see [Ingress annotations](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/>) on the Kubernetes website.

### Check the Kubernetes Service annotations for issues with Network Load Balancers

For issues with the Network Load Balancer, check the Kubernetes Service annotations:
    
    
    $ kubectl describe svc SERVICE_NAME -n YOUR_NAMESPACE

Example output:
    
    
    Name:                     nlb-ipNamespace:                default
    Labels:                   <none>
    Annotations:              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip              
                              service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing          
                              service.beta.kubernetes.io/aws-load-balancer-type: external                   
    Selector:                 app=nlb-ip
    Type:                     LoadBalancer
    IP Family Policy:         SingleStack
    IP Families:              IPv4
    IP:                       10.100.161.91
    IPs:                      10.100.161.91
    LoadBalancer Ingress:     k8s-default-nlbip-fff2442e46-ae4f8cf4a182dc4d.elb.ap-southeast-2.amazonaws.com
    Port:                     http  80/TCP
    TargetPort:               80/TCP
    NodePort:                 http  31806/TCP
    Endpoints:                192.168.93.144:80
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:                   <none>

**Note:** Note the value of **APPLICATION_POD_IP** to run a health check command in a later step.

To find Kubernetes Service annotations that are specific to your use case, see [Service annotations](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/>) on the Kubernetes website.

### Manually test a health check

Check your application pod IP address:
    
    
    $ kubectl get pod -n YOUR_NAMESPACE -o wide

Run a test pod to manually test a health check within the cluster:
    
    
    $ kubectl run -n YOUR_NAMESPACE troubleshoot -it --rm --image=amazonlinux -- /bin/bash

Then, run the HTTP health check: 
    
    
    # curl -Iv APPLICATION_POD_IP/HEALTH_CHECK_PATH

**Note:** Replace **APPLICATION_POD_IP** with your application pod IP address and **HEALTH_CHECK_PATH** with the Application Load Balancer target group health check path.

Example command:
    
    
    # curl -Iv 192.168.81.137

Example output:
    
    
    * Trying 192.168.81.137:80...* Connected to 192.168.81.137 (192.168.81.137) port 80 (#0)
    > HEAD / HTTP/1.1
    > Host: 192.168.81.137
    > User-Agent: curl/7.78.0
    > Accept: */*
    > 
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 200 OK
    HTTP/1.1 200 OK
    < Server: nginx/1.21.3
    Server: nginx/1.21.3
    < Date: Tue, 26 Oct 2021 05:10:17 GMT
    Date: Tue, 26 Oct 2021 05:10:17 GMT
    < Content-Type: text/html
    Content-Type: text/html
    < Content-Length: 615
    Content-Length: 615
    < Last-Modified: Tue, 07 Sep 2021 15:21:03 GMT
    Last-Modified: Tue, 07 Sep 2021 15:21:03 GMT
    < Connection: keep-alive
    Connection: keep-alive
    < ETag: "6137835f-267"
    ETag: "6137835f-267"
    < Accept-Ranges: bytes
    Accept-Ranges: bytes
    
    < 
    * Connection #0 to host 192.168.81.137 left intact

Check the HTTP response status code. If the response status code is **200 OK** , then your application correctly responds to the health check path.

If the HTTP response status code is **3xx** or **4xx** , then change your health check path. The following annotation responds with **200 OK** :
    
    
    alb.ingress.kubernetes.io/healthcheck-path: /ping

-or-

Use the following annotation on the ingress resource to add a successful health check response status code range:
    
    
    alb.ingress.kubernetes.io/success-codes: 200-399

For TCP health checks, use the following command to install the **netcat** command:
    
    
    # yum update -y && yum install -y nc

Test the TCP health checks:
    
    
    # nc -z -v APPLICATION_POD_IP CONTAINER_PORT_NUMBER

**Note:** Replace **APPLICATION_POD_IP** with your application pod IP address and **CONTAINER_PORT_NUMBER** with your container port.

Example command:
    
    
    # nc -z -v 192.168.81.137 80

Example output:
    
    
    Ncat: Version 7.50 ( https://nmap.org/ncat )
    Ncat: Connected to 192.168.81.137:80.Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.

### Check the networking

For networking issues, verify the following:

  * The multiple node groups in the EKS cluster can freely communicate with each other.
  * The network access control list (network ACL) that's associated with the subnet where your pods run allows traffic from the load balancer subnet CIDR range.
  * The network ACL that's associated with your load balancer subnet allows return traffic on the ephemeral port range from the subnet where the pods run.
  * The route table allows local traffic from within the VPC CIDR range.



### Restart the kube-proxy

If the kube-proxy that runs on each node doesn't work correctly, then the kube-proxy might fail to update the iptables rules for the service and endpoints. Restart the kube-proxy to force it to recheck and update iptables rules:
    
    
    kubectl rollout restart daemonset.apps/kube-proxy -n kube-system

Example output:
    
    
    daemonset.apps/kube-proxy restarted

## Related information

[How do I set up an Application Load Balancer through the AWS Load Balancer Controller on an Amazon EC2 node group in Amazon EKS?](<https://repost.aws/knowledge-center/eks-alb-ingress-controller-setup>)

[How do I troubleshoot load balancers created by the Kubernetes service controller in Amazon EKS?](<https://repost.aws/knowledge-center/eks-load-balancers-troubleshooting>)

[How do I automatically discover the subnets that my Application Load Balancer uses in Amazon EKS?](<https://repost.aws/knowledge-center/eks-vpc-subnet-discovery>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
