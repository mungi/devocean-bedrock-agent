Original URL: <https://repost.aws/knowledge-center/eks-node-status-ready>

# How can I change the status of my nodes from NotReady or Unknown status to Ready status?

My Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes are in NotReady or Unknown status. I want to get my worker nodes back in Ready status.

## Short description

You can't schedule pods on a node that's in **NotReady** or **Unknown** status. You can schedule pods only on a node that's in **Ready** status.

The following resolution addresses nodes in **NotReady** or **Unknown** status.

When your node is in the **MemoryPressure** , **DiskPressure** , or **PIDPressure** status, you must manage your resources to allow additional pods to be scheduled on the node.

If your node is in **NetworkUnavailable** status, then you must properly configure the network on the node. For more information, see [Node status](<https://kubernetes.io/docs/concepts/architecture/nodes/#node-status>) on the Kubernetes website.

**Note:** For information on how to manage pod evictions and resource limits, see [Node-pressure eviction](<https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/>) on the Kubernetes website.

## Resolution

### Check the aws-node and kube-proxy pods to see why the nodes are in NotReady status

A node in **NotReady** status isn't available for pods to be scheduled on.

To improve the security posture, the managed node group might remove the Container Network Interface (CNI) policy from the node role's Amazon Resource Name (ARN). This missing CNI policy causes the nodes to change to **NotReady** status. To resolve this issue, follow the [guidelines](<https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html#configure-cni-iam-eksctl>) to set up IAM Roles for Service Accounts (IRSA) for **aws-node** DaemonSet.

  1. To check the status of your **aws-node** and **kube-proxy** pods, run the following command:
    
        $ kubectl get pods -n kube-system -o wide

The output looks similar to the following:
    
        $ kubectl get pods -n kube-system -o wideNAME                             READY   STATUS    RESTARTS   AGE        IP              NODE
    aws-node-qvqr2                    1/1     Running   0          4h31m      192.168.54.115  ip-192-168-54-115.ec2.internal
    kube-proxy-292b4                  1/1     Running   0          4h31m      192.168.54.115  ip-192-168-54-115.ec2.internal

  2. Review the output. If your node status is normal, then your **aws-node** and **kube-proxy** pods are in **Running** status.  
If no **aws-node** or **kube-proxy** pods are listed, then skip to step 3. The **aws-node** and **kube-proxy** pods are managed by a DaemonSet. This means that each node in the cluster must have one **aws-node** and **kube-proxy** pod that runs on it. For more information, see [DaemonSet](<https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/>) on the Kubernetes website.

If either pod is in a status other than **Running** , then run the following command:
    
        $ kubectl describe pod yourPodName -n kube-system

To get additional information from the **aws-node** and **kube-proxy** pod logs, run the following command:
    
        $ kubectl logs yourPodName -n kube-system

The logs and the events from the **describe** output can show why the pods aren't in **Running** status. For a node to change to **Ready** status, both the **aws-node** and **kube-proxy** pods must be **Running** on that node.

  3. If the **aws-node** and **kube-proxy** pods don't appear in the command output, then run the following commands:
    
        $ kubectl describe daemonset aws-node -n kube-system
    $ kubectl describe daemonset kube-proxy -n kube-system

  4. Search the output for a reason why the pods can't be started:

**Note** : You can also search the [Amazon EKS control plane logs](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>) for information on why the pods can't be scheduled.

  5. Confirm that the versions of **aws-node** and **kube-proxy** are compatible with the cluster version based on [AWS guidelines](<https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html>). For example, run the following commands to check the pod versions:
    
        $ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2$ kubectl get daemonset kube-proxy --namespace kube-system -o=jsonpath='{$.spec.template.spec.containers[:1].image}'

**Note:** To update the **aws-node** version, see [Working with the Amazon VPC CNI plugin for Kubernetes Amazon EKS add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>). To update the **kube-proxy** version, follow step 4 in [Update the Kubernetes version for your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html#update-existing-cluster>).




In some scenarios, the node can be in **Unknown** status. This means that the **kubelet** on the node can't communicate the correct status of the node to the control plane.

To troubleshoot nodes in **Unknown** status, complete the steps in the following sections.

### Check the network configuration between nodes and the control plane

  1. Confirm that there aren't [network access control list (ACL) rules](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html>) on your subnets that block traffic between the Amazon EKS control plane and your worker nodes.

  2. Confirm that the security groups for your control plane and nodes comply with [minimum inbound and outbound requirements](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>).

  3. (Optional) If your nodes are configured to use a proxy, then confirm that the proxy allows traffic to the API server endpoints.

  4. To verify that the node has access to the API server, run the following netcat command from inside the worker node:
    
        $ nc -vz 9FCF4EA77D81408ED82517B9B7E60D52.yl4.eu-north-1.eks.amazonaws.com 443Connection to 9FCF4EA77D81408ED82517B9B7E60D52.yl4.eu-north-1.eks.amazonaws.com 443 port [tcp/https] succeeded!

**Note:** Replace **9FCF4EA77D81408ED82517B9B7E60D52.yl4.eu-north-1.eks.amazonaws.com** with your API server endpoint.

  5. Check that the route tables are configured to allow communication with the API server endpoint. This can be done through either an internet gateway or NAT gateway. If the cluster uses PrivateOnly networking, then verify that the VPC endpoints are configured correctly.




### Check the status of the kubelet

  1. Use SSH to connect to the affected worker node.

  2. To check the **kubelet** logs, run the following command:
    
        $ journalctl -u kubelet > kubelet.log

**Note:** The **kubelet.log** file contains information on **kubelet** operations that can help you find the root cause of the node status issue.

  3. If the logs don't provide information on the source of the issue, then run the following command. The command checks the status of the **kubelet** on the worker node:
    
        $ sudo systemctl status kubelet  kubelet.service - Kubernetes Kubelet
       Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: disabled)
      Drop-In: /etc/systemd/system/kubelet.service.d
               └─10-eksclt.al2.conf
       Active: inactive (dead) since Wed 2023-12-04 08:57:33 UTC; 40s ago

If the **kubelet** isn't in the **Running** status, then run the following command to restart the **kubelet** :
    
        $ sudo systemctl restart kubelet




### Confirm that the Amazon EC2 API endpoint is reachable

  1. Use SSH to connect to one of the worker nodes.
  2. To check if the Amazon Elastic Compute Cloud (Amazon EC2) API endpoint for your AWS Region is reachable, run the following command:
    
        $ nc -vz ec2.<region>.amazonaws.com 443Connection to ec2.us-east-1.amazonaws.com 443 port [tcp/https] succeeded!

**Note:** Replace **us-east-1** with the AWS Region where your worker node is located.



### Check the worker node instance profile and the ConfigMap

  1. Confirm that the worker node instance profile has the [recommended policies](<https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html>).
  2. Confirm that the worker node instance role is in the **aws-auth** ConfigMap. To check the ConfigMap, run the following command:
    
        $ kubectl get cm aws-auth -n kube-system -o yaml

The ConfigMap must have an entry for the worker node instance AWS Identity and Access Management (IAM) role. For example:
    
        apiVersion: v1kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: <ARN of instance role (not instance profile)>
          username: system:node:{{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
