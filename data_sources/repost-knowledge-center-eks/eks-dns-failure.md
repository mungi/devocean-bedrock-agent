Original URL: <https://repost.aws/knowledge-center/eks-dns-failure>

# How do I troubleshoot DNS failures with Amazon EKS?

The applications or pods that use CoreDNS in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster fail internal or external DNS name resolutions.

## Short description

Pods that run inside the Amazon EKS cluster use the CoreDNS cluster IP address as the name server to query internal and external DNS records. If there are issues with the CoreDNS pods, service configuration, or connectivity, then applications might fail DNS resolutions.

A service object called **kube-dns** abstracts the CoreDNS pods. To troubleshoot issues with your CoreDNS pods, verify the working status of all the **kube-dns** service's components, such as service endpoint options and **iptables** rules.

## Resolution

The following resolution applies to the CoreDNS ClusterIP **10.100.0.10**.

Complete the following steps:

  1. Get the ClusterIP of your CoreDNS service:
    
        kubectl get service kube-dns -n kube-system

  2. Verify that the DNS endpoints are exposed and pointing to CoreDNS pods:
    
        kubectl -n kube-system get endpoints kube-dns

Example output:
    
        NAME       ENDPOINTS                                                        AGE
    kube-dns   192.168.2.218:53,192.168.3.117:53,192.168.2.218:53 + 1 more...   90d

**Note:** If the endpoint list is empty, then [check the pod status of the CoreDNS pods](<https://aws.amazon.com/premiumsupport/knowledge-center/eks-pod-status-troubleshooting/>).

  3. Verify that a [security group](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) or network access control list (network ACL) isn't blocking the pods when it communicates with CoreDNS.

For more information, see [Why won't my pods connect to other pods in Amazon EKS?](<https://aws.amazon.com/premiumsupport/knowledge-center/eks-pod-connections/>)




### Verify that the kube-proxy pod is working

To verify that the **kube-proxy** pod has access to API servers for your cluster, check your logs for timeout errors to the control plane. Also, check for 403 unauthorized errors.

Get the **kube-proxy** logs:
    
    
    kubectl logs -n kube-system --selector 'k8s-app=kube-proxy'

**Note:** The **kube-proxy** gets the endpoints from the control plane and creates the **iptables** rules on every node.

### Check CPU utilization of the CoreDNS pods at the time of the issue

The Amazon EKS CoreDNS add-on adds only the 170Mi limit to the CoreDNS pod's memory. The CoreDNS pod doesn't define a CPU limit, so the container can use all the available CPU resources on the node where it runs. If the node CPU utilization reaches 100%, then you might get DNS timeout errors in your Amazon EKS application logs. This is because the CoreDNS pod doesn't have enough CPU resources to handle all DNS queries.

### Connect to the application pod to troubleshoot the DNS issue

Complete the following steps:

  1. To run commands inside your application pods, run the following command to access a shell inside the running pod:
    
        $ kubectl exec -it your-pod-name -- sh

If the application pod doesn't have an available shell binary, then you receive an error similar to the following example:

"OCI runtime exec failed: exec failed: container_linux.go:348: starting container process caused "exec: \"sh\": executable file not found in $PATH": unknown command terminated with exit code 126

To debug, update the image that's used in your manifest file for another image, such as the [busybox](<https://hub.docker.com/_/busybox>) image on the Docker website.

  2. Verify that the cluster IP address of the **kube-dns** service is in your pod's **/etc/resolv.conf** file. Run the following command in the shell that's inside the pod:
    
        cat /etc/resolv.conf

The following example **resolv.conf** file shows a pod that's configured to point to **10.100.0.10** for DNS requests. The IP address must match the **ClusterIP** of your **kube-dns** service:
    
        nameserver 10.100.0.10
    search default.svc.cluster.local svc.cluster.local cluster.local ec2.internal
    options ndots:5

**Note:** You can manage your pod's DNS configuration with the **dnsPolicy** field in the pod specification. If you don't populate this field, then the **ClusterFirst** DNS policy is used by default. For more information on the **ClusterFirst** DNS policy, see [Pod's DNS policy](<https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy>) on the Kubernetes website. 

  3. To verify that your pod can use the default **ClusterIP** to resolve an internal domain, run the following command in the shell that's inside the pod:
    
        nslookup kubernetes.default 10.100.0.10

Example output:
    
        Server:     10.100.0.10
    Address:    10.100.0.10#53
    Name:       kubernetes.default.svc.cluster.local
    Address:    10.100.0.1

  4. To verify that your pod can use the default **ClusterIP** to resolve an external domain, run the following command in the shell that's inside the pod:
    
        nslookup amazon.com 10.100.0.10

Example output:
    
        Server:     10.100.0.10
    Address:    10.100.0.10#53
    Non-authoritative answer:
    Name:   amazon.com
    Address: 176.32.98.166
    Name:    amazon.com
    Address: 205.251.242.103
    Name:    amazon.com
    Address: 176.32.103.205

  5. Verify that your pod can use the IP address of the CoreDNS pod to resolve directly. Run the following commands in the shell that's inside the pod:
    
        nslookup kubernetes COREDNS_POD_IP
    
    nslookup amazon.com COREDNS_POD_IP

**Note:** Replace the **COREDNS_POD_IP** with one of the endpoint IP addresses from the **kubectl** get endpoints.




### Get more detailed logs from CoreDNS pods to debug

Complete the following steps:

  1. Turn on the debug log of CoreDNS pods, and then add the log plugin to the CoreDNS ConfigMap:
    
        kubectl -n kube-system edit configmap coredns

**Note:** For more information, see [log plugin](<https://coredns.io/plugins/log/>) on the CoreDNS website.

  2. In the editor screen that appears in the output, add the log string:
    
        kind: ConfigMap
    apiVersion: v1
    data:
      Corefile: |
        .:53 {
            log    # Enabling CoreDNS Logging
            errors
            health
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              upstream
              fallthrough in-addr.arpa ip6.arpa
            }
            ...
    ...

**Note:** It takes several minutes to reload the configuration CoreDNS. To immediately apply the changes, restart the pods one by one.

  3. Check if the CoreDNS logs fail or get any hits from the application pod:
    
        kubectl logs --follow -n kube-system --selector 'k8s-app=kube-dns'




### Update the ndots value

The **ndots** value is the number of dots that must appear in a domain name to resolve a query before the initial absolute query.

For example, you set the **ndots** option to the default value **5** in a domain name that's not fully qualified. Then, all external domains that aren't under the internal domain **cluster.local** append to the search domains before they query.

The following example has the **/etc/resolv.conf** file setting of the application pod:
    
    
    nameserver 10.100.0.10
    search default.svc.cluster.local svc.cluster.local cluster.local ec2.internal
    options ndots:5

CoreDNS looks for five dots in the domain that's queried. If the pod makes a DNS resolution call for **amazon.com** , then your logs look similar to the following example:
    
    
    [INFO] 192.168.3.71:33238 - 36534 "A IN amazon.com.default.svc.cluster.local. udp 54 false 512" NXDOMAIN qr,aa,rd 147 0.000473434s
    [INFO] 192.168.3.71:57098 - 43241 "A IN amazon.com.svc.cluster.local. udp 46 false 512" NXDOMAIN qr,aa,rd 139 0.000066171s
    [INFO] 192.168.3.71:51937 - 15588 "A IN amazon.com.cluster.local. udp 42 false 512" NXDOMAIN qr,aa,rd 135 0.000137489s
    [INFO] 192.168.3.71:52618 - 14916 "A IN amazon.com.ec2.internal. udp 41 false 512" NXDOMAIN qr,rd,ra 41 0.001248388s
    [INFO] 192.168.3.71:51298 - 65181 "A IN amazon.com. udp 28 false 512" NOERROR qr,rd,ra 106 0.001711104s

**Note:** **NXDOMAIN** means that the domain record wasn't found, and **NOERROR** means that the domain record was found.

Every search domain is prepended with **amazon.com** before it makes the final call on the absolute domain that's at the end. A final domain name that's appended with a dot (**.**) at the end is a fully qualified domain name. Therefore, for every external domain name query, there might be four to five additional calls that can overwhelm the CoreDNS pod.

To resolve this issue, either change **ndots** to **1** to look only for a single dot. Or, append a dot (**.**) at the end of the domain that you query or use:
    
    
    nslookup example.com.

### Consider VPC resolver (AmazonProvidedDNS) limits

The Amazon Virtual Private Cloud (Amazon VPC) resolver can accept a [maximum hard limit](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-limits>) of only 1024 packets per second per network interface. If more than one CoreDNS pod is on the same node, then the chances are higher to reach this limit for external domain queries.

To use **PodAntiAffinity** rules to schedule CoreDNS pods on separate instances, add the following options to the CoreDNS deployment:
    
    
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: k8s-app
              operator: In
              values:
              - kube-dns
          topologyKey: kubernetes.io/hostname
        weight: 100

**Note:** For more information on **PodAntiAffinity** , see [Inter-pod affinity and anti-affinity](<https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity>) on the Kubernetes website.

### Use tcpdump to capture CoreDNS packets from Amazon EKS worker nodes

To help you diagnose DNS resolution issues, use the tcpdump tool to perform a packet capture:

  1. Locate a worker node where a CoreDNS pod is running:
    
        kubectl get pod -n kube-system -l k8s-app=kube-dns -o wide

  2. Use SSH to connect to the worker node where a CoreDNS pod is running, and then install the tcpdump tool:
    
        sudo yum install tcpdump –y

  3. Locate the CoreDNS pod process ID on the worker node:
    
        ps ax | grep coredns

  4. From the worker node, perform a packet capture on the CoreDNS pod network to monitor network traffic on UDP port 53:
    
        sudo nsenter -n -t PID tcpdump udp port 53

  5. From a separate terminal, get the CoreDNS service and pod IP address:
    
        kubectl describe svc kube-dns -n kube-system

**Note:** Note the service IP address that's located in the **IP** field and the pod IP address that's located in the **Endpoints** field.

  6. Launch a pod to test the DNS service from. The following example uses an Ubuntu container image:
    
        kubectl run ubuntu --image=ubuntu sleep 1d
    
    kubectl exec -it ubuntu sh

  7. Use the nslookup tool to perform a DNS query to a domain, such as **amazon.com** :
    
        nslookup amazon.com

Explicitly perform the same query against the CoreDNS service IP address:
    
        nslookup amazon.com COREDNS_SERVICE_IP

Perform the query against each of the CoreDNS pod IP address:
    
        nslookup amazon.com COREDNS\_POD\_IP

**Note:** If you're running multiple CoreDNS pods, then perform multiple queries so that at least one query is sent to the pod that you're capturing traffic from.

  8. Review the packet capture results.

If your monitored CoreDNS pod experiences DNS query timeouts, and you don't see the query in the packet capture, then check your network connectivity. Make sure to check the network reachability between worker nodes.

If you see a DNS query timeout against a pod IP address that you're not capturing, then perform another packet capture on the related worker node.

To save the results of a packet capture, add the **-w FILE_NAME** flag to the **tcpdump** command. The following example writes the results to a file that's named **capture.pcap** :
    
        tcpdump -w capture.pcap udp port 53




## Related information

[CoreDNS GA for Kubernetes cluster DNS](<https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/>)

on the Kubernetes website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
