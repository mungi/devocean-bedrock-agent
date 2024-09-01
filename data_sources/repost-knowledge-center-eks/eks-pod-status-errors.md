Original URL: <https://repost.aws/knowledge-center/eks-pod-status-errors>

# How can I troubleshoot the pod status ErrImagePull and ImagePullBackoff errors in Amazon EKS?

My Amazon Elastic Kubernetes Service (Amazon EKS) pod status is in the ErrImagePull or ImagePullBackoff status.

## Short description

If you run the [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>) command **get pods** and your pods are in the **ImagePullBackOff** status, then the pods aren't running correctly. The **ImagePullBackOff** status means that a container didn't start because an image couldn't be retrieved or pulled. To troubleshoot this issue, use the following resolutions.

For more information, see [Amazon EKS connector Pods are in ImagePullBackOff state](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting-connector.html#symp-img>).

## Resolution

### Confirm the image information

Use the following steps to confirm that the pod status error message, and verify that the image name, tag, and Secure Hash Algorithm (SHA) are correct:

  1. To get pod status, run the following command:
    
        $ kubectl get pods -n defaultNAME                              READY   STATUS             RESTARTS   AGE
    nginx-7cdbb5f49f-2p6p2            0/1     ImagePullBackOff   0          86s

  2. To get pod failure details, run the following command:
    
        $ kubectl describe pod nginx-7cdbb5f49f-2p6p2
    ...
    Events:
      Type     Reason     Age                   From               Message
      ----     ------     ----                  ----               -------
      Normal   Scheduled  4m23s                 default-scheduler  Successfully assigned default/nginx-7cdbb5f49f-2p6p2 to ip-192-168-149-143.us-east-2.compute.internal
      Normal   Pulling    2m44s (x4 over 4m9s)  kubelet            Pulling image "nginxx:latest"
      Warning  Failed     2m43s (x4 over 4m9s)  kubelet            Failed to pull image "nginxx:latest": rpc error: code = Unknown desc = Error response from daemon: pull access denied for nginxx, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
      Warning  Failed     2m43s (x4 over 4m9s)  kubelet            Error: ErrImagePull
      Warning  Failed     2m32s (x6 over 4m8s)  kubelet            Error: ImagePullBackOff
      Normal   BackOff    2m17s (x7 over 4m8s)  kubelet            Back-off pulling image "nginxx:latest"

  3. Confirm that your image tag and name exist and are correct.

  4. If the image registry requires authentication, then confirm that you are authorized to access it. To verify that the image used in the pod is correct, run the following command:
    
        $ kubectl get pods nginx-7cdbb5f49f-2p6p2  -o jsonpath="{.spec.containers[*].image}" | \sort
    nginx:latest




To understand the pod status values, see [Pod phase](<https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase>) on the Kubernetes website and [How do I troubleshoot the pod status in Amazon EKS?](<https://repost.aws/knowledge-center/eks-pod-status-troubleshooting>)

### Troubleshoot private registries

If you retrieve images from private registry with Amazon EKS, then additional configuration might be needed. Use **imagePullSecrets** on workload manifest to specify the credentials. These credentials authenticate with the private registry. This allows the pod to pull images from the specified private repository.

To view the contents of the Secret, use the following command to view it in YAML:
    
    
    kubectl get secret <secret_name> --output=yaml

In the following example, a pod needs access to your Docker registry credentials in **regcred** :
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: private-reg
    spec:
      containers:
      - name: private-reg-container
        image: your-private-image
      imagePullSecrets:
      - name: regcred

Replace **your-private-image** with the path to an image in a private registry similar to the following:
    
    
    your.private.registry.example.com/bob/bob-private:v1

To pull the image from the private registry, Kubernetes requires the credentials. The **imagePullSecrets** field in the configuration file specifies that Kubernetes must get the credentials from a Secret named **regcred**.

For more information, see [Pull an Image from a Private Registry](<https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/>) on the Kubernetes website.

### Troubleshoot additional registry issues

**Failed to pull image issue**

The error "Failed to pull image..." means that kubelet tried to connect to the private registry endpoint and failed due to a connection timeout.

In the following example, the registry is inaccessible because **kubelet** isn't able to reach the private registry endpoint:
    
    
    $ kubectl describe pods nginx-9cc69448d-vgm4m
    ...
    Events:
      Type     Reason     Age                From               Message
      ----     ------     ----               ----               -------
      Normal   Scheduled  16m                default-scheduler  Successfully assigned default/nginx-9cc69448d-vgm4m to ip-192-168-149-143.us-east-2.compute.internal
      Normal   Pulling    15m (x3 over 16m)  kubelet            Pulling image "nginx:stable"
      Warning  Failed     15m (x3 over 16m)  kubelet            Failed to pull image "nginx:stable": rpc error: code = Unknown desc = Error response from daemon: Get "https://registry-1.docker.io/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
      Warning  Failed     15m (x3 over 16m)  kubelet            Error: ErrImagePull
      Normal   BackOff    14m (x4 over 16m)  kubelet            Back-off pulling image "nginx:stable"
      Warning  Failed     14m (x4 over 16m)  kubelet            Error: ImagePullBackOff

To troubleshoot this error, check your subnet, security groups, and network ACL that allow communication to the registry endpoint.

**Registry rate limit exceeded**

In the following example, the registry rate limit has been exceeded:
    
    
    $ kubectl describe pod nginx-6bf9f7cf5d-22q48
    ...
    Events:
      Type     Reason                  Age                   From               Message
      ----     ------                  ----                  ----               -------
      Normal   Scheduled               3m54s                 default-scheduler  Successfully assigned default/nginx-6bf9f7cf5d-22q48 to ip-192-168-153-54.us-east-2.compute.internal
      Warning  FailedCreatePodSandBox  3m33s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "82065dea585e8428eaf9df89936653b5ef12b53bef7f83baddb22edc59cd562a" network for pod "nginx-6bf9f7cf5d-22q48": networkPlugin cni failed to set up pod "nginx-6bf9f7cf5d-22q48_default" network: add cmd: failed to assign an IP address to container
      Warning  FailedCreatePodSandBox  2m53s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "20f2e27ba6d813ffc754a12a1444aa20d552cc9d665f4fe5506b02a4fb53db36" network for pod "nginx-6bf9f7cf5d-22q48": networkPlugin cni failed to set up pod "nginx-6bf9f7cf5d-22q48_default" network: add cmd: failed to assign an IP address to container
      Warning  FailedCreatePodSandBox  2m35s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "d9b7e98187e84fed907ff882279bf16223bf5ed0176b03dff3b860ca9a7d5e03" network for pod "nginx-6bf9f7cf5d-22q48": networkPlugin cni failed to set up pod "nginx-6bf9f7cf5d-22q48_default" network: add cmd: failed to assign an IP address to container
      Warning  FailedCreatePodSandBox  2m                    kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "c02c8b65d7d49c94aadd396cb57031d6df5e718ab629237cdea63d2185dbbfb0" network for pod "nginx-6bf9f7cf5d-22q48": networkPlugin cni failed to set up pod "nginx-6bf9f7cf5d-22q48_default" network: add cmd: failed to assign an IP address to container
      Normal   SandboxChanged          119s (x4 over 3m13s)  kubelet            Pod sandbox changed, it will be killed and re-created.
      Normal   Pulling                 56s (x3 over 99s)     kubelet            Pulling image "httpd:latest"
      Warning  Failed                  56s (x3 over 99s)     kubelet            Failed to pull image "httpd:latest": rpc error: code = Unknown desc = Error response from daemon: toomanyrequests: You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limit
      Warning  Failed                  56s (x3 over 99s)     kubelet            Error: ErrImagePull
      Normal   BackOff                 43s (x4 over 98s)     kubelet            Back-off pulling image "httpd:latest"

If you try to pull an image from the public Docker Hub repository after you reach the pull rate limit, then you are stopped. For more information, see [Docker Hub rate limit](<https://docs.docker.com/docker-hub/download-rate-limit/>) on the Docker Hub website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
