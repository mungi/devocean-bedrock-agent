Original URL: <https://repost.aws/knowledge-center/eks-worker-node-not-ready>

# How do I troubleshoot my Amazon EKS worker node that's going into NotReady status due to PLEG issues?

My Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes go into NotReady or Unknown Status because the Pod Lifecycle Event Generator (PLEG) isn't healthy.

## Resolution

When the worker nodes in your Amazon EKS cluster go into the **NotReady** or **Unknown** status, then workloads that are scheduled on that node are disrupted. To troubleshoot this issue, do the following:

Get information on the worker node by running the following command:
    
    
    $ kubectl describe node node-name

In the output, check the **Conditions** section to find the cause for the issue.

Example:
    
    
    KubeletNotReady  PLEG is not healthy: pleg was last seen active xx

The most common reasons for PLEG being unhealthy are the following:

  * Kubelet can't communicate with Docker daemon because the daemon is busy or dead. For example, the Docker daemon on your EKS worker node might be broken.
  * An out of memory (OOM) or CPU utilization issue at instance level caused PLEG to become unhealthy.
  * If the worker node has a large number of pods, the kubelet and Docker daemon might experience higher workloads, causing PLEG related errors. Higher workloads might also result if the liveness or readiness probes frequently.



### Check the kubelet logs

You can check the kubelet logs on the instance to identify why PLEG is unhealthy.

1\. Use SSH to connect to the instance and run the following command:
    
    
    $ journalctl -u kubelet > kubelet.log

If you're using the Amazon EKS-optimized AMI and SSH isn't enabled, then you can connect using SSM. For more information, see [Connect to your Linux instance using Session Manager](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/session-manager.html>).

2\. Check for PLEG related events posted by kubelet in these logs:

Example:
    
    
    28317 kubelet.go:1873] "Skipping pod synchronization" err="PLEG is not healthy: pleg was last seen active 4h5m43.659028227s ago; threshold is 3m0s"
    28317 kubelet.go:1873] "Skipping pod synchronization" err="PLEG is not healthy: pleg was last seen active 4h5m48.659213288s ago; threshold is 3m0s"

3\. Check the kubelet logs to see if there are any pods that are failing readiness and liveness probes. These log messages look similar to the following:
    
    
    "Probe failed" probeType="Liveness" pod="nginx/bus" podUID=2527afb7-b32c-4c84-97e2-246eb48c97a9 containerName="nginx" probeResult=failure output="Get \"http://192.168.154.18:15020/app-health/livez\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)"

Use these logs to identify the pods that are failing. For the pods that are identified, check and make sure that the health probes are configured correctly.

### Monitor the worker node resource usage

Check if there is any instance level issue, such as a resource crunch due to OOM issues or high CPU utilization.

Monitor the CPU Utilization metric for the underlying Amazon Elastic Compute Cloud (Amazon EC2) worker node. Check this metric to see if there are any sudden spikes or if the CPU utilization reaches 100%.

Kubelet reports that the node is under pressure when the node meets hard or soft eviction thresholds irrespective of configured grace periods. You can check the node condition by running the following command:
    
    
    $ kubectl describe node <node_name>

Check whether node condition is indicated as **MemoryPressure** in the output. In these cases, the instance might stall due to resource unavailability. This might result in the process becoming unresponsive.

To mitigate issues due to resource crunch, it's a best practice to set CPU and memory utilization limits for your pods.

When you specify a resource limit for your container, kubelet enforces these limits. The usage of the running container isn't allowed to exceed these limits. This prevents the pod from taking up more memory than needed, thereby preventing OOM issues. For more information, see [Resource Management for pods and containers](<https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/>) on the Kubernetes website.

Also, consider using Container Insights to collect, aggregate, and summarize metrics and logs from your containerized applications and microservices. For more information, see [Amazon EKS and Kubernetes Container Insights metrics](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-EKS.html>). You can use **node_cpu_utilization** and **node_memory_utilization** to monitor resource utilization at node level. You can also set alarms to get notified when a certain threshold is reached.

### Monitor the root Amazon EBS volume performance

PLEG might be unhealthy due to disk issues in your Amazon Elastic Block Store (Amazon EBS) volume. In this case, the kubelet logs look similar to the following:
    
    
    fs: disk usage and inodes count on following dirs took 1.262610491s: [/var/lib/docker/overlay2/709e904d843733d746e5134e55e3c6553db4c0f5297d5e3c3a86c206bcb6b172/diff /var/lib/docker/containers/158725d2d97578713034c5f5c16291a068349b7e989b417324c142bb584f79ad]; will not log again for this container unless duration exceeds 2s

This happens when your applications that are using the pods on the instance perform intensive I/O operations against the disk.

You can monitor the IOPS utilization and throughput of your Amazon EBS volume using the [Amazon CloudWatch metrics for Amazon EBS](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using_cloudwatch_ebs.html>).

Use the following CloudWatch metrics to monitor the throughput and IOPS of an Amazon EBS volume:

  * VolumeReadOps
  * VolumeWriteOps
  * VolumeReadBytes



For example, you can calculate the average IOPS in ops/s using the following formula:

((VolumeReadOps) + (VolumeWriteOps)) / (Period)

You can calculate the average throughput in bytes/s using the following formula:

((VolumeReadBytes) + (VolumeWriteBytes)) / (Period)

For more information, see [How can I use CloudWatch metrics to calculate the average throughput and average number of IOPS my EBS volume is providing?](<https://repost.aws/knowledge-center/ebs-cloudwatch-metrics-throughput-iops>)

To resolve this issue, consider increasing the disk size or changing the EBS volume type for achieving a better I/O throughput.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
