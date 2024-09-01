Original URL: <https://repost.aws/knowledge-center/eks-unhealthy-worker-node-nginx>

# Why is my worker node status "Unhealthy" when I use the NGINX Ingress Controller with Amazon EKS?

I use the NGINX Ingress Controller to expose the ingress resource. However, my Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes fail to use the Network Load Balancer.

## Short description

To preserve the client IP, the NGINX Ingress Controller sets the **spec.externalTrafficPolicy** option to **Local**. Also, it routes requests only to healthy worker nodes.

To troubleshoot the status of your worker nodes and update your traffic policy, see the following steps.

**Note:** There's no requirement to maintain the cluster IP address or preserve the client IP address.

## Resolution

### Check the health status of your worker nodes

**Note:** The following examples use the NGINX Ingress Controller v1.5.1 running on EKS Cluster v1.23.

1\. Create the [mandatory resources for the NGINX Ingress Controller](<https://kubernetes.github.io/ingress-nginx/deploy/#aws>) (from the Kubernetes website) in your cluster:
    
    
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/aws/deploy.yaml

By default, the NGINX Ingress Controller creates the Kubernetes Service **ingress-nginx-controller** with the **.spec.externalTrafficPolicy** option set to [Local](<https://github.com/kubernetes/ingress-nginx/blob/controller-v1.0.2/deploy/static/provider/aws/deploy.yaml#L279>) (from the GitHub website).

2\. Check if the [external traffic policy](<https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip>) (from the Kubernetes website) is set to **Local** :
    
    
    $ kubectl -n ingress-nginx describe svc ingress-nginx-controller

You receive an output that's similar to the following:
    
    
    Name:                     ingress-nginx-controller
    Namespace:                ingress-nginx
    Labels:                   app.kubernetes.io/component=controller
                              app.kubernetes.io/instance=ingress-nginx
                              app.kubernetes.io/managed-by=Helm
                              app.kubernetes.io/name=ingress-nginx
                              app.kubernetes.io/version=1.0.2
                              helm.sh/chart=ingress-nginx-4.0.3
    Annotations:              service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
                              service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: true
                              service.beta.kubernetes.io/aws-load-balancer-type: nlb
    Selector:                 app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
    Type:                     LoadBalancer
    IP Families:              <none>
    IP:                       10.100.115.226
    IPs:                      10.100.115.226
    LoadBalancer Ingress:     a02245e77404f4707a725d0b977425aa-5b97f717658e49b9.elb.eu-west-1.amazonaws.com
    Port:                     http  80/TCP
    TargetPort:               http/TCP
    NodePort:                 http  31748/TCP
    Endpoints:                192.168.43.203:80
    Port:                     https  443/TCP
    TargetPort:               https/TCP
    NodePort:                 https  30045/TCP
    Endpoints:                192.168.43.203:443
    Session Affinity:         None
    External Traffic Policy:  Local
    HealthCheck NodePort:     30424
    Events:                   <none>

**Note:** The **Local** setting drops packets that are sent to Kubernetes nodes and doesn't need to run instances of the NGINX Ingress Controller. [Assign NGINX pods](<https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/>) (from the Kubernetes website) to the nodes that you want to schedule the NGINX Ingress Controller for.

3\. Check the iptables command that set up the DROP rules on the nodes that aren't running instances of the NGINX Ingress Controller:
    
    
    $ sudo iptables-save | grep -i "no local endpoints"
    -A KUBE-XLB-CG5I4G2RS3ZVWGLK -m comment --comment "ingress-nginx/ingress-nginx-controller:http has no local endpoints
            " -j KUBE-MARK-DROP
    -A KUBE-XLB-EDNDUDH2C75GIR6O -m comment --comment "ingress-nginx/ingress-nginx-controller:https has no local endpoints " -j KUBE-MARK-DROP

### Set the policy option

Update the **spec.externalTrafficPolicy** option to **Cluster** :
    
    
    $ kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
    service/ingress-nginx-controller patched

By default, NodePort services perform [source IP address translation](<https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport>) (from the Kubernetes website). For NGINX, this means that the source IP address of an HTTP request is always the IP address of the Kubernetes node that received the request. If you set **externalTrafficPolicy** (.spec.externalTrafficPolicy) to **Cluster** in the **ingress-nginx** service specification, then the incoming traffic doesn't preserve the source IP address. For more information, see [Preserving the client source IP address](<https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip>) (on the Kubernetes website).

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
