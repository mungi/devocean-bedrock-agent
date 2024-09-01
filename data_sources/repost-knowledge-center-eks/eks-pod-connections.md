Original URL: <https://repost.aws/knowledge-center/eks-pod-connections>

# Why won't my pods connect to other pods in Amazon EKS?

My pods won't connect to other pods in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

If your pods can't connect with other pods, then you might receive the following errors, depending on your application.

If the security group from a worker node doesn't allow internode communication, then you receive the following error:
    
    
    curl: (7) Failed to connect to XXX.XXX.XX.XXX port XX: Connection timed out

If the DNS isn't working, then you receive the following error:
    
    
    curl nginx  
    curl: (6) Could not resolve host: nginx

If the DNS is working but there's a pod connectivity issue, then you receive the following error:
    
    
    Error: RequestError: send request failed caused by: Post  dial tcp 1.2.3.4.5:443: i/o timeout

If you try to resolve the DNS for the pod that isn't exposed through a service, then you receive the following error:
    
    
    kubectl exec -it busybox -- nslookup nginx 
    Server:   10.100.0.10
    Address:  10.100.0.10:53
    ** server can't find nginx.default.svc.cluster.local: NXDOMAIN
    *** Can't find nginx.svc.cluster.local: No answer
    *** Can't find nginx.cluster.local: No answer
    *** Can't find nginx.ap-southeast-2.compute.internal: No answer
    *** Can't find nginx.default.svc.cluster.local: No answer
    *** Can't find nginx.svc.cluster.local: No answer
    *** Can't find nginx.cluster.local: No answer
    *** Can't find nginx.ap-southeast-2.compute.internal: No answer

To resolve these errors, check that your environment is set up correctly:

  * Your security groups meet Amazon EKS guidelines.
  * The network access control list (network ACL) doesn't deny the connection.
  * Your subnet has a local route for communicating within your Amazon Virtual Private Cloud (Amazon VPC).
  * There are enough IP addresses available in the subnet.
  * Your security groups for pods allow pods to communicate with each other.
  * Your worker nodes have IP forwarding on.
  * You meet the networking requirements for Kubernetes (excluding any intentional **NetworkPolicy**).
  * Your pods are correctly using DNS to communicate with each other.
  * Your pods are scheduled and in the RUNNING state.
  * You have the recommended version of the Amazon VPC Container Network Interface (CNI) plugin for Kubernetes.



## Resolution

### Your security groups meet Amazon EKS guidelines

To restrict the traffic that you allow on the security group of your worker node, create inbound rules. Create these rules for any protocol or any ports that your worker nodes use for internode communication.

It's a best practice to allow all traffic for the security group of your worker node. You don't need to change security group rules every time a new pod with a new port is created.

For more information, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

### The network ACL doesn't deny the connection

1\. Confirm that traffic between your Amazon EKS cluster and VPC CIDR flows freely on your [network ACL](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html>).

2\. (Optional) To add an additional layer of security to your VPC, consider setting up network ACLs with rules similar to your security groups.

### Your subnet has a local route for communicating within your VPC

Confirm that your subnets have the default route for communication within the VPC.

### There are enough IP addresses available in the subnet

Confirm that your specified subnets have enough available IP addresses for the cross-account elastic network interfaces and your pods.

For more information, see [Amazon EKS VPC and subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-cidr>).

To check for available IP addresses, run the following AWS CLI command:
    
    
    $ aws ec2 describe-subnets --subnet-id YOUR-SUBNET-ID --query 'Subnets[0].AvailableIpAddressCount'

### Your security groups for pods allow pods to communicate with each other

If you use [security groups for pods](<https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html>) or [CNI custom networking](<https://docs.aws.amazon.com/eks/latest/userguide/cni-custom-network.html>), then you can allocate any security groups to pods. In this scenario, confirm that the security groups allow communication between pods correctly.

### Your worker nodes have IP forwarding on

If you use a custom AMI, then you must make sure that net.ipv4.ip_forward kernel variable is turned on. To verify this setting on a worker node, run either of the following commands:
    
    
    # sysctl net.ipv4.ip_forward
                
    # cat /proc/sys/net/ipv4/ip_forward

If the output is 0, use either of the following commands to active the net.ipv4.ip_forward kernel variable.
    
    
    # sysctl -w net.ipv4.ip_forward=1
                
    # echo 1 > /proc/sys/net/ipv4/ip_forward

For Amazon EKS AMIs in containerd runtime, see [lines 184-188 of the install-worker.sh script](<https://github.com/awslabs/amazon-eks-ami/blob/master/scripts/install-worker.sh#L184-L188>) (on GitHub) for the setting's activation. Because containerd is the default runtime in Amazon EKS versions 1.24 and newer, this step is required to troubleshoot pod-to-pod network connectivity.

You meet the networking requirements for Kubernetes (excluding any intentional NetworkPolicy)

Confirm that you meet the Kubernetes [networking requirements](<https://kubernetes.io/docs/concepts/cluster-administration/networking/>) (from the Kubernetes website).

By default, pods are not isolated. Pods accept traffic from any source. Pods become isolated by having a **NetworkPolicy** that selects them.

**Note:** For **NetworkPolicy** configurations, see [Installing the Calico network policy engine add-on](<https://docs.aws.amazon.com/eks/latest/userguide/calico.html>).

### Your pods are correctly using DNS to communicate with each other

You must expose your pods through a service first. If you don't, then your pods can't get DNS names and can be reached only by their specific IP addresses.

The following example output shows an attempt to resolve the DNS name for the **nginx** service. In this case, the **ClusterIP 10.100.94.70** is returned:
    
    
    $ kubectl run nginx --image=nginx --replicas=5 -n web
    deployment.apps/nginx created
    
    $ kubectl expose deployment nginx --port=80 -n web
    service/nginx exposed
    
    $ kubectl get svc -n web
    NAME    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    nginx   ClusterIP   10.100.94.70   <none>        80/TCP    2s
    
    # kubectl exec -ti busybox -n web -- nslookup nginx
    Server:    10.100.0.10
    Address 1: 10.100.0.10 ip-10-100-0-10.ap-southeast-2.compute.internal
    Name:      nginx
    Address 1: 10.100.94.70 ip-10-100-94-70.ap-southeast-2.compute.internal

If your pods still fail to resolve DNS, see [How do I troubleshoot DNS failures with Amazon EKS?](<https://repost.aws/knowledge-center/eks-dns-failure>)

**Note:** For more information, see [Pods](<https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pods>), [Service](<https://kubernetes.io/docs/concepts/services-networking/service/>), and [Headless Services](<https://kubernetes.io/docs/concepts/services-networking/service/#headless-services>) from the Kubernetes website.

### Your pods are scheduled and in the RUNNING state

Confirm that your pods are scheduled and in the RUNNING state.

To troubleshoot your pod status, see [How can I troubleshoot the pod status in Amazon EKS?](<https://repost.aws/knowledge-center/eks-pod-status-troubleshooting>)

### You have the recommended version of the Amazon VPC CNI plugin for Kubernetes

If you don't have the [recommended version](<https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html>) of the [Amazon VPC CNI plugin for Kubernetes](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>), then upgrade to the latest version.

If you have the recommended version but are experiencing issues with it, then see [How do I resolve kubelet or CNI plugin issues for Amazon EKS?](<https://repost.aws/knowledge-center/eks-cni-plugin-troubleshooting>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
