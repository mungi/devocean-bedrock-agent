Original URL: <https://repost.aws/knowledge-center/eks-anywhere-check-component-logs>

# How do I check EKS Anywhere cluster component logs on primary and worker nodes for BottleRocket, Ubuntu, or Redhat?

I want to check the component logs when the creation of a control plane or data plane machines fails in Amazon Elastic Kubernetes Service (Amazon EKS) Anywhere.

## Short description

During the creation of an Amazon EKS Anywhere workload cluster, you can check the logs for each machine in the control plane, etcd, and data plane.

To check the component logs in each machine, the following conditions must be met:

  * EKS Anywhere is trying to create a workload cluster, and each machine is in the process of creation.
  * Each machine allows you to log in through SSH on the control plane, etcd, and data plane.



## Resolution

Check the status of each machine with the **$ kubectl get machines** command.

Example management cluster:
    
    
    $ kubectl get machines -A
    NAMESPACE     NAME                         CLUSTER   NODENAME      PROVIDERID                                       PHASE     AGE     VERSION
    eksa-system   mgmt-etcd-bwnfq              mgmt                    vsphere://4230b0d5-7b14-4753-bd41-3dbe4987dbc4   Running   5h26m
    eksa-system   mgmt-etcd-bzm77              mgmt                    vsphere://4230b278-1fb4-f539-0afe-9f12afebf86b   Running   5h26m
    eksa-system   mgmt-etcd-dzww2              mgmt                    vsphere://42309b5a-b0ad-58a5-1e40-5fe39a3d1640   Running   5h26m
    eksa-system   mgmt-jw8dl                   mgmt      10.4.11.19    vsphere://42304059-c833-48d3-9856-7f902c852743   Running   5h26m   v1.24.9-eks-1-24-7
    eksa-system   mgmt-md-0-66b858b477-6cbcz   mgmt      10.4.35.76    vsphere://4230efad-5d42-c570-36c5-bf9ee92ee011   Running   5h26m   v1.24.9-eks-1-24-7
    eksa-system   mgmt-md-0-66b858b477-8h88c   mgmt      10.4.19.38    vsphere://4230edbf-db9b-3ae9-a2e6-8421e06863fb   Running   5h26m   v1.24.9-eks-1-24-7
    eksa-system   mgmt-s7fb7                   mgmt      10.4.67.152   vsphere://42301d6f-feb1-d967-9750-148d0823c7b5   Running   5h26m   v1.24.9-eks-1-24-7

After you check your machines' statuses and verify that you can check their component logs, log in to each machine through SSH. In the following example, **user** is the SSH login user that's specified in each provider's MachineConfig:
    
    
    $ ssh -i private_key_file user@Machine_IP_address

Depending on your machine's operating system (OS), follow the relevant steps to check its component logs.

**Note:** The **control plane** section refers to a machine with a name that has the cluster name prefix ("cluster_name-"). The **etcd** section refers to a machine with a name that has the cluster name and etcd prefix ("cluster_name-etcd-"). The **data plane** section refers to a machine with a name that has the cluster name and worker node name prefix ("cluster_name-worker_node_name-"). Depending on the ClusterConfig settings, etcd might not have a dedicated machine and instead starts on the control plane.

### Machines with BottleRocket OS

When you log in with SSH, you also log in to the admin container. For debugging purposes, obtain root privileges with the following command before you check the logs:
    
    
    $ sudo sheltie

**control plane**

For the kubelet log, run the following command:
    
    
    # journalctl -u kubelet.service --no-pager

For the containerd log, run the following command:
    
    
    # journalctl -u containerd.service --no-pager

For the machine initialization log, run the following command:
    
    
    # journalctl _COMM=host-ctr --no-pager

For each container log, check the logs in the **/var/log/containers** directory.

For Kubernetes **kube-apiserver** , **kube-controller-manager** , **kube-scheduler** , and **kube-vip manifests** , check the files in the **/etc/kubernetes/manifest** directory.

**etcd**

For the containerd log, run the following command::
    
    
    # journalctl -u containerd.service --no-pager

For the machine initialization log, run the following command::
    
    
    # journalctl _COMM=host-ctr --no-pager

For the etcd log, look in the **/var/log/containers** directory.

**data plane**

For the kubelet log, run the following command:
    
    
    # journalctl -u kubelet.service --no-pager

For the containerd log, run the following command:
    
    
    # journalctl -u containerd.service --no-pager

For the machine initialization log, run the following command:
    
    
    # journalctl _COMM=host-ctr

For each container log, check the logs in the **/var/log/containers** directory.

**Note:** If you use [AWS Snow](<https://docs.aws.amazon.com/snowball/latest/developer-guide/using-eksa.html>) as your provider, then also check the results of the following commands on each node:
    
    
    # journalctl -u bootstrap-containers@bottlerocket-bootstrap-snow.service
    # systemctl status bootstrap-containers@bottlerocket-bootstrap-snow

### Machines with Ubuntu or Red Hat Enterprise Linux OS

For debugging purposes, obtain root privileges with the following command before you check the logs:
    
    
    $ sudo su -

**control plane**

For the kubelet log, run the following command:
    
    
    # journalctl -u kubelet.service --no-pager

For the containerd log, run the following command:
    
    
    # journalctl -u containerd.service --no-pager

For the machine initialization log, run the following command:
    
    
    # cat /var/log/cloud-init-output.log

For each container log, check the logs in the **/var/log/containers** directory.

For userdata that initiates when the machine starts, run the following command:
    
    
    # cat /var/lib/cloud/instance/user-data.txt

For Kubernetes **kube-apiserver** , **kube-controller-manager** , **kube-scheduler** , and **kube-vip manifests** , check the files in the **/etc/kubernetes/manifest** directory.

**etcd**

For the etcd log, run the following command:
    
    
    # journalctl -u etcd.service --no-pager

For the machine initialization log, run the following command:
    
    
    # cat /var/log/cloud-init-output.log

For user data that initiates when the machine starts, run the following command:
    
    
    # cat /var/lib/cloud/instance/user-data.txt

**data plane**

For the kubelet log, run the following command:
    
    
    # journalctl -u kubelet.service --no-pager

For the containerd log, run the following command:
    
    
    # journalctl -u containerd.service --no-pager

For the machine initialization log, run the following command:
    
    
    # cat /var/log/cloud-init-output.log

For user data that initiates when the machine starts, run the following command:
    
    
    cat /var/lib/cloud/instance/user-data.txt

For each container log, check the logs in the **/var/log/containers** directory.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
