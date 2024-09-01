Original URL: <https://repost.aws/knowledge-center/eks-liveness-readiness-probe>

# How do I troubleshoot liveness and readiness probe issues with my Amazon EKS clusters?

I want to troubleshoot issues related to liveness and readiness probes in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

Kubelets that are running on the worker nodes use probes to [check pod status periodically](<https://github.com/kubernetes/kubernetes/blob/f356ae4ad977bc9bf2baf3e90451f9b74a9dbba9/pkg/kubelet/prober/prober.go>). Kubernetes currently supports three states in probes: success, failure and unknown. Kubelet considers the pod as successful or healthy under the following conditions:

  * The application running inside the container is ready.
  * The application accepts traffic and responds to probes that are defined on the pod manifest.



Kubelet considers an application pod as failed or unhealthy when the probe doesn't respond. Kubelet then marks this pod as unhealthy and sends SIGTERM to the pod. Either of the following happen based on the lifecycle policy and restartPolicy that are defined on the deployment:

  * The pod is terminated immediately.
  * The pod is shut down gracefully after it stops to accept traffic.



Example:
    
    
    spec:
     containers:
     - name: "example-container"
      image: "example-image"
      lifecycle:
       preStop:
        exec:
         command: ["sh", "-c", "sleep 10"]

In this example, if **example-container** that runs inside **example-pod** becomes unhealthy by not responding to probes, then the pod stops accepting traffic in 10 seconds. Then, kubelet shuts down the pod gracefully. If the pod isn't terminated even after 30 seconds, kubelet forcefully removes the pod. Kubelet considers the application pod as unknown when kubelet can't determine the status of the pod using probes that are defined on the deployment manifest. In this case, kubelet performs additional checks to determine the pod status.

Kubernetes provides probe checks on liveness probe, readiness probe, and startup probe.

  * Kubelet uses liveness probes to know the state of the application that's running inside your pod.
  * Kubelet uses readiness probes to know when your application is ready to start serving the incoming traffic.
  * Kubelet uses startup probes for slow-starting applications inside the pod. When a startup probe is configured, liveness and readiness probes don't check the pod until startup is considered successful.



If none of these probes are defined on the pod manifest, kubelet indefinitely marks the pods as successful or healthy. You can configure one of the following probes to check pod health:

  * HTTP probe
  * Command probe
  * TCP socket probe
  * gRPC probe



## Resolution

### Application healthcheck fail errors due to client timeouts

When your liveness or readiness probes fail, you get the following error messages:
    
    
    Liveness probe failed: Get "http://podIP:8080/health ": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
    
    Readiness probe failed: Get "http://podIP:8080/health ": context deadline exceeded (Client.Timeout exceeded while awaiting headers)

To troubleshoot these errors, do the following:

Check whether you configured the liveness and readiness probes for the application pods correctly.

If you're using the Amazon Virtual Private Cloud (Amazon VPC) CNI version 1.11.0 or later, then be sure that **POD_SECURITY_GROUP_ENFORCING_MODE** is set to **standard** in the **aws-node DaemonSet**. If this setting is incorrect, run the following command:
    
    
    kubectl set env daemonset aws-node -n kube-system POD_SECURITY_GROUP_ENFORCING_MODE=standard

Be sure to set **DISABLE_TCP_EARLY_DEMUX** to **true** for **amazon-k8s-cni-init** that's the container under **initcontainers** when the following conditions are true:

  * You're using an Amazon VPC CNI version that's earlier than version 1.11.0.
  * Your pods are configured with security groups.
  * ENABLE_POD_ENI is set to true.


    
    
    kubectl patch daemonset aws-node -n kube-system \
    -p '{"spec": {"template": {"spec": {"initContainers": [{"env":[{"name":"DISABLE_TCP_EARLY_DEMUX","value":"true"}],"name":"aws-vpc-cni-init"}]}}}}'

### Amazon VPC CNI failure errors

Your aws-node DaemonSet might fail with the following errors:
    
    
    Liveness probe failed: OCI runtime exec failed: exec failed: container_linux.go:380: starting container process caused: read init-p: connection reset by peer: unknown
    Warning  Unhealthy  11m (x3 over 12m)    kubelet            Liveness probe failed:
    Normal   Killing    11m                  kubelet            Container aws-node failed liveness probe, will be restarted
    
    Readiness probe failed: OCI runtime exec failed: exec failed: container_linux.go:380: starting container process caused: process_linux.go:99: starting setns process caused: fork/exec /proc/self/exe: resource temporarily unavailable: unknown
    Warning  Unhealthy  11m (x9 over 13m)    kubelet            Readiness probe failed:

You can resolve these errors by increasing the value of [timeoutSeconds](<https://github.com/aws/amazon-vpc-cni-k8s/blob/master/charts/aws-vpc-cni/templates/daemonset.yaml#L70>) to 60 seconds on the aws-node DaemonSet.

To view the current values of fields in the VPC CNI, run the following command:
    
    
    $kubectl get daemonset aws-node -n kube-system -o yaml

The output looks similar to the following:
    
    
    "livenessProbe":
              exec:
                command:
                - /app/grpc-health-probe
                -addr=:50051
                -connect-timeout=5s
                -rpc-timeout=5s
              failureThreshold: 3
              initialDelaySeconds: 60
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 60

### Application connection errors

When you run the **describe** command on custom application pods, you get the following errors if the pods fail the liveness and readiness probe checks:
    
    
    2m 25s Warning  Unhealthy  Liveness probe failed: Get "http://podIP:8081/health ": dial tcp 192.168.187.28: 8081: connect: connection refused
    
    2m 25s Warning  Unhealthy   Readiness probe failed: Get "http:// podIP:8081/health": dial tcp 192.168.187.28:8081: connect: connection refused
    
    Warning  Unhealthy  39s (x4 over 2m19s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
    
    Warning  Unhealthy  29s (x5 over 2m19s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 500

To troubleshoot this error, do the following:

1\. Manually curl the health check path that's defined on the pod manifest from the worker node.
    
    
    [ec2-user@ip-10-0-0-11 ~]$ curl -ikv podIP:8081/health

2\. Exec into the application pod that fails the liveness or readiness probes. Then, curl the health check path that's defined on the pod manifest:
    
    
    local@bastion-host ~ % kubectl exec <pod-name> -- curl  -ikv "http://localhost:8081/_cluster/health?"

3\. Check the kubelet logs of the worker node where the pod is running for any errors:
    
    
    [ec2-user@ip-10-0-0-11 ~]$ journalctl -u kubelet //optionally 'grep' with pod name

4\. Run the **describe pod** command on the pod and check the current status for the containers that are running in the pod. Also, check the pod logs:
    
    
    $ kubectl describe pod <pod name> -n <namespace>
    
    $ kubectl logs <pod name>

5\. If you still don't have information on the error, then consider increasing the verbosity of the underlying kubelet that's running on the worker node:
    
    
    $ sudo systemctl status kubelet
    $ vi /etc/systemd/system/kubelet.service.d/10-kubelet-args.conf 
       [Service]
       Environment='KUBELET_ARGS=--node-ip=192.168.31.211 --pod-infra-container-image=602401143452.dkr.ecr.us-east-2.amazonaws.com/eks/pause:3.5 --v=2'

In the configuration file, change **\--v=2** to **\--v=9** , and then save the file.

Restart the kubelet for the changes to take effect:
    
    
    $ sudo systemctl daemon-reload && sudo systemctl restart kubelet && sudo systemctl enable kubelet

Run the following command to check the verbosity of the kubelet:
    
    
    $ systemctl status kubelet -l

The output must look like the following:
    
    
    CGroup: /system.slice/kubelet.service 
           └─5909 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.0.0.11 --pod-infra-container-image=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/pause:3.1-eksbuild.1 --v=9

Restart the pod that fails with liveness or readiness checks. Then, make sure that this pod is being deployed on the Amazon EKS worker node where the preceding changes were made. You can check the kubelet logs by running the following command:
    
    
    $ journalctl -u kubelet //optionally 'grep' with pod name

6\. Run the same container image on bastion host and check whether you can curl the health check path that's defined on the probes in manifest. Also, check the container logs.

7\. For HTTP probes, check if the custom http header is configured correctly. Kubelet uses the golang code that's equivalent of curl to HTTP test your pod.

Example:
    
    
    "livenessProbe":
       httpGet:
            path: /healthz
            port: 8080
            httpHeaders:
            - name: Custom-Header
              value: Awesome
          initialDelaySeconds: 3
          periodSeconds: 3

8\. If you're using an **exec** probe, check whether your pod is configured correctly. In the following example, the pod passes for 30 seconds, and then fails:
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        test: liveness
      name: liveness-exec
    spec:
      containers:
      - name: liveness
        image: registry.k8s.io/busybox
        args:
        - /bin/sh
        - -c
        - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
        livenessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 5
          periodSeconds: 5

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
