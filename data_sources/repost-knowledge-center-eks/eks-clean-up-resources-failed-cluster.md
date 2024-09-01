Original URL: <https://repost.aws/knowledge-center/eks-clean-up-resources-failed-cluster>

# How do I clean up EKS Anywhere resources without eksctl when cluster creation fails?

My Amazon Elastic Kubernetes Service (Amazon EKS) Anywhere cluster failed the creation process. I want to manually clean up my resources because I can't use eksctl.

## Short description

When you create an EKS Anywhere cluster, the process also creates a bootstrap cluster on the administrative machine. This bootstrap cluster is a Kubernetes in Docker (KinD) cluster that facilitates the creation of the EKS Anywhere cluster. To clean up the KinD cluster, stop the KinD containers and remove the KinD container images.

For other providers, you must complete additional steps on the virtual machines (VMs) for the control plane and nodes.

## Resolution

### Clean up resources on the administrative machine for Docker

To clean up all unwanted resources from the failed cluster creation, use the following script for all use cases.

Because the **kind delete cluster** command requires KinD installation, this script doesn't use the command. Instead, EKS Anywhere uses KinD binaries from temporary containers to set up clusters:
    
    
    EKSA_CLUSTER_NAME="YOUR_CLUSTER_NAME"
    # Clean up KIND Cluster Containers  
    kind_container_ids=$(docker ps -a | grep "${EKSA_CLUSTER_NAME}" | awk -F ' ' '{print $1}')  
    for container_id in $kind_container_ids; do echo "deleting container with id ${container_id}"; docker rm -f ${container_id}; done
    
    # Clean up EKS-A tools Containers  
    tools_container_ids=$(docker ps -a | grep "public.ecr.aws/eks-anywhere/cli-tools" | awk -F ' ' '{print $1}')  
    for container_id in $tools_container_ids; do echo "deleting container with id ${container_id}"; docker rm -f ${container_id}; done  
    
    # Delete All EKS-Anywhere Images  
    image_ids=$(docker image ls | grep "public.ecr.aws/eks-anywhere/" | awk -F ' ' '{print $3}')  
    for image_id in $image_ids; do echo "deleting image with id ${image_id}"; docker image rm ${image_id}; done
    
    # Delete Auto-generated Cluster Folder  
    rm $EKSA_CLUSTER_NAME -rf

**Note:** Replace **YOUR_CLUSTER_NAME** with your EKS Anywhere cluster name.

### Clean up resources on the VM for Bare Metal, Nutanix, CloudStack and vSphere

If any VMs are created during the creation process and creation fails, then you must manually clean up the VMs.

If you use a separate management cluster to create and manage EKS Anywhere clusters, then see the following **Clusters with a management cluster** section. If your EKS Anywhere cluster doesn't support a separate management cluster, then see the following **Clusters without a management cluster** section.

**Clusters without a management cluster**

For clusters without a separate management cluster, power off and delete all worker nodes, etcd VMs, and the API server.

**Note:** The cluster name is commonly included as a prefix in names for VMs that are associated with Nutanix, CloudStack, and vSphere clusters.

For Bare Metal clusters, power off and delete the target machines.

**Clusters with a management cluster**

When you use a management cluster, a separate cluster monitors your workload cluster's state. If a machine that's part of the workload cluster powers off and terminates, then the management cluster detects a health issue. The cluster then spins up a new virtual machine to bring the workload cluster back to the desired state.

Therefore, to clean up clusters with separate management clusters, delete the Custom Resources (CRDs) that represent the workload cluster. This deletes all the VMs for the workload cluster.

**Note:** In the following commands, replace **WORKLOAD_CLUSTER_NAME** with your workload cluster's name. Replace **MANAGEMENT_CLUSTER_FOLDER** with your EKS Anywhere management folder. Replace **MANAGEMENT_CLUSTER_KUBECONFIG_FILE** with the kubeconfig file your management cluster's kubeconfig file. The kubeconfig file is in the **MANAGEMENT_CLUSTER_FOLDER**.

Delete the Cluster API resource for the workload cluster:
    
    
    kubectl delete clusters.cluster.x-k8s.io -n eksa-system WORKLOAD_CLUSTER_NAME --kubeconfig MANAGEMENT_CLUSTER_FOLDER/MANAGEMENT_CLUSTER_KUBECONFIG_FILE

If the resources exist, then delete the **clusters.anywhere.eks.amazonaws.com** resource for the cluster:
    
    
    kubectl delete clusters.anywhere.eks.amazonaws.com WORKLOAD_CLUSTER_NAME --kubeconfig MANAGEMENT_CLUSTER_FOLDER/MANAGEMENT_CLUSTER_KUBECONFIG_FILE

**Note:** If the cluster creation failed before the **clusters.anywhere.eks.amazonaws.com** resource was provisioned, then you get the following error:

"Error from server (NotFound): clusters.anywhere.eks.amazonaws.com "WORKLOAD_CLUSTER_NAME" not found"

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
