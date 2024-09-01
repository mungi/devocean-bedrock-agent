Original URL: <https://repost.aws/knowledge-center/eks-configure-ipvs-kube-proxy>

# How do I configure ipvs kube-proxy mode in Amazon EKS?

I want to change the Kubernetes network proxy mode from the default 'iptables' to 'ipvs' in Amazon Elastic Kubernetes Service (Amazon EKS).

## Resolution

**Prerequisites:**

  * Install [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  * [Install](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html>) and [configure](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html>) the latest version of the AWS Command Line Interface (AWS CLI).
  * Install [eksctl](<https://eksctl.io/installation/>) from the eksctl website.



**Note:** If you receive errors when you run AWS CLI commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### For an existing Amazon EKS cluster

To configure **ipvs kube-proxy** mode for an existing EKS cluster, complete the following steps:

  1. Make sure that **ipvs** is turned on for your worker node:
    
        sudo ipvsadm -L

When the proxy mode is set to the default **iptables** , the output looks similar to the following example:
    
        IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port           Forward Weight ActiveConn InActConn

  2. To make sure that you have the necessary IPVS kernel modules, run the following command:
    
        sudo lsmod | egrep -i "ip_vs|ip_vs_rr|ip_vs_wrr|ip_vs_sh|nf_conntrack"

  3. If IPVS modules are missing in the output, then run the following command to install the missing kernel modules:
    
        sudo modprobe ip_vs 
    sudo modprobe ip_vs_rr
    sudo modprobe ip_vs_wrr 
    sudo modprobe ip_vs_sh
    sudo modprobe nf_conntrack  

  4. To determine if your **kube-proxy** is a managed Amazon EKS add-on or self-managed add-on, run the following command:
    
        aws eks list-addons --cluster-name my-cluster | grep proxy

**Note:** Replace **my-cluster** with your cluster name. A managed Amazon EKS add-on returns **kube-proxy** as an output.

  5. Based on your add-on, configure the **kube-proxy** add-on with **ipvs** mode and the round robin option to equally distribute traffic to the backing servers.  
**Managed Amazon EKS add-on**
    
        aws eks update-addon --cluster-name my-cluster --addon-name kube-proxy \
        --addon-version v1.24.17-eksbuild.4 \
        --configuration-values '{"ipvs": {"scheduler": "rr"}, "mode": "ipvs"}' \
        --resolve-conflicts OVERWRITE

**Self-managed add-on**  
Backup the **kube-proxy** config configmap:
    
        kubectl get cm kube-proxy-config -n kube-system -o yaml > kube-proxy-config-old.yml

Edit the **kube-proxy-config** configmap:
    
        kubectl edit cm kube-proxy-config -n kube-system

In the config, change the **mode** parameter from **iptables** to **ipvs** , and then change **scheduler** to **rr** for round robin.
    
        ...
        ipvs:
          excludeCIDRs: null
          minSyncPeriod: 0s
          scheduler: "rr"          # add rr
          syncPeriod: 30s
        kind: KubeProxyConfiguration
        metricsBindAddress: 0.0.0.0:10249
        mode: "ipvs"         # change from iptables
    ... 

To apply the configuration changes, reload your cluster worker nodes. Use **eksctl** to scale in and scale out the worker nodes:
    
        # get node group names
    eksctl get nodegroup --cluster=my-cluster
    
    # scale-in
    eksctl scale nodegroup --cluster=my-cluster --nodes=0 --name=my-nodegroup-name --nodes-min=0 --nodes-max=3 --wait
    
    # scale-out
    eksctl scale nodegroup --cluster=my-cluster --nodes=2 --name=my-nodegroup-name --nodes-min=2 --nodes-max=3 --wait

**Note:** Replace **my-cluster** and **my-nodegroup-name** with your parameters. When you scale out, replace the node counts based on your cluster needs.

  6. To verify that **ipvs** mode is configured, run the following command:
    
        sudo ipvsadm -L

**Example output:**
    
        IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
    TCP  ip-10-100-0-1.eu-west-1.comp rr
      -> ip-192-168-118-22.eu-west-1. Masq    1      5          0
      -> ip-192-168-187-76.eu-west-1. Masq    1      6          0
    TCP  ip-10-100-0-10.eu-west-1.com rr
      -> ip-192-168-168-152.eu-west-1 Masq    1      0          0         
      -> ip-192-168-183-81.eu-west-1. Masq    1      0          0         
    UDP  ip-10-100-0-10.eu-west-1.com rr
      -> ip-192-168-168-152.eu-west-1 Masq    1      0          0         
      -> ip-192-168-183-81.eu-west-1. Masq    1      0          0 

The TCP and UDP entries are for Kubernetes and CoreDNS services in the cluster.

  7. To make sure that there are no **iptables** entries for **kube-svc*** in the cluster, run the following command:
    
        sudo iptables-save | grep -i kube-svc

If there are no **iptables** in the cluster, then the preceding command doesn't generate an output.




### For a new Amazon EKS cluster

To configure **ipvs kube-proxy** mode for a new EKS cluster, complete the following steps:

  1. When you create node groups, bootstrap the worker nodes [user data](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data>) to install the IPVS dependencies:
    
        ...
    #!/bin/bash
    echo "Running custom user data script"
    yum install -y ipvsadm
    ipvsadm -l
    modprobe ip_vs 
    modprobe ip_vs_rr
    modprobe ip_vs_wrr 
    modprobe ip_vs_sh
    modprobe ip_vs_lc
    modprobe nf_conntrack
    ...

  2. To create a managed Amazon EKS add-on for **kube-proxy** with the IPVS parameter, run the following command:
    
        aws eks create-addon --cluster-name my-cluster --addon-name kube-proxy \
        --addon-version v1.29.0-minimal-eksbuild.1 \
        --configuration-values '{"ipvs": {"scheduler": "rr"}, "mode": "ipvs"}' \
        --resolve-conflicts OVERWRITE

**Note:** Replace **v1.29.0-minimal-eksbuild.1** with the latest available **kube-proxy** version that's compatible with your Amazon EKS cluster version. For more information, see [Updating the Kubernetes kube-proxy self-managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html>).




## Related information

[Proxy modes](<https://kubernetes.io/docs/reference/networking/virtual-ips/#proxy-modes>) on the Kubernetes website

[Configuration for using NodeLocal DNSCache in Kubernetes clusters](<https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/#configuration>) on the Kubernetes website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
