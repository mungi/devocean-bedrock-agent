Original URL: <https://repost.aws/knowledge-center/cloudwatch-container-insights-eks-fargate>

# How do I turn on Container Insights metrics on an Amazon EKS cluster?

I want to configure Amazon CloudWatch Container Insights to see my Amazon Elastic Kubernetes Service (Amazon EKS) cluster metrics.

## Short description

When you use Container Insights with Amazon EKS, Container Insights uses a containerized version of the CloudWatch agent to find all containers running in a cluster. Container Insights also uses AWS Distro for OpenTelemetry (ADOT) Collector to find containers in a cluster. Container Insights then collects performance data at every layer of the performance stack, such as performance log events that use an [embedded metric format](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html>). Afterward, Container Insights sends this data to CloudWatch Logs under the **/aws/containerinsights/cluster-name/performance** log group where CloudWatch creates aggregated metrics at the cluster, node, and pod levels. Container Insights also supports collecting metrics from clusters that are deployed on AWS Fargate for Amazon EKS. For more information, see [Using Container Insights](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html>).

**Note:** Container Insights is supported only on Linux instances. Amazon provides a CloudWatch agent container image on Amazon Elastic Container Registry (Amazon ECR). For more information, see [cloudwatch-agent/cloudwatch-agent](<https://gallery.ecr.aws/cloudwatch-agent/cloudwatch-agent>) on Amazon ECR.

## Resolution

### Prerequisites

  * Your Amazon EKS cluster is running with nodes in the **Ready** state and the **kubectl** command is installed and running.
  * The AWS Identity and Access Management (IAM) managed **CloudWatchAgentServerPolicy** activates your Amazon EKS worker nodes to send metrics and logs to CloudWatch. To activate your worker nodes, attach a policy to the worker nodes' IAM role. Or, use an IAM role for service accounts for the cluster, and attach the policy to this role. For more information, see [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).
  * You're running a cluster that supports Kubernetes version 1.18 or higher. This is a requirement of Container Insights for EKS Fargate. Also, make sure that you define a [Fargate profile](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html>) to schedule pods on Fargate.
  * The [Amazon EKS pod IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html>) must allow components that run on the Fargate infrastructure to make calls to AWS APIs on your behalf. For example, the IAM role must be able to pull container images from Amazon ECR.



### Use the CloudWatch agent to set up Container Insights metrics on your EC2 cluster

The CloudWatch agent or ADOT first creates a log group that's named **aws/containerinsights/Cluster_Name/performance** , and then sends the performance log events to this log group. When you set up Container Insights to collect metrics, you must deploy the CloudWatch agent container image as a DaemonSet from Docker Hub. By default, this is done as an anonymous user. This pull might be subject to a rate limit.

1\. If you don't have an **amazon-cloudwatch** namespace, then create one:
    
    
    kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

2\. Create a service account for the CloudWatch agent that's named **cloudwatch-agent** :
    
    
    kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml

3\. Create a **configmap** as a configuration file for the CloudWatch agent:
    
    
    ClusterName=<my-cluster-name>curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-configmap.yaml | sed 's/cluster_name/'${ClusterName}'/' | kubectl apply -f -

**Note:** Replace **my-cluster-name** with the name of your EKS cluster. For more information, see [Create a ConfigMap for the CloudWatch agent](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html#create-configmap>).

4\. Deploy the **cloudwatch-agent** DaemonSet:
    
    
    kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

(Optional) To pull the CloudWatch agent from the Amazon Elastic Container Registry, patch the **cloudwatch-agent** DaemonSet:
    
    
    kubectl patch ds cloudwatch-agent -n amazon-cloudwatch -p \ '{"spec":{"template":{"spec":{"containers":[{"name":"cloudwatch-agent","image":"public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"}]}}}}'

**Note:** The **Cloudwatch-agent** Docker image on Amazon ECR supports the ARM and AMD64 architectures. Replace the latest image tag based on the image version and architecture. For more information, see images tags [cloudwatch-agent](<https://gallery.ecr.aws/cloudwatch-agent/cloudwatch-agent>) on Amazon ECR.

5\. For [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>), create an OIDC provider and an IAM role and policy. Then, associate the IAM role to the **cloudwatch-agent** service account:
    
    
    kubectl annotate serviceaccounts cloudwatch-agent -n amazon-cloudwatch "eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME"

**Note:** Replace **ACCOUNT_ID** with your account ID and **IAM_ROLE_NAME** with the IAM role that you use for the service accounts.

### Troubleshoot the CloudWatch agent

1\. To retrieve the list of pods, run this command:
    
    
    kubectl get pods -n amazon-cloudwatch

2\. To check the events at the bottom of the output, run this command:
    
    
    kubectl describe pod pod-name -n amazon-cloudwatch

3\. Check the logs:
    
    
    kubectl logs pod-name -n amazon-cloudwatch

4\. If you see a **CrashLoopBackOff** error for the CloudWatch agent, then make sure that your IAM permissions are set correctly. For more information, see [Verify prerequisites](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-prerequisites.html>).

### Delete the CloudWatch Agent

To delete the CloudWatch agent, run this command:
    
    
    kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

**Note:** Deleting the namespace also deletes the associated resources.

### Use ADOT to set up Container Insights metrics on your EC2 cluster

1\. To deploy the ADOT Collector as a DaemonSet, run the following command:
    
    
    curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-container-insights-infra.yaml | kubectl apply -f -

For more information, see [Container Insights EKS infrastructure metrics](<https://aws-otel.github.io/docs/getting-started/container-insights/eks-infra>).

2\. To confirm that the collector is running, run this command:
    
    
    kubectl get pods -l name=aws-otel-eks-ci -n aws-otel-eks

3\. (Optional) By default, the **aws-otel-collector** image is pulled from Docker Hub as an anonymous user. This pull might be subject to a rate limit. To pull the [aws-otel-collector](<https://gallery.ecr.aws/aws-observability/aws-otel-collector>) Docker image on Amazon ECR, patch **aws-otel-eks-ci** DaemonSet:
    
    
    kubectl patch ds aws-otel-eks-ci -n aws-otel-eks -p \'{"spec":{"template":{"spec":{"containers":[{"name":"aws-otel-collector","image":"public.ecr.aws/aws-observability/aws-otel-collector:latest"}]}}}}'

**Note:** The **Cloudwatch-agent** Docker image on Amazon ECR supports the ARM and AMD64 architectures. Replace the latest image tag based on the image version and architecture. For more information, see images tags [cloudwatch-agent](<https://gallery.ecr.aws/cloudwatch-agent/cloudwatch-agent>) on Amazon ECR.

4\. (Optional) For [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>), create an OIDC provider and an IAM role and policy. Then, associate the IAM role to the **aws-otel-sa** service account.
    
    
    kubectl annotate serviceaccounts aws-otel-sa -n aws-otel-eks "eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME"

**Note:** Replace **ACCOUNT_ID** with your account ID and **IAM_ROLE_NAME** with the IAM role that you use for the service accounts.

### Delete ADOT

To delete ADOT, run this command:
    
    
    curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-container-insights-infra.yaml |kubectl delete -f -

### Use ADOT to set up Container Insights metrics on an EKS Fargate cluster

For applications that run on Amazon EKS and AWS Fargate, you can use ADOT to set up Container Insights. EKS Fargate networking architecture doesn't allow pods to directly reach the kubelet on the worker to retrieve resource metrics. The ADOT Collector first calls the Kubernetes API server to proxy the connection to the kubelet on a worker node. Then it collects kubelet's advisor metrics for workloads on that node.

The ADOT Collector sends the following metrics to CloudWatch for every workload that runs on EKS Fargate:

  * **pod_cpu_utilization_over_pod_limit**
  * **pod_cpu_usage_total**
  * **pod_cpu_limit**
  * **pod_memory_utilization_over_pod_limit**
  * **pod_memory_working_set**
  * **pod_memory_limit**
  * **pod_network_rx_bytes**
  * **pod_network_tx_bytes**



Each metric is associated with these dimension sets and is collected under the CloudWatch namespace that's named **ContainerInsights** :

  * **ClusterName** , **LaunchType**
  * **ClusterName** , **Namespace** , **LaunchType**
  * **ClusterName** , **Namespace** , **PodName** , **LaunchType**



For more information, see [Container Insights EKS Fargate](<https://aws-otel.github.io/docs/getting-started/container-insights/eks-fargate>).

To deploy ADOT in your EKS Fargate, complete these steps:

1\. Associate a Kubernetes service account with an IAM role. Create an IAM role that's named **EKS-ADOT-ServiceAccount-Role** that's associated with a Kubernetes service account that's named **adot-collector**. The following helper script requires [eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>):
    
    
    #!/bin/bashCLUSTER_NAME=YOUR-EKS-CLUSTER-NAME
    REGION=YOUR-EKS-CLUSTER-REGION
    SERVICE_ACCOUNT_NAMESPACE=fargate-container-insights
    SERVICE_ACCOUNT_NAME=adot-collector
    SERVICE_ACCOUNT_IAM_ROLE=EKS-Fargate-ADOT-ServiceAccount-Role
    SERVICE_ACCOUNT_IAM_POLICY=arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    
    eksctl utils associate-iam-oidc-provider \
    --cluster=$CLUSTER_NAME \
    --approve
    
    eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --name=$SERVICE_ACCOUNT_NAME \
    --namespace=$SERVICE_ACCOUNT_NAMESPACE \
    --role-name=$SERVICE_ACCOUNT_IAM_ROLE \
    --attach-policy-arn=$SERVICE_ACCOUNT_IAM_POLICY \
    --approve

**Note:** Replace **CLUSTER_NAME** with your cluster name and **REGION** with your AWS Region.

2\. To deploy the ADOT Collector as a Kubernetes StatefulSet, run the following command:
    
    
    ClusterName=<my-cluster-name>Region=<my-cluster-region>
    curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-fargate-container-insights.yaml | sed 's/YOUR-EKS-CLUSTER-NAME/'${ClusterName}'/;s/us-east-1/'${Region}'/' | kubectl apply -f -

**Note:** Make sure that you have a matching Fargate profile to provision the StatefulSet pods on AWS Fargate. Replace **my-cluster-name** with your cluster's name and **my-cluster-region** with the AWS Region that your cluster is located in.

3\. To verify that the ADOT Collector pod is running, run the following command:
    
    
    kubectl get pods -n fargate-container-insights

4\. (Optional) By default, the **aws-otel-collector** image is pulled from Docker Hub as an anonymous user. This pull might be subject to a rate limit. To pull the [aws-otel-collector](<https://gallery.ecr.aws/aws-observability/aws-otel-collector>) Docker image on Amazon ECR, patch **adot-collector** StatefulSet:
    
    
    kubectl patch sts adot-collector -n fargate-container-insights -p \'{"spec":{"template":{"spec":{"containers":[{"name":"adot-collector","image":"public.ecr.aws/aws-observability/aws-otel-collector:latest"}]}}}}'

**Delete ADOT**

To delete ADOT, run this command:
    
    
    eksctl delete iamserviceaccount --cluster CLUSTER_NAME --name adot-collector
    
    ClusterName=<my-cluster-name>Region=<my-cluster-region>
    curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-fargate-container-insights.yaml | sed 's/YOUR-EKS-CLUSTER-NAME/'${ClusterName}'/;s/us-east-1/'${Region}'/' | kubectl delete -f -

* * *

Topics

[Management & Governance](<https://repost.aws/topics/TAevTsfINjS2-2QSh0i3nDqQ/management-governance>)[Networking & Content Delivery](<https://repost.aws/topics/TA-2izgznkTKe0-VdIELPAgg/networking-content-delivery>)

Tags

[Amazon CloudWatch](<https://repost.aws/tags/TArz36ydKETWeIc1aO7QuRFw/amazon-cloudwatch>)

Language

English
