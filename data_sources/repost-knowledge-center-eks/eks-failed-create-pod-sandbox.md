Original URL: <https://repost.aws/knowledge-center/eks-failed-create-pod-sandbox>

# Why is my Amazon EKS pod stuck in the ContainerCreating state with the error "failed to create pod sandbox"?

My Amazon Elastic Kubernetes Service (Amazon EKS) pod is stuck in the ContainerCreating state with the error "failed to create pod sandbox".

## Resolution

You see this error when there's a networking issue or incorrect system resource limit configuration.

If you get this error and your pods are in the **ContainerCreating** state, then inspect the pod's status. Then, run the following command to get more details. Replace **podname** with the name of your pod:
    
    
     kubectl describe pod podname 

Based on the output, see the following sections for troubleshooting steps.

### "Resource temporarily unavailable" error response

Error: "Error response from daemon: failed to start shim: fork/exec /usr/bin/containerd-shim: resource temporarily unavailable: unknown"

This error response occurs when the defined kernel settings for maximum PID or maximum number of files causes an operating system limitation.

Example output:
    
    
    kubelet, ip-xx-xx-xx-xx.xx-xxxxx-x.compute.internal  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to start sandbox container for pod "example\_pod": Error response from daemon: failed to start shim: fork/exec /usr/bin/containerd-shim: resource temporarily unavailable: unknown

To temporarily resolve the issue, restart the node.

To troubleshoot the issue, complete the following tasks:

  * Gather the node logs.

  * Review the Docker logs for the **"dockerd[4597]: runtime/cgo: pthread_create failed: Resource temporarily unavailable"** error response.

  * Review the Kubelet log for the following error responses:

  * **"kubelet[5267]: runtime: failed to create new OS thread (have 2 already; errno=11)"**

  * **"kubelet[5267]: runtime: may need to increase max user processes (ulimit -u)"**.

  * Run the **ps** command to identify the zombie processes. All the processes that are listed with the **Z** state in the output are the zombie processes.




### "Network plugin cni failed to set up pod network" error response

Error: "Network plugin cni failed to set up pod network: add cmd: failed to assign an IP address to container"

This error response means that the Container Network Interface (CNI) can't assign an IP address to the newly created pod.

An instance that used the maximum allowed elastic network interfaces and IP addresses can cause this error response. You can also receive this error response when the Amazon Virtual Private Cloud (Amazon VPC) subnets have an IP address count of zero.

The following is an example of the maximum network interface IP addresses:
    
    
    Instance type    Maximum network interfaces    Private IPv4 addresses per interface    IPv6 addresses per interfacet3.medium        3                             6                                       6

In the preceding example, the **t3.medium** instance has a maximum of three network interfaces, and each network interface has a maximum of six IP addresses. The first IP address is used for the node, and you can't assign it. This network interface then has 17 IP addresses that it can allocate.

When the network interface runs out of IP addresses, the local IP Address Management daemon (ipamD) logs show the following message:

"ipamd/ipamd.go:1285","msg":"Total number of interfaces found: 3 ""AssignIPv4Address: IP address pool stats: total: 17, assigned 17" "AssignPodIPv4Address: ENI eni-abc123 does not have available addresses"

Example output:
    
    
    Warning FailedCreatePodSandBox 23m (x2203 over 113m) kubelet, ip-xx-xx-xx-xx.xx-xxxxx-x.compute.internal (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" network for pod "provisioning-XXXXXXXXXXXXXXX": networkPlugin cni failed to set up pod "provisioning-XXXXXXXXXXXXXXX" network: add cmd: failed to assign an IP address to container

Review the subnet to determine whether the subnet ran out of free IP addresses. You can view available IP addresses for each subnet in the [Amazon VPC console](<https://console.aws.amazon.com/vpc/>) under the **Subnets** section.
    
    
    Subnet: XXXXXXXXXXIPv4 CIDR Block 10.2.1.0/24   Number of allocated ips 254   Free address count 0

To resolve this issue, use the following solutions:

  * Scale down workload to free up used IP addresses.
  * Scale-up the node count if more IP addresses are available in the subnet.
  * Use [custom networking](<https://docs.aws.amazon.com/eks/latest/userguide/cni-custom-network.html>) for pods.
  * Turn on [prefix delegation](<https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html>) mode. For more information, see [Prefix mode for Windows](<https://github.com/aws/aws-eks-best-practices/blob/master/content/networking/prefix-mode/index_windows.md#replace-all-nodes-during-migration-from-secondary-ip-mode-to-prefix-delegation-mode-or-vice-versa>) on the GitHub website.



### "Error while dialing" error response

Error: "Error while dialing dial tcp 127.0.0.1:50051: connect: connection refused"

This error indicates that the **aws-node** pod failed to communicate with IPAM because the **aws-node** pod failed to run on the node.

To troubleshoot this issue, make sure that you're running the [correct version of the VPC CNI plugin](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>) for the cluster version.

The pods might be in **Pending** state because of Liveness and Readiness probe errors. Be sure that you have the latest VPC CNI add-on version.

The issue might also occur because the **Dockershim** (up to EKS version 1.23) mount point fails to mount. The following example message indicates that the pod didn't mount **var/run/dockershim.sock** :
    
    
    Getting running pod sandboxes from \"unix:///var/run/dockershim.sock\Not able to get local pod sandboxes yet (attempt 1/5): rpc error: code = Unavailable desc = all SubConns are in TransientFailure, latest connection error: connection error: desc = "transport: Error while dialing dial unix /var/run/dockershim.sock: connect: no such file or director

To resolve this issue, complete the following tasks:

  * Restart the **aws-node** pod to remap the mount point.
  * Cordon the node, and scale the nodes in the node group.
  * Upgrade the Amazon VPC network interface to the latest cluster version that's supported.



If you added the CNI as a managed plugin in the AWS Management Console, then the **aws-node** fails the probes. Managed plugins overwrite the service account. However, the service account isn't configured with the selected role. To resolve this issue, turn off the plugin from the AWS Management Console, and create the service account with a manifest file. Or, edit the current **aws-node** service account to add the role that's used on the managed add-on.

### "Pod does not have label" error response

Errors "Failed to parse Kubernetes args: pod does not have label vpc.amazonaws.com/PrivateIPv4Address" or "Pod does not have label vpc.amazonaws.com/PrivateIPv4Address"

This issue occurs when a pod doesn't have a scheduled **nodeSelector** on a windows node.

To resolve the issue, make sure to include the following labels in the **PodSpec** for the **nodeSelector** :

**kubernetes.io/os:** windows 

**kubernetes.io/arch** : amd64

### Security group error

Error: Plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container  
Vpc-resource-controller failed to allocate branch ENI to pod: creating network interface, NoCredentialProviders: no valid providers in chain. Deprecated."

This error response can indicate an issue with the **health.kubernetes** control plane. To resolve this issue, [contact AWS Support](<https://console.aws.amazon.com/support/home#/case/create?issueType=technical>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
