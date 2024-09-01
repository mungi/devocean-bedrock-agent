Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-secrets-manager-issues>

# How do I troubleshoot issues when I integrate AWS Secrets Manager with Amazon EKS?

When I try to integrate AWS Secrets Manager with Amazon Elastic Kubernetes Service (Amazon EKS), I get an error.

## Short description

When you integrate AWS Secrets Manager with Amazon EKS, you can get an error if your pods fail to enter into the **Running** state. To resolve this issue, check the logs from the Secrets Store Container Storage Interface (CSI) Driver pods to see if any pods aren't performing.

## Resolution

To display the Secrets Store CSI Driver pods, run the following command:
    
    
    kubectl --namespace=kube-system get pods -l "app=secrets-store-csi-driver"

To display the logs from the Secrets Store CSI pods, run the following command:
    
    
    kubectl --namespace=kube-system logs -f -l "app=secrets-store-csi-driver"

The following logs show that each pod is performing well:
    
    
    I1120 20:21:19.135834       1 secrets-store.go:74] Driver: secrets-store.csi.k8s.io
    I1120 20:21:19.135857       1 secrets-store.go:75] Version: v0.2.0, BuildTime: 2021-08-12-18:55
    I1120 20:21:19.135868       1 secrets-store.go:76] Provider Volume Path: /etc/kubernetes/secrets-store-csi-providers
    I1120 20:21:19.135874       1 secrets-store.go:77] GRPC supported providers will be dynamically created
    I1120 20:21:19.135895       1 driver.go:80] "Enabling controller service capability" capability="CREATE_DELETE_VOLUME"
    I1120 20:21:19.135912       1 driver.go:90] "Enabling volume access mode" mode="SINGLE_NODE_READER_ONLY"
    I1120 20:21:19.135922       1 driver.go:90] "Enabling volume access mode" mode="MULTI_NODE_READER_ONLY"
    I1120 20:21:19.135938       1 main.go:172] starting manager
    I1120 20:21:19.136210       1 server.go:111] Listening for connections on address: //csi/csi.sock
    I1120 20:21:18.956092       1 exporter.go:33] metrics backend: prometheus

**Note:** Pods that perform the same actions appear as duplicate entries.

If the **SecretProviderClass** in the **volumeMount** doesn't exist in the same namespace as the pod, then you receive the following error:

"Warning FailedMount 3s (x4 over 6s) kubelet, kind-control-plane MountVolume.SetUp failed for volume "secrets-store-inline" : rpc error: code = Unknown desc = failed to get secretproviderclass default/aws, error: secretproviderclasses.secrets-store.csi.x-k8s.io "aws" not found"

The **SecretProviderClass** must exist in the same namespace as the pod.

The Secrets Store CSI Driver is deployed as a daemonset. If the CSI Driver pods aren't running on the node, then you receive the following error:

"Warning FailedMount 1s (x4 over 4s) kubelet, kind-control-plane MountVolume.SetUp failed for volume "secrets-store-inline" : kubernetes.io/csi: mounter.SetUpAt failed to get CSI client: driver name secrets-store.csi.k8s.io not found in the list of registered CSI drivers"

If the node is tainted, then add a toleration for the taint in the Secrets Store CSI Driver daemonset.

Check if there are any node selectors that don't allow the Secrets Store CSI Driver pods to run on the node:
    
    
    kubectl --namespace=kube-system describe pods -l "app=secrets-store-csi-driver" | grep Node-Selectors*

Get the labels that are associated to the worker nodes in your pod:
    
    
    kubectl get node --selector=kubernetes.io/os=linux

Compare the outputs from the preceding commands. Make sure that the labels match the node selector values.

Check if the CSI Driver was deployed to the cluster and if all pods are in the **Running** state:
    
    
    kubectl get pods -l app=secrets-store-csi-driver -n kube-system

-or-
    
    
    kubectl get daemonset csi-secrets-store-secrets-store-csi-driver -n kube-system

Example output:
    
    
    kubectl get csidriver
    NAME                       ATTACHREQUIRED   PODINFOONMOUNT   MODES       AGE
    secrets-store.csi.k8s.io   false            true             Ephemeral   110m

The preceding output shows that the driver was deployed to the cluster. If the **secrets-store.csi.k8s.io** isn't found, then reinstall the driver.

If the files that the **SecretProviderClass** pulled in are larger than 4 mebibytes (MiB), then you might get **FailedMount** warnings. The message includes: **grpc: received message larger than max**. You can configure the driver to accept responses larger than 4 MiB. To accept larger responses, specify **\--max-call-recv-msg-size=size in bytes** to the Secrets Store Container in the **csi-secrets-store** daemonset.

**Note:** Replace **size in bytes** with the size that you want the driver to accept. Because larger responses can increase the memory resource consumption of the **secrets-store** container, you might need to increase your memory limit. If you still have issues, then review the log events in chronological order to see if any other failures occurred:
    
    
    kubectl get events -n kube-system --sort-by='.metadata.creationTimestamp'

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
