Original URL: <https://repost.aws/knowledge-center/eks-resolve-pending-fargate-pods>

# How can I troubleshoot Amazon EKS pods on AWS Fargate that are stuck in a Pending state?

My Amazon Elastic Kubernetes Service (Amazon EKS) pods that run on AWS Fargate instances are stuck in a Pending state.

## Short description

There are several reasons that your Amazon EKS pods that use AWS Fargate can be stuck in the **Pending** state:

  * Because a particular [vCPU and memory combination](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory>) is unavailable, there's a capacity error.
  * You created the CoreDNS pods with a default annotation that maps them to the Amazon Elastic Compute Cloud (Amazon EC2) compute type. To schedule them on a Fargate node, remove the Amazon EC2 compute type.
  * When you created the pod and assigned it to the **fargate-scheduler** , the pod didn't match any Fargate profiles. If a pod isn't matched when it's created, then it isn't automatically rescheduled to Fargate nodes. This is true even if you create a profile that matches later. In this case, the pod is assigned to the **default-scheduler**.
  * If the pod is assigned to the **fargate-scheduler** but remains in a **Pending** state, then the pod might require additional troubleshooting.



## Resolution

**Prerequisites**

  * Configure the namespace and (optionally) specify Kubernetes labels to match the labels for your pod selectors. Fargate workflow matches pods to a Fargate profile only if both conditions match the pod specification.
  * If you specify multiple pod selectors within a single Fargate profile, then **fargate-scheduler** schedules the pod if it matches any of the selectors.
  * If a pod specification matches with multiple Fargate profiles, then the pod is scheduled according to a random Fargate profile. To avoid this, use the annotation **eks.amazonaws.com/fargate-profile:fp_name** within the pod specification. Replace **fp_name** with your Fargate profile name.



**Important** : The following steps apply only to pods that are launched with AWS Fargate. For information on pods launched on Amazon EC2 instances, see [How can I troubleshoot the pod status in Amazon EKS?](<https://repost.aws/knowledge-center/eks-pod-status-troubleshooting>)

### Find out the status of your pod

1\. To check your pod state, run the following command:
    
    
    kubectl get pods -n <namespace>

2\. To get more error information about your pod, run the following **describe** command:
    
    
    kubectl describe pod YOUR\_POD\_NAME -n <namespace>

Refer to the output of the **describe** command to evaluate the resolution steps to complete.

### Resolve a capacity error

If your pods have a capacity issue, then the **describe** output is similar to the following message:

"Fargate capacity is unavailable at this time. Please try again later or in a different availability zone."

This means that Fargate can't provision compute capacity based on the vCPU and memory combination that you selected.

To resolve the error, complete the following steps:

  * Try to create the pod again after 20 minutes. Because the error is capacity-based, the exact amount of time can vary.
  * Change the request (CPU and memory) within your pod specification. For information on pod specification, see [How Kubernetes applies resource requests and limits](<https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#how-pods-with-resource-limits-are-run>) on the Kubernetes website. The Fargate workflow then provisions a new combination of vCPU and memory.  
**Note:** You're billed based on one of your combinations. For more information on how the combination is completed based on your pod specification, see [Pod CPU and memory](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory>). Perform a **kubectl describe node** command from your terminal or Integrated Development Environment (IDE) to get a higher vCPU and memory combination value. Fargate doesn't always have available capacity based on your requests. Fargate provisions resources from a capacity pool on a best effort basis. You're billed only for pod usage and equivalent vCPU and memory combination.



### Resolve CoreDNS pods in a Pending state

If CoreDNS pods are in a **Pending** state, then your output is similar to the following message:
    
    
    kubectl get pods -n kube-system
    NAME                                     READY   STATUS     RESTARTS      AGE
    coredns-6548845887-qk9vf                 0/1     Pending    0             157m

This might be because the default annotation of CoreDNS deployment is the following: **eks.amazonaws.com/compute-type : ec2**.

To resolve this and re-assign the pods to the Fargate scheduler, see [Update CoreDNS](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns>).

### Troubleshoot pods that are assigned to fargate-scheduler

There are multiple reasons why pods assigned to **fargate-scheduler** might be stuck in **Pending** state. If your pods remain in a **Pending** state, then the **describe** output is similar to the following message:
    
    
    Events:
    Type       Reason              Age                     From
    ----       ------              ----                    ----
    Warning    FailedScheduling    2m25s (x301 over 5h3m)  fargate-scheduler

To resolve this error, complete the following tasks:

  * Delete and recreate the pods.
  * Confirm the following specifications aren't set in the pod specification YAML. The specification can cause the **fargate-scheduler** to skip the pod:  
**node selector**  
<>node name  
**schedulerName**
  * Confirm that the subnets selected in your Fargate profile have enough free IP addresses to create new pods. Each Fargate node consumes one IP address from the subnet.
  * Confirm that the NAT gateway is set to a public subnet, and has an Elastic IP address attached to it.
  * Confirm that the DHCP option sets associated with your virtual private cloud (VPC) have an AmazonProvidedDNS or a valid DNS server hostname for **domain-name-servers**.
  * Confirm that DNS hostnames and DNS resolution are [turned on](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-updating>) for your VPC.
  * If your Fargate pods use private subnets with only VPC endpoints configured for service communication, then allow these endpoints with DNS names:  
**ECR - API**  
**ECR - DKR**  
**S3 Gateway endpoint**
  * Confirm the security group that's attached to the VPC endpoint allows communication from Fargate to and from the API server. The VPC endpoint security group must allow port 443 ingress from the cluster VPC CIDR. You must also turn on [private endpoint access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#modify-endpoint-access>) for your cluster.



### Resolving pods assigned to default-scheduler

To determine the scheduler that your pods are assigned to, run the following command:
    
    
    kubectl get pods -o yaml -n <namespace> <pod-name> | grep schedulerName.

In the output, confirm that the **schedulerName** is **fargate-scheduler**. If it's listed as **default-scheduler** , then the fargate-scheduler skipped this pod. To troubleshoot this issue, check your pod configuration for compute-type annotations. For more information, see [AWS Fargate considerations](<https://docs.aws.amazon.com/eks/latest/userguide/fargate.html#fargate-considerations>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
