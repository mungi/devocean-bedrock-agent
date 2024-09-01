Original URL: <https://repost.aws/knowledge-center/cloudwatch-stream-container-logs-eks>

# How do I stream container logs to CloudWatch in Amazon EKS?

I want to stream container logs running in Amazon Elastic Kubernetes Service (Amazon EKS) to a logging system like CloudWatch Logs. How can I do this?

## Short description

You can use the external resources [Fluent Bit](<https://fluentbit.io/>) or [Fluentd](<https://www.fluentd.org/>) to send logs from your containers to your CloudWatch logs. Fluent Bit is the default log solution for Container Insights, so it's a best practice to use Fluent Bit instead of Fluentd. Amazon provides a Fluent Bit container image on Amazon Elastic Container Registry (Amazon ECR). For more information, see [cloudwatch-agent](<https://gallery.ecr.aws/cloudwatch-agent/cloudwatch-agent>) on Amazon ECR.

When you set up Fluent Bit as a DaemonSet to send logs to CloudWatch, FluentBit creates these log groups, if they don't already exist:

| **Log Group name** | **Log source** | | /aws/containerinsights/ Cluster_Name/application | All log files in /var/log/containers | | /aws/containerinsights/ Cluster_Name/host | Logs from /var/log/dmesg, /var/log/secure, and /var/log/messages | | /aws/containerinsights/ Cluster_Name/dataplane | The logs in /var/log/journal for kubelet.service, kubeproxy.service, and docker.service |

## Resolution

### Prerequisites

Before following these steps, review the prerequisites:

  * Your EKS cluster is running with nodes in the Ready state, and the kubectl command is installed and running.
  * The AWS Identity and Access Management (IAM) managed **CloudWatchAgentServerPolicy** is in place to enable your Amazon EKS worker nodes to send metrics and logs to CloudWatch. You can do this by attaching a policy to the IAM role of your worker nodes. Or, use an IAM role for service accounts for the cluster, and attach the policy to this role. For more information, see [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).
  * You are running a cluster that supports Kubernetes version 1.18 or higher. This is a requirement of Container Insights for EKS Fargate. You have also defined a [Fargate profile](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html>) to schedule pods on Fargate.
  * The [EKS pod execution role](<https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html>) is in place to allow components that run on Fargate infrastructure to make calls to AWS APIs on your behalf. For example, pulling container images from Amazon ECR.



### Stream container logs running in your EKS EC2 cluster

To stream containers logs to CloudWatch Logs, install AWS for Fluent Bit using these steps:

1\. Create a namespace called amazon-cloudwatch, if you don't have one already:
    
    
    kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

2\. Run this command to create a ConfigMap called fluent-bit-cluster-info, including the cluster name and the Region that you want to send logs to. Replace my-cluster-name and my-cluster-region with your cluster's name and Region.
    
    
    ClusterName=<my-cluster-name>
    RegionName=<my-cluster-region>
    FluentBitHttpPort='2020'
    FluentBitReadFromHead='Off'
    [[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
    [[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
    kubectl create configmap fluent-bit-cluster-info \
    --from-literal=cluster.name=${ClusterName} \
    --from-literal=http.server=${FluentBitHttpServer} \
    --from-literal=http.port=${FluentBitHttpPort} \
    --from-literal=read.head=${FluentBitReadFromHead} \
    --from-literal=read.tail=${FluentBitReadFromTail} \
    --from-literal=logs.region=${RegionName} -n amazon-cloudwatch

3\. Deploy the Fluent Bit optimized configuration DaemonSet to the cluster:
    
    
    kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml

4\. **Optional** : Patch the aws-for-fluent-bit DaemonSet to use the AWS for Fluent Bit image on Amazon Elastic Container Registry:
    
    
    kubectl patch ds fluent-bit -n amazon-cloudwatch -p \
    '{"spec":{"template":{"spec":{"containers":[{"name":"fluent-bit","image":"public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"}]}}}}'

5\. For [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>), create an OIDC provider and an IAM role and policy. Then, associate the IAM role to cloudwatch-agent and fluent-bit service accounts. Replace **ACCOUNT_ID** and **IAM_ROLE_NAME** with AWS Account ID and the IAM role used for service accounts.
    
    
    kubectl annotate serviceaccounts fluent-bit -n amazon-cloudwatch "eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME"

For more customization, see [Set up Fluent Bit as a DaemonSet to send logs to CloudWatch Logs](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html>).

**Troubleshoot Fluent Bit deployment**

1\. Run this command, and then check the events at the bottom of the output:
    
    
    kubectl describe pod pod-name -n amazon-cloudwatch

2\. Run this command to check the logs:
    
    
    kubectl logs pod-name -n amazon-cloudwatch

**Delete Fluent Bit deployment**

To delete Fluent Bit deployment, run these commands:
    
    
    kubectl delete configmap fluent-bit-cluster-info -n amazon-cloudwatch 
    
    kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml

### Stream container logs running in your EKS Fargate cluster

Amazon EKS on Fargate has a built-in log router based on Fluent Bit. This means that you don't explicitly run a Fluent Bit container as a sidecar. Instead, Amazon runs it for you. For more details, see [Fargate logging](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html>).

Follow these steps to stream containers logs to CloudWatch logs:

1\. Create a dedicated Kubernetes namespace called aws-observability:
    
    
    cat <<EOF > aws-observability-namespace.yaml
    kind: Namespace
    apiVersion: v1
    metadata:
      name: aws-observability
      labels:
        aws-observability: enabled
    EOF
    
    kubectl apply -f aws-observability-namespace.yaml

2\. Create a ConfigMap with a Fluent Conf data value to ship container logs to CloudWatch logs:
    
    
    cat <<EOF > aws-logging-cloudwatch-configmap.yaml
    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: aws-logging
      namespace: aws-observability
    data:
      output.conf: |
        [OUTPUT]
            Name cloudwatch_logs
            Match   *
            region region-code
            log_group_name fluent-bit-cloudwatch
            log_stream_prefix from-fluent-bit-
            auto_create_group true
            log_key log
    
      parsers.conf: |
        [PARSER]
            Name crio
            Format Regex
            Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
            Time_Key    time
            Time_Format %Y-%m-%dT%H:%M:%S.%L%z
      
      filters.conf: |
         [FILTER]
            Name parser
            Match *
            Key_name log
            Parser crio
    EOF
    
    kubectl apply -f aws-logging-cloudwatch-configmap.yaml

3\. Create an IAM policy using the CloudWatch IAM policy, and then attach it to the pod execution role that is specified for your Fargate profile.

  * Download the CloudWatch IAM policy to your computer. You can also [view the policy](<https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json>) on GitHub.


    
    
    curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json

  * Create an IAM policy from the policy file that you downloaded.


    
    
    aws iam create-policy —policy-name eks-fargate-logging-policy —policy-document file://permissions.json

  * Attach the IAM policy to the pod execution role that is specified for your Fargate profile. Replace 111122223333 with your account ID.


    
    
    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::111122223333:policy/eks-fargate-logging-policy \
    --role-name your-pod-execution-role

For more information on troubleshooting AWS Fluent Bit running on EKS Fargate, see the [Troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html#fargate-logging-troubleshooting>) page.

**Disable streaming logs for EKS Fargate pods**

To disable streaming logs for your EKS Fargate pods, run this command:
    
    
    kubectl delete namespace aws-observability

Delete pods and redeploy them after you delete the aws-observability namespace.

* * *

## Related information

[Using Container Insights](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html>)

* * *

Topics

[Management & Governance](<https://repost.aws/topics/TAevTsfINjS2-2QSh0i3nDqQ/management-governance>)[Networking & Content Delivery](<https://repost.aws/topics/TA-2izgznkTKe0-VdIELPAgg/networking-content-delivery>)

Tags

[Amazon CloudWatch](<https://repost.aws/tags/TArz36ydKETWeIc1aO7QuRFw/amazon-cloudwatch>)

Language

English
