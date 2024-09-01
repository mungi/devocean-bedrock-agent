Original URL: <https://repost.aws/knowledge-center/amazon-eks-troubleshoot-autoscaler>

# How do I troubleshoot issues when setting up Cluster Autoscaler on an Amazon EKS cluster?

I want to troubleshoot issues when launching Cluster Autoscaler on my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

Make sure that you verify the following before you start:

  * You installed or updated [eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>) to the latest version.
  * You replaced the placeholder values in code snippets with your own values.



**Note:** The **\--region** variable isn't always used in the commands because the default value for your AWS Region is used. Check the default value by running the [AWS Command Line Interface (AWS CLI) configure](<https://docs.aws.amazon.com/cli/latest/reference/configure/>) command. If you need to change the AWS Region, then use the **\--region** flag.

**Note:** If you receive errors when running AWS CLI commands, then [confirm that you're running a recent version of the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

## Resolution

### Cluster Autoscaler pod is in a CrashLoopBackOff status

Check the Cluster Autoscaler pod status by running the following command:
    
    
    kubectl get pods -n kube-system | grep cluster-autoscaler

The following is an example of a Cluster Autoscaler pod that's in a **CrashLoopBackOff** status:
    
    
    NAME                            READY   STATUS             RESTARTS      AGE
    cluster-autoscaler-xxxx-xxxxx   0/1     CrashLoopBackOff   3 (20s ago)   99s

View the Cluster Autoscaler pod logs by running the following command:
    
    
    kubectl logs -f -n kube-system -l app=cluster-autoscaler

If the logs indicate that there are AWS Identity and Access Management (IAM) permissions issues, then do the following:

  * Check that an OIDC provider is associated with the Amazon EKS cluster.
  * Check that the Cluster Autoscaler service account is annotated with the IAM role.
  * Check that the correct IAM policy is attached to the preceding IAM role.
  * Check that the trust relationship is configured correctly.



**Note:** The following is an example of a log indicating IAM permissions issues:
    
    
    Failed to create AWS Manager: cannot autodiscover ASGs: AccessDenied: User: xxx is not authorized to perform: autoscaling: DescribeTags because no identity-based policy allows the autoscaling:DescribeTags action status code: 403, request id: xxxxxxxx

**Important:** Make sure to check all given AWS CLI commands and replace all instances of **example** strings with your values. For example, replace **example-cluster** with your cluster.

**Check that an OID** C **provider is associated with the EKS cluster**

1\. Check that you have an existing IAM [OpenID Connect (OIDC) provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>) for your cluster by running the following command:
    
    
    oidc_id=$(aws eks describe-cluster --name example-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

2\. Check that an IAM OIDC provider with your cluster's ID is already in your account by running the following command:
    
    
    aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

**Note:** If output is returned, then you already have an IAM OIDC provider for your cluster and you can skip the next step. If no output is returned, then you must create an IAM OIDC provider for your cluster at the next step.

3\. Create an IAM OIDC identity provider for your cluster by running the following command:
    
    
    eksctl utils associate-iam-oidc-provider --cluster example-cluster --approve

**Check that the Cluster Autoscaler service account is annotated with the IAM role**

Check that the service account is annotated with the IAM role by running the following command:
    
    
    kubectl get serviceaccount cluster-autoscaler -n kube-system -o yaml

The following is the expected outcome:
    
    
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::012345678912:role/<cluster_auto_scaler_iam_role>
      name: cluster-autoscaler
      namespace: kube-system

**Check that the correct[IAM policy](<https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#ca-create-policy>) is attached to the preceding IAM role**

For an example, see the following:
    
    
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeTags",
            "autoscaling:DescribeLaunchConfigurations",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:DescribeInstanceTypes",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
          ],
          "Resource": "*"
        }
      ]
    }

**Check that the trust relationship is configured correctly**

For an example, see the following:
    
    
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::<example_awsaccountid>:oidc-provider/oidc.eks.<example_region>.amazonaws.com/id/<example_oidcid>"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.<example_region>.amazonaws.com/id/<example_oidcid>:aud": "sts.amazonaws.com",
              "oidc.eks.<example_region>.amazonaws.com/id/<example_oidcid>:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
            }
          }
        }
      ]
    }

Restart the Cluster Autoscaler pod when any change is made to the service account role or IAM policy.

If the logs indicate any networking issues (for example, I/O timeout), then do the following:

**Note:** The following is an example of a log that indicates networking issues:
    
    
    Failed to create AWS Manager: cannot autodiscover ASGs: WebIdentityErr: failed to retrieve credentials caused by: RequestError: send request failed caused by: Post https://sts.region.amazonaws.com/: dial tcp: i/o timeout

1\. Check that the Amazon EKS cluster is configured with the required [networking](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html>) setup. Verify that the worker node subnet has a route table that can route traffic to the following endpoints, either on [global or Regional endpoints](<https://docs.aws.amazon.com/general/latest/gr/rande.html>):

  * Amazon Elastic Compute Cloud (Amazon EC2)
  * AWS Auto Scaling
  * AWS Security Token Service (AWS STS)



2\. Make sure that the subnet [network access control list (network ACL)](<https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html>) or the worker node security group isn't blocking traffic communicating to these endpoints.

3\. If the Amazon EKS cluster is [private](<https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html>), then check the setup of the relevant [Amazon Virtual Private Cloud (VPC) endpoints](<https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html>). For example, Amazon EC2, AWS Auto Scaling, and AWS STS.

**Note:** The security group of each VPC endpoint is required to allow the Amazon EKS worker node security group. It's also required to allow the Amazon EKS VPC CIDR block on 443 port on the ingress traffic.

### Cluster Autoscaler isn't scaling in or scaling out nodes

If your Cluster Autoscaler isn't scaling in or scaling out nodes, then check the following:

  * Check the Cluster Autoscaler pod logs.
  * Check the Auto Scaling group tagging for the Cluster Autoscaler.
  * Check the configuration of the deployment manifest.
  * Check the current number of nodes.
  * Check the pod resource request.
  * Check the taint configuration for the node in node group.
  * Check whether the node is annotated with scale-down-disable.



**Check the Cluster Autoscaler pod logs**

To view the pod logs and identify the reasons why your Cluster Autoscaler isn't scaling in or scaling out nodes, run the following command:
    
    
    kubectl logs -f -n kube-system -l app=cluster-autoscaler

Check whether the pod that's in a **Pending** status contains any scheduling rules, such as the [affinity](<https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity>) rule, by running the following describe pod command:
    
    
    kubectl describe pod <example_podname> -n <example_namespace>

Check the **events** section from the output. This section shows information about why a pod is in a pending status.

**Note:** Cluster Autoscaler respects **nodeSelector** and **requiredDuringSchedulingIgnoredDuringExecution** in **nodeAffinity** , assuming that you labeled your node groups accordingly. If a pod can't be scheduled with **nodeSelector** or **requiredDuringSchedulingIgnoredDuringExecution** , then Cluster Autoscaler considers only node groups that satisfy those requirements for expansion. Modify the scheduling rules defined on pods or nodes accordingly so that a pod is scheduled on a node.

**Check the Auto Scaling group tagging for the Cluster Autoscaler**

The node group’s corresponding Auto Scaling group must be tagged for the Cluster Autoscaler to discover the Auto Scaling group as follows:

Tag 1:

  * key: **k8s.io/cluster-autoscaler/example-cluster**
  * value: owned



Tag 2:

  * key: **k8s.io/cluster-autoscaler/enabled**
  * value: true



**Check the configuration of the deployment manifest**

To check the configuration of the Cluster Autoscaler deployment manifest, run the following command:
    
    
    kubectl -n kube-system edit deployment.apps/cluster-autoscaler

Check that the manifest is configured with the correct **node-group-auto-discovery** argument as follows:
    
    
    containers:
    - command
       ./cluster-autoscaler
       --v=4
       --stderrthreshold=info
       --cloud-provider=aws
       --skip-nodes-with-local-storage=false
       --expander=least-waste
       --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/example-cluster
       --balance-similar-node-groups
       --skip-nodes-with-system-pods=false

**Check the current number of nodes**

To check whether the current number of nodes has reached the managed node group's minimum or maximum values, run the following command:
    
    
    aws eks describe-nodegroup --cluster-name <example-cluster> --nodegroup-name <example-nodegroup>

If the minimum or maximum values are reached, then modify the values with the new workload requirements.

**Check the pod resource request**

To check whether the pod resource request can't be fulfilled by the current node instance types, run the following command:
    
    
    kubectl -n <example_namespace> get pod <example_podname> -o yaml | grep resources -A6

To get the resource request fulfilled, either modify the pod resource requests or create a new node group. When creating a new node group, make sure that the nodes' instance type can fulfill the resource requirement for pods.

**Check the taint configuration for the node in node group**

Check whether taints are configured for the node and whether the pod can tolerate the taints by running the following command:
    
    
    kubectl describe node <example_nodename> | grep taint -A2

If the taints are configured, then remove the taints defined on the node. If the pod can't tolerate taints, then define [tolerations](<https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/>) on the pod so that the pod can be scheduled on the node with the taints.

**Check whether the node is annotated with scale-down-disable**

To check that the node is annotated with **scale-down-disable** , run the following command:
    
    
    kubectl describe node <example_nodename> | grep scale-down-disable

The following is the expected outcome:
    
    
    cluster-autoscaler.kubernetes.io/scale-down-disabled: true

If **scale-down-disable** is set to true, then remove the annotation for the node to be able to scale down by running the following command:
    
    
    kubectl annotate node <example_nodename> cluster-autoscaler.kubernetes.io/scale-down-disabled-

For more information on troubleshooting, see [Cluster Autoscaler FAQ](<https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md>) on the GitHub website.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
