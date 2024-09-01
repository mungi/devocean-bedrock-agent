Original URL: <https://repost.aws/knowledge-center/eks-vpc-cni-plugin-api-server-failure>

# Why does my VPC CNI plugin fail to reach the API server in Amazon EKS?

My Amazon Virtual Private Cloud (Amazon VPC) Container Network Interface (CNI) plugin fails to reach the API server in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

The **ipamD** daemon might try to connect to the API server before the **kube-proxy** adds the Kubernetes service port. In this case, the connection between **ipamD** and the API server times out. To troubleshoot this issue, check the **ipamD** and the **kube-proxy** logs, and then compare the timestamp of each.

You can also add an init container. The init container waits for the **kube-proxy** to create the Kubernetes service port. The **aws-node** pods then finish the initialization to avoid a timeout.

## Resolution

### Check the ipamD and kube-proxy logs

**ipamD logs**

If the connection between the **ipamD** and the API server times out, then you receive the following error:

"Failed to create client: error communicating with apiserver:"

**kube-proxy logs**

The **kube-proxy** creates iptables routes for Kubernetes API server endpoints on the worker node. After the **kube-proxy** creates the route, you see the following message:

"Adding new service port \"default/kubernetes:https\"

### Compare the timestamps between the logs

**ipamD logs**
    
    
    {"level":"error","ts":"2021-09-22T10:40:49.735Z","caller":"aws-k8s-agent/main.go:28","msg":"Failed to create client: error communicating with apiserver: Get https://10.77.0.1:443/version?timeout=32s: dial tcp 10.77.0.1:443: i/o timeout"}

**kube-proxy logs**
    
    
    {"log":"I0922 10:41:15.267648       1 service.go:379] Adding new service port \"default/kubernetes:https\" at 10.77.0.1:443/TCP\n","stream":"stderr","time":"2021-09-22T10:40:49.26766844Z"}

In the **ipamD** logs, you can see that the **ipamD** daemon tried to connect to the API server at **2021-09-22T10:40:49.735Z**. The connection timed out and failed. In the **kube-proxy** logs, you can see that the **kube-proxy** added the Kubernetes service port at **2021-09-22T10:41:15.26766844Z**.

### Add an init container

To add an init container, complete the following steps:

  1. Modify the **aws-node** specification so that the DNS is resolved for the Kubernetes service name:
    
        $ kubectl -n kube-system edit daemonset/aws-node

You receive the following output:
    
           initContainers:
       - name: init-kubernetes-api
         image: busybox:1.28
         command: ['sh', '-c', "until nc -zv ${KUBERNETES_PORT_443_TCP_ADDR} 443; do echo waiting for kubernetes Service endpoint; sleep 2; done"]

  2. Verify that the **aws-node** pods created the init containers:
    
        $ kubectl get pods -n kube-system  -w

You receive the following output:
    
            ...
        kube-proxy-smvfl                          0/1     Pending             0          0s
        aws-node-v68bh                            0/1     Pending             0          0s
        kube-proxy-smvfl                          0/1     Pending             0          0s
        aws-node-v68bh                            0/1     Pending             0          0s
        aws-node-v68bh                            0/1     Init:0/1            0          0s
        kube-proxy-smvfl                          0/1     ContainerCreating   0          0s
        kube-proxy-smvfl                          1/1     Running             0          6s
        aws-node-v68bh                            0/1     PodInitializing     0          9s
        aws-node-v68bh                            0/1     Running             0          16s
        aws-node-v68bh                            1/1     Running             0          53s




## Related information

[Updating the Kubernetes kube-proxy self-managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html>)

[Version skew policy](<https://kubernetes.io/releases/version-skew-policy>) on the Kubernetes website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
