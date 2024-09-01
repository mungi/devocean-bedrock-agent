Original URL: <https://repost.aws/knowledge-center/eks-pod-status-troubleshooting>

# How do I troubleshoot the pod status in Amazon EKS?

My Amazon Elastic Kubernetes Service (Amazon EKS) pods that are running on Amazon Elastic Compute Cloud (Amazon EC2) instances or on a managed node group are stuck. I want to get my pods in the "Running" or "Terminated" state.

## Resolution

**Important:** The following steps apply only to pods launched on Amazon EC2 instances or in a [managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html>). These steps don't apply to pods launched on [AWS Fargate](<https://docs.aws.amazon.com/eks/latest/userguide/fargate.html>).

### Find the status of your pod

To troubleshoot the pod status in Amazon EKS, complete the following steps:

  1. To get the status of your pod, run the following command:
    
        $ kubectl get pod

  2. To get information from the **Events** history of your pod, run the following command:
    
        $ kubectl describe pod YOUR_POD_NAME

  3. Based on the status of your pod, complete the steps in the following section.




### Your pod is in the Pending state

**Note:** The example commands in the following steps are in the default namespace. For other namespaces, append the command with -n YOURNAMESPACE.

Pods can be stuck in a **Pending** state because of insufficient resources or because you defined a **hostPort**. For more information, see [Pod phase](<https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase>) on the Kubernetes website.

If you have insufficient resources on the worker nodes, then delete unnecessary pods. You can also add more resources on the worker nodes. When you don't have enough resources in your cluster, use the [Kubernetes Cluster Autoscaler](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html>) to automatically scale your worker node group.

Insufficient CPU example:
    
    
    $ kubectl describe pod frontend-cpu
    Name:         frontend-cpu
    ...
    Status:       Pending
    ...
    Events:
      Type     Reason            Age                 From               Message
      ----     ------            ----                ----               -------
      Warning  FailedScheduling  22s (x14 over 13m)  default-scheduler  0/3 nodes are available: 3 Insufficient cpu.

Insufficient Memory example:
    
    
    $ kubectl describe pod frontend-memory
    Name:         frontend-memory
    ...
    Status:       Pending
    ...
    Events:
      Type     Reason            Age                 From               Message
      ----     ------            ----                ----               -------
      Warning  FailedScheduling  80s (x14 over 15m)  default-scheduler  0/3 nodes are available: 3 Insufficient memory.

If you defined a **hostPort** for your pod, then follow these best practices:

  * Because the **hostIP** , **hostPort** , and **protocol** combination must be unique, specify a **hostPort** only when it's necessary.
  * If you specify a **hostPort** , then schedule the same number of pods as there are worker nodes.



**Note:** When you bind a pod to a **hostPort** , there are a limited number of places that you can schedule a pod.

The following example shows the output of the **describe** command for a pod that's in the **Pending** state, **frontend-port-77f67cff67-2bv7w**. The pod is unscheduled because the requested host port isn't available for worker nodes in the cluster:
    
    
    $ kubectl describe pod frontend-port-77f67cff67-2bv7w
    Name:           frontend-port-77f67cff67-2bv7w
    ...
    Status:         Pending
    IP:
    IPs:            <none>
    Controlled By:  ReplicaSet/frontend-port-77f67cff67
    Containers:
      app:
        Image:      nginx
        Port:       80/TCP
        Host Port:  80/TCP
    ...
    Events:
      Type     Reason            Age                  From               Message
      ----     ------            ----                 ----               -------
      Warning  FailedScheduling  11s (x7 over 6m22s)  default-scheduler  0/3 nodes are available: 3 node(s) didn't have free ports for the requested pod ports.

If you can't schedule the pods because the nodes have taints that the pod doesn't allow, then the example output is similar to the following:
    
    
    $ kubectl describe pod nginx
    Name:         nginx
    ...
    Status:       Pending
    ...
    Events:
      Type     Reason            Age                  From               Message
      ----     ------            ----                 ----               -------
      Warning  FailedScheduling  8s (x10 over 9m22s)  default-scheduler  0/3 nodes are available: 3 node(s) had taint {key1: value1}, that the pod didn't tolerate.

To check your nodes taints, run the following command:
    
    
    $ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

To retain your node taints, specify a toleration for a pod in the **PodSpec**. For more information, see [Concepts](<https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts>) on the Kubernetes website. Or, append **-** to the end of the taint value to remove the node taint:
    
    
    $ kubectl taint nodes NODE_Name key1=value1:NoSchedule-

If your pods are still in the **Pending** state, then complete the steps in the **Additional troubleshooting** section.

### Your container is in the Waiting state

Your container might be in the **Waiting** state because of an incorrect Docker image or an incorrect repository name. Or, your pod might be in the **Waiting** state because the image doesn't exist or you lack permissions.

To confirm that the image and repository name are correct, log in to Docker Hub, Amazon Elastic Container Registry (Amazon ECR), or another container image repository. Compare the repository or image from the repository with the repository or image name that's specified in the pod specification. If the image doesn't exist or you lack permissions, then complete the following steps:

  1. Verify that the image that's specified is available in the repository and that the correct permissions are configured to allow you to pull the image.

  2. To confirm that you can pull the image and that there aren't general networking and repository permission issues, manually pull the image. You must use Docker to pull the image from the Amazon EKS worker nodes:
    
        $ docker pull yourImageURI:yourImageTag

  3. To verify that the image exists, check that both the image and tag are in either Docker Hub or Amazon ECR.




**Note:** If you use Amazon ECR, then verify that the repository policy allows image pull for the **NodeInstanceRole**. Or, verify that the [AmazonEC2ContainerRegistryReadOnly](<https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryReadOnly>) role is attached to the policy.  
The following example shows a pod in the **Pending** state with the container in the **Waiting** state because of an image pull error:
    
    
    $ kubectl describe po web-test
    
    Name:               web-test
    ...
    Status:             Pending
    IP:                 192.168.1.143
    Containers:
      web-test:
        Container ID:
        Image:          somerandomnonexistentimage
        Image ID:
        Port:           80/TCP
        Host Port:      0/TCP
        State:          Waiting
          Reason:       ErrImagePull
    ...
    Events:
      Type     Reason            Age                 From  Message
      ----     ------            ----                ----                                                 -------
      Normal   Scheduled         66s                 default-scheduler                                    Successfully assigned default/web-test to ip-192-168-6-51.us-east-2.compute.internal
      Normal   Pulling           14s (x3 over 65s)   kubelet, ip-192-168-6-51.us-east-2.compute.internal  Pulling image "somerandomnonexistentimage"
      Warning  Failed            14s (x3 over 55s)   kubelet, ip-192-168-6-51.us-east-2.compute.internal  Failed to pull image "somerandomnonexistentimage": rpc error: code = Unknown desc = Error response from daemon: pull access denied for somerandomnonexistentimage, repository does not exist or may require 'docker login'
      Warning  Failed            14s (x3 over 55s)   kubelet, ip-192-168-6-51.us-east-2.compute.internal  Error: ErrImagePull

If your containers are still in the **Waiting** state, then complete the steps in the **Additional troubleshooting** section.

### Your pod is in the CrashLoopBackOff state

If you receive the "Back-Off restarting failed container" output message, then your container might have exited soon after Kubernetes started the container.

To look for errors in the logs of the current pod, run the following command:
    
    
    $ kubectl logs YOUR_POD_NAME

To look for errors in the logs of the previous pod that crashed, run the following command:
    
    
    $ kubectl logs --previous YOUR-POD_NAME

For a multi-container pod, append the container name at the end. For example:
    
    
    $ kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER]

If the liveness probe doesn't return a **Successful** status, then verify that the liveness probe is correctly configured for the application. For more information, see [Configure probes](<https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes>) on the Kubernetes website.

The following example shows a pod in a **CrashLoopBackOff** state because the application exits after it starts:
    
    
    $ kubectl describe pod crash-app-b9cf4587-66ftw 
    Name:         crash-app-b9cf4587-66ftw
    ...
    Containers:
      alpine:
        Container ID:   containerd://a36709d9520db92d7f6d9ee02ab80125a384fee178f003ee0b0fcfec303c2e58
        Image:          alpine
        Image ID:       docker.io/library/alpine@sha256:e1c082e3d3c45cccac829840a25941e679c25d438cc8412c2fa221cf1a824e6a
        Port:           <none>
        Host Port:      <none>
        State:          Waiting
          Reason:       CrashLoopBackOff
        Last State:     Terminated
          Reason:       Completed
          Exit Code:    0
          Started:      Tue, 12 Oct 2021 12:26:21 +1100
          Finished:     Tue, 12 Oct 2021 12:26:21 +1100
        Ready:          False
        Restart Count:  4
        ...
    Events:
      Type     Reason     Age                  From               Message
      ----     ------     ----                 ----               -------
      Normal   Started    97s (x4 over 2m25s)  kubelet            Started container alpine
      Normal   Pulled     97s                  kubelet            Successfully pulled image "alpine" in 1.872870869s
      Warning  BackOff    69s (x7 over 2m21s)  kubelet            Back-off restarting failed container
      Normal   Pulling    55s (x5 over 2m30s)  kubelet            Pulling image "alpine"
      Normal   Pulled     53s                  kubelet            Successfully pulled image "alpine" in 1.858871422s

The following is an example of liveness probe that fails for the pod:
    
    
    $ kubectl describe pod nginx
    Name:         nginx
    ...
    Containers:
      nginx:
        Container ID:   containerd://950740197c425fa281c205a527a11867301b8ec7a0f2a12f5f49d8687a0ee911
        Image:          nginx
        Image ID:       docker.io/library/nginx@sha256:06e4235e95299b1d6d595c5ef4c41a9b12641f6683136c18394b858967cd1506
        Port:           80/TCP
        Host Port:      0/TCP
        State:
              Waiting      Reason:       CrashLoopBackOff
        Last State:     Terminated
          Reason:       Completed
          Exit Code:    0
          Started:      Tue, 12 Oct 2021 13:10:06 +1100
          Finished:     Tue, 12 Oct 2021 13:10:13 +1100
        Ready:          False
        Restart Count:  5
        Liveness:       http-get http://:8080/ delay=3s timeout=1s period=2s #success=1 #failure=3
        ...
    Events:
      Type     Reason     Age                    From               Message
      ----     ------     ----                   ----               -------
      Normal   Pulled     2m25s                  kubelet            Successfully pulled image "nginx" in 1.876232575s
      Warning  Unhealthy  2m17s (x9 over 2m41s)  kubelet            Liveness probe failed: Get "http://192.168.79.220:8080/": dial tcp 192.168.79.220:8080: connect: connection refused
      Normal   Killing    2m17s (x3 over 2m37s)  kubelet            Container nginx failed liveness probe, will be restarted
      Normal   Pulling    2m17s (x4 over 2m46s)  kubelet            Pulling image "nginx"

If your pods are still in the **CrashLoopBackOff** state, then complete the steps in the **Additional troubleshooting** section.

### Your pod is in the Terminating state

If your pods are stuck in a **Terminating** state, then check the health of the node where that pod is running and the finalizers. A finalizer is a function that performs termination processing before the pod transitions to **Terminated**. For more information, see [Finalizers](<https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/>) on the Kubernetes website. To check the finalizer for the terminating pod, run the following command:
    
    
    $ kubectl get po nginx -o yaml  
      
    apiVersion: v1  
    kind: Pod  
    metadata:  
    ...  
      finalizers:  
      - sample/do-something  
    ...

In the preceding example, the pod transitions to **Terminated** only after the finalizer **sample/do-something** is removed. Generally, a custom controller processes the finalizer and then removes it. The pod then transitions to the **Terminated** state.

To resolve this issue, check if the custom controller's pod correctly runs. Resolve any issues with the controller's pod, and let the custom controller complete the finalizer process. The pod then automatically transitions to the **Terminated** state. Or, run the following command to directly delete the finalizer:
    
    
    $ kubectl edit po nginx 

### Additional troubleshooting

If your pod is still stuck, then complete the following steps:

  1. To confirm that worker nodes are in the cluster and are in **Ready** status, run the following command:
    
        $ kubectl get nodes

If the nodes' status is **NotReady** , then see [How can I change the status of my nodes from NotReady or Unknown status to Ready status?](<https://repost.aws/knowledge-center/eks-node-status-ready>) If the nodes can't join the cluster, then see [How can I get my worker nodes to join my Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-worker-nodes-cluster>)

  2. To check the version of the Kubernetes cluster, run the following command:
    
        $ kubectl version --short

  3. To check the version of the Kubernetes worker node, run the following command:
    
        $ kubectl get node -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion

  4. Confirm that the Kubernetes server version for the cluster matches the version of the worker nodes within an acceptable version skew. For more information, see [Version skew policy](<https://kubernetes.io/releases/version-skew-policy/>) on the Kubernetes website.  
**Important:** The patch versions can be different between the cluster and worker node, such as v1.21.x for the cluster and v1.21.y for the worker node. If the cluster and worker node versions are incompatible, then use **eksctl** or AWS CloudFormation to [create a new node group](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html>). Or, use a compatible [Kubernetes version](<https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html>) to [create a new managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>), such as Kubernetes: v1.21, platform: eks.1 and above. Then, delete the node group that contains the incompatible Kubernetes version.

  5. Confirm that the Kubernetes control plane can communicate with the worker nodes. Check firewall rules against required rules in [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>). Then, verify that the nodes are in the **Ready** status.




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
