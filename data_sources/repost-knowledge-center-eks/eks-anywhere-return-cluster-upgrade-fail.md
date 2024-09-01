Original URL: <https://repost.aws/knowledge-center/eks-anywhere-return-cluster-upgrade-fail>

# How do I return an EKS Anywhere cluster to a working state when the cluster upgrade fails?

I want to use the eksctl command to upgrade an Amazon Elastic Kubernetes Service (Amazon EKS) Anywhere management cluster. However, the upgrade process fails or is interrupted before completion.

## Resolution

When you upgrade an Amazon EKS Anywhere management cluster, the process includes two phases: the verification phase and upgrade phase. The recovery steps for a failed upgrade depend on which phase of the upgrade was interrupted.

### Verification phase

When you upgrade an EKS Anywhere cluster, eksctl runs a set of preflight checks to make sure that your cluster is ready. This occurs before the upgrade, and eksctl modifies your cluster to match the updated specification.

When eksctl performs these checks, you see a message that's similar to the following example:
    
    
    Performing setup and validations
       Connected to server
       Authenticated to vSphere
       Datacenter validated
       Network validated
    Creating template. This might take a while.
       Datastore validated
       Folder validated
       Resource pool validated
       Datastore validated
       Folder validated
       Resource pool validated
       Datastore validated
       Folder validated
       Resource pool validated
       Machine config tags validated
       Control plane and Workload templates validated
       Vsphere provider validation
       Validate certificate for registry mirror
       Control plane ready
       Worker nodes ready
       Nodes ready
       Cluster CRDs ready
       Cluster object present on workload cluster
       Upgrade cluster kubernetes version increment
       Validate authentication for git provider
       Validate immutable fields
       Upgrade preflight validations pass

Next, eksctl continues to verify CAPI controllers that run in your management cluster. If any of these controllers need an upgrade, then eksctl also upgrades them. During this process, eksctl also creates a KinD bootstrap cluster to upgrade your management cluster. You see a message that reflects this process:
    
    
    Ensuring etcd CAPI providers exist on management cluster before 
    Pausing EKS-A cluster controller reconcile
    Pausing GitOps cluster resources reconcile
    Upgrading core components
    Creating bootstrap cluster
    Provider specific pre-capi-install-setup on bootstrap cluster
    Provider specific post-setup
    Installing cluster-api providers on bootstrap cluster

If any of these checks or actions fail, then the upgrade stops and your management cluster remains in the same original version.

For more details about the specific check that failed, check the eksctl logs.

**Issues during the verification phase**

To recover from a failure at this phase, complete the following steps:

1\. Troubleshoot and fix the problem that caused the verification to fail.

2\. Run the **eksctl anywhere cluster upgrade** command again. It's a best practice to use the **-v9** flag.

### Upgrade phase

In the upgrade phase, eksctl performs the following main actions:

  * Moves your management cluster CAPI objects (such as machines, KubeadmControlPlane, and EtcdadmCluster)to the bootstrap cluster
  * Upgrades the etcd and control plane components
  * Upgrades the worker node components



During this phase, you see a message that's similar to the following example:
    
    
    Moving cluster management from bootstrap to workload cluster
    Applying new EKS-A cluster resource
    Resuming EKS-A controller reconcile
    Updating Git Repo with new EKS-A cluster spec
    GitOps field not specified, update git repo skipped
    Forcing reconcile Git repo with latest commit
    GitOps not configured, force reconcile flux git repo skipped
    Resuming GitOps cluster resources kustomization
    Writing cluster config file
        Cluster upgraded!

eksctl uses a rolling process to perform the upgrade in place, similar to Kubernetes deployments. It also creates a new virtual machine (VM) with this upgrade, and then it removes the old VM. This process applies to each component, one at a time, until all control plane components are upgraded.

If a VM fails to run, then the upgrade fails and stops after a set timeout interval. The rolling process keeps the old VM running to make sure that your cluster remains in the **Ready** state.

**Issues during the upgrade phase**

To recover from a failure during this phase, complete the following steps:

1\. Troubleshoot and fix the problem that caused the upgrade to fail. Check the eksctl logs for details about the failure.

2\. To facilitate the recovery process, set up an environment variable:

  * **CLUSTER_NAME:** The name of your cluster
  * **CLITOOLS_CONT:** The name of the container that runs **image cli-tools** left in your environment after upgrade interruption
  * **KINDKUBE:** The Kubeconfig file that you use to access the KinD bootstrap cluster
  * **MGMTKUBE:** The Kubeconfig file that you use to access your management cluster
  * **EKSA_VSPHERE_USERNAME** and **EKSA_VSPHERE_PASSWORD:** Credentials to access vCenter



See the following example of these variables:
    
    
    CLUSTER_NAME=cluster3
    CLITOOLS_CONT=eksa_1681572481616591501
    KINDKUBE=$CLUSTER_NAME/generated/${CLUSTER_NAME}.kind.kubeconfig
    MGMTKUBE=$CLUSTER_NAME/$CLUSTER_NAME-eks-a-cluster.kubeconfig
    EKSA_VSPHERE_USERNAME=xxxxx
    EKSA_VSPHERE_PASSWORD=yyyyy

3\. Make sure that your management cluster CAPI components, such as machines and clusters, are in the **Ready** state. Also, make sure that **kubeApi-server** in your management cluster is responsive. To do this, run the following command:
    
    
    kubectl --kubeconfig $KINDKUBE -n eksa-system get machines
    docker exec -i $CLITOOLS_CONT clusterctl describe cluster cluster3  --kubeconfig $KINDKUBE -n eksa-system
    kubectl --kubeconfig $MGMTKUBE -n kube-system get node

You receive an output that's similar to the following example:
    
    
    NAME                            CLUSTER    NODENAME                        PROVIDERID                                       PHASE     AGE     VERSION
    cluster3-2snw8                  cluster3   cluster3-2snw8                  vsphere://4230efe1-e1f5-c8e5-9bff-12eca320f5db   Running   3m13s   v1.23.17-eks-1-23-19
    cluster3-etcd-chkc5             cluster3                                   vsphere://4230826c-b25d-937a-4728-3e607e6af579   Running   4m14s
    cluster3-md-0-854976576-tw6hr   cluster3   cluster3-md-0-854976576-tw6hr   vsphere://4230f2e5-0a4b-374c-f06b-41ac1f80e41f   Running   4m30s   v1.22.17-eks-1-22-24
    
    $ docker exec -i $CLITOOLS_CONT clusterctl describe cluster cluster3  --kubeconfig $KINDKUBE -n eksa-system
    NAME                                               READY  SEVERITY  REASON  SINCE  MESSAGE
    Cluster/cluster3                                   True                     49s
    ├─ClusterInfrastructure - VSphereCluster/cluster3  True                     4m53s
    ├─ControlPlane - KubeadmControlPlane/cluster3      True                     49s
    │ └─Machine/cluster3-2snw8                         True                     2m51s
    └─Workers
      ├─MachineDeployment/cluster3-md-0                True                     4m53s
      │ └─Machine/cluster3-md-0-854976576-tw6hr        True                     4m53s
      └─Other
        └─Machine/cluster3-etcd-chkc5                  True                     3m55s
        
    $ kubectl --kubeconfig $MGMTKUBE -n kube-system get node
    NAME                             STATUS   ROLES                  AGE   VERSION
    cluster3-md-0-854976576-tw6hr    Ready    [none]                 18m   v1.22.17-eks-a51510b
    cluster3-2snw8                   Ready    control-plane,master   19m   v1.23.17-eks-a51510b

4\. Back up your management cluster CAPI components:
    
    
    mkdir ${CLUSTER_NAME}-backup
    docker exec -i $CLITOOLS_CONT clusterctl move --to-directory ${CLUSTER_NAME}-backup  --kubeconfig $KINDKUBE -n eksa-system

5\. Move your management cluster CAPI components back to your management cluster:
    
    
    $ docker exec -i $CLITOOLS_CONT clusterctl move --to-kubeconfig $MGMTKUBE  --kubeconfig $KINDKUBE -n eksa-system
    Performing move...
    Discovering Cluster API objects
    Moving Cluster API objects Clusters=1
    Moving Cluster API objects ClusterClasses=0
    Creating objects in the target cluster
    Deleting objects from the source cluster

You receive an output that's similar to the following example:
    
    
    $ docker exec -i $CLITOOLS_CONT clusterctl move --to-kubeconfig $MGMTKUBE  --kubeconfig $KINDKUBE -n eksa-system
    Performing move...
    Discovering Cluster API objects
    Moving Cluster API objects Clusters=1
    Moving Cluster API objects ClusterClasses=0
    Creating objects in the target cluster
    Deleting objects from the source cluster

6\. Make sure that management cluster CAPI components, such as machines and clusters, are no longer in the KinD bootstrap cluster. Verify that they show up in the management cluster. To do this, run the following commands:
    
    
    kubectl --kubeconfig $KINDKUBE -n eksa-system get cluster -n eksa-system
    kubectl --kubeconfig $MGMTKUBE get machines -n eksa-system

You receive an output that's similar to the following example:
    
    
    $ kubectl --kubeconfig $KINDKUBE -n eksa-system get cluster -n eksa-system
    No resources found in eksa-system namespace.
    
    $ kubectl --kubeconfig $MGMTKUBE get machines -n eksa-system
    NAME                           CLUSTER    NODENAME                       PROVIDERID                                       PHASE     AGE     VERSION
    cluster2-4n7qd                 cluster2   cluster2-4n7qd                 vsphere://4230fb07-2823-3474-c41f-b7223dec3089   Running   2m27s   v1.23.17-eks-1-23-19
    cluster2-etcd-h4tpl            cluster2                                  vsphere://42303b36-1991-67a9-e942-dd9959760649   Running   2m27s
    cluster2-md-0-fd6c558b-6cfvq   cluster2   cluster2-md-0-fd6c558b-6cfvq   vsphere://423019a3-ad3f-1743-e7a8-ec8772d3edc2   Running   2m26s   v1.22.17-eks-1-22-24

7\. Run the upgrade again. Use the flags **\--force-cleanup -v9** flag:
    
    
    eksctl anywhere upgrade cluster -f cluster3/cluster3-eks-a-cluster.yaml --force-cleanup -v9

## Related information

[Upgrade vSphere, CloudStack, Nutanix, or Snow cluster](<https://anywhere.eks.amazonaws.com/docs/tasks/cluster/cluster-upgrades/vsphere-and-cloudstack-upgrades/>)

[EKS-A troubleshooting](<https://anywhere.eks.amazonaws.com/docs/tasks/troubleshoot/troubleshooting/#cluster-upgrade-fails-with-management-cluster-on-bootstrap-cluster>)

[The Cluster API Book](<https://cluster-api.sigs.k8s.io/introduction.html>) (on the Kubernetes website)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
