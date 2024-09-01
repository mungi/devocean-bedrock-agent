Original URL: <https://repost.aws/knowledge-center/eks-anywhere-etcdadm-controller-issues>

# How can I troubleshoot etcdadm controller issues in EKS Anywhere?

I want to check the logs in etcdadm pods for clues to troubleshoot ETCD bootstrap failure issues.

## Short description

If your Amazon Elastic Kubernetes Service (Amazon EKS) Anywhere nodes experience bootstrap failure, then check the logs for etcdadm pods. Also, check the logs for etcd pods that you created for a stacked etcd cluster.

To further debug, log in to any of the etcd virtual machines (VMs). If you didn't create an etcd VM before the bootstrap failure, then you can't use the VM to debug.

## Resolution

### Check the logs in etcdadm pods

**Note:** In the following commands, replace **SUFFIX** with your bootstrap provider's suffix. Replace **KUBECONFIG_FILE** with your kubeconfig file location.

After you [create your cluster](<https://anywhere.eks.amazonaws.com/docs/concepts/clusterworkflow/>), you can use it with the generated [KUBECONFIG file in your local directory](<https://anywhere.eks.amazonaws.com/docs/getting-started/production-environment/vsphere-getstarted/#:~:text=Once%20the%20cluster,a%2Dcluster.kubeconfig>):
    
    
    KUBECONFIG=${PWD}/${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig

To check the logs for **etcdadm-bootstrap-provider-controller** , run the following command:
    
    
    kubectl -n etcdadm-bootstrap-provider-system logs etcdadm-bootstrap-provider-controller-SUFFIX  
        --kubeconfig=KUBECONFIG_FILE

To check the logs for **etcdadm-controller-controller-manager** , run the following command:
    
    
    kubectl -n etcdadm-controller-system logs etcdadm-controller-controller-manager-SUFFIX --kubeconfig=KUBECONFIG_FILE

### Check the logs for a stacked etcd

If you created pods for a stacked etcd cluster, then run the following command to check those pods' logs:
    
    
    kubectl logs -n kube-system etcd-$CONTROL_PLANE_VM_IP --kubeconfig=KUBECONFIG_FILE

**Note:** Replace **KUBECONFIG_FILE** with your kubeconfig file location.

**Check VM logs**

After you use the kubectl client to check for logs, you can also check for logs on the VMs:

1\. Log in to the VM's control plane:
    
    
    ssh -i $PRIV_KEY ec2-user@$CONTROL_PLANE_VM_IP

**Note:** Replace **PRIV_KEY** with your private key. Replace **CONTROL_PLANE_VM_IP** with the IP address of your control plane's VM.

2\. For a BottleRocket operating system (OS): To get the root shell for a node that runs on BottleRocket OS, run the **sudo sheltie** command.

3\. After you log in to an etcd VM, you can check additional related container logs at the following location:
    
    
    cd /var/log/containers

### Check the logs for an unstacked or external etcd

For an unstacked or external etcd, log in to any etcd VM that you created.

1\. To log in to your etcd VM, run the following command:
    
    
    ssh -i $PRIV_KEY ec2-user@$ETCD_VM_IP

**Note:** Replace **PRIV_KEY** with your private key. Replace **ETCD_VM_IP** with the IP address of your VM.

2\. For a BottleRocket operating system (OS): To get the root shell for a node that runs on BottleRocket OS, run the **sudo sheltie** command.

3\. After you log in to an etcd VM, you can check additional related container logs at the following location:
    
    
    cd /var/log/containers  
    bash-5.1# ls -lrt  
    total 4  
    lrwxrwxrwx. 1 root root 90 Apr 11 16:38 etcd-mgmt-etcd-4mt4g_kube-system_etcd-aa91be45434b920903e0630254cb5f319b86b50c56b87d8f992b0285272b93c4.log -> /var/log/pods/kube-system_etcd-mgmt-etcd-4mt4g_88b6dbc1be367b4ffc5a6bfab65e7376/etcd/0.log

**Run a health check**
    
    
    ETCD_CONTAINER_ID=$(ctr -n k8s.io c ls | grep -w "etcd-io" | cut -d " " -f1)  
    ctr -n k8s.io t exec -t --exec-id etcd ${ETCD_CONTAINER_ID} etcdctl \  
         --cacert=/var/lib/etcd/pki/ca.crt \  
         --cert=/var/lib/etcd/pki/server.crt \  
         --key=/var/lib/etcd/pki/server.key \  
         endpoint health  
      
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 10.241212ms

### Example error messages

When you check your logs, you might see various error messages relating to your bootstrap failure. The following examples are some of the most common errors:

**"Waiting for External ETCD to be ready."**

To troubleshoot this error, refer to the [troubleshooting documentation for Amazon EKS Anywhere](<https://anywhere.eks.amazonaws.com/docs/tasks/troubleshoot/troubleshooting/#waiting-for-external-etcd-to-be-ready>).

"**Kubelet of ETCD VMs Crashing."**

Cluster provisioning doesn't continue after the creation of your ETCD VM. This issue also occurs with the following kubelet error message:

"Failed to start ContainerManager" err="invalid Node Allocatable configuration. Resource \"ephemeral-storage\" has an allocatable of {{1175812097 0} {<nil>} BinarySI}, capacity of {{-155109377 0} {<nil>} BinarySI}"

This indicates that the ephemeral storage on the node doesn't have sufficient free space. In each Kubernetes node, kubelet's root directory (**/var/lib/kubelet** by default) and log directory (**/var/log**) are on the root partition of the node.

To display the free disc space of a specific file system, run the following command:
    
    
    "df -h"

To display a list of all files and their respective sizes, run the following command:
    
    
    "sudo du -d 3 /var/lib/"

If you don't have enough free disc space, then clean up your node to free up space. Or, expand the storage capacity of your node’s root partition.

## Related information

[Install etcd](<https://etcd.io/docs/v3.4/install/>) (etcd website)

[How to check cluster status](<https://etcd.io/docs/v3.5/tutorials/how-to-check-cluster-status/>) (etcd website)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
