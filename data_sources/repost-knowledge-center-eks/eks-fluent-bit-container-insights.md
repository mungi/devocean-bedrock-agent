Original URL: <https://repost.aws/knowledge-center/eks-fluent-bit-container-insights>

# How do I troubleshoot setup issues when I integrate Fluent Bit with Container Insights for Amazon EKS?

I want to troubleshoot setup issues when I integrate Fluent Bit with Amazon CloudWatch Container Insights for Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

**Note:** It's a best practice to use Fluent Bit instead of Fluentd. For more information, see [Send logs to CloudWatch Logs](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-logs.html>).

To allow Fluent Bit to deliver container logs to CloudWatch Logs, you must grant AWS Identity and Access Management (IAM) permissions to Fluent Bit. For more information, see [Verify prerequisites](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-prerequisites.html>).

To use Container Insights with Fluent bit, set up an IAM role for service account (IRSA), and then deploy Container Insights in your EKS cluster.

## Resolution

### Set up Container Insights with Fluent Bit

Use the [CloudWatchAgentServerPolicy](<https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchAgentServerPolicy.html>) AWS managed policy to create a **cloudwatch-agent** and **fluent-bit** service account.

Complete the following steps:

  1. Run the following commands to set up the environment variables:
    
        export CLUSTER=clustername
    export AWS_REGION=awsregion

**Note:** Replace **clustername** , **awsregion** with your own cluster name and AWS Region.

  2. Run the following eksctl command to create a **CloudWatch-agent** service account with IRSA:
    
        eksctl create iamserviceaccount \
        --name cloudwatch-agent \
        --namespace amazon-cloudwatch \
        --cluster $CLUSTER \
        --attach-policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" \
        --approve \
        --override-existing-serviceaccounts

  3. Run the following eksctl command to create the Fluent Bit service account with IRSA:
    
        eksctl create iamserviceaccount \
        --name fluent-bit \
        --namespace amazon-cloudwatch \
        --cluster $CLUSTER \
        --attach-policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" \
        --approve \
        --override-existing-serviceaccounts

  4. To use quick start to deploy Container Insights, run the following command
    
        :ClusterName=<my-cluster-name>
    RegionName=<my-cluster-region>
    FluentBitHttpPort='2020'
    FluentBitReadFromHead='Off'
    [[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
    [[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
    curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart-enhanced.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f - 

**Note:** Replace **my-cluster-name** and **my-cluster-region** with your own cluster name and Region. The preceding command creates a **ClusterRole** , **ClusterRoleBinding** , **ConfigMap** and **DaemonSet** for the CloudWatch agent and Fluent Bit.

  5. Run the following command to validate that the CloudWatch agent and Fluent Bit deploys:
    
        kubectl get pods -n amazon-cloudwatch




When the deployment is complete, the CloudWatch agent creates the log group **/aws/containerinsights/Cluster_Name/performance.**

Fluent Bit creates the log groups **/aws/containerinsights/Cluster_Name/application, /aws/containerinsights/Cluster_Name/host** and **/aws/containerinsights/Cluster_Name/dataplane**.

### Troubleshoot Fluent Bit setup issues

**Fluent Bit pods crash**

To check for error messages in the Fluent Bit pod logs, complete the following steps:

  1. Run the following commands to find events from Fluent Bit pods:
    
        kubectl -n amazon-cloudwatch logs -l k8s-app=fluent-bit 
    kubectl -n amazon-cloudwatch describe pod fluent_pod pod_name

  2. Verify that **cluster-info** is accurate and has no syntax mistakes.

  3. Verify that all cluster name and Region values are set. For more information, see [amazon-cloudwatch-container-insights](<https://github.com/aws-samples/amazon-cloudwatch-container-insights/blob/master/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit-configmap.yaml>) on the GitHub website.




**Fluent Bit doesn't send logs to CloudWatch**

Complete the following steps to troubleshoot:

  1. Verify that the output plugin is correctly set up in the Fluent Bit configuration file. To check if there are any data ship errors, run the following command to view the Fluent Bit pod logs:
    
        kubectl -n amazon-cloudwatch logs fluent_pod_name

  2. Make sure that the Fluent Bit pods have the necessary IAM permissions to create log groups and stream logs to CloudWatch. You must have the **CloudWatchAgentServerPolicy** IAM policy attached to the IAM role that's annotated in the fluent-bit service account.  
If you used IRSA, then you must attach the IAM role to the worker nodes. For more information, see [How do I troubleshoot IRSA errors in Amazon EKS?](<https://repost.aws/knowledge-center/eks-troubleshoot-irsa-errors>)




If you don't see particular application logs, then confirm that your application can run. Then, confirm if the application can generate other types of logs. If the application runs and logs are generated, then check the fluent-bit pod logs to see if specific errors are sent to CloudWatch.

**Fluent Bit pods are stuck in the CreateContainerConfigError status**

Run the following command to get the exact error message:
    
    
    kubectl describe pod pod_name -n amazon-cloudwatch

In the **Events** section from the output of the command, look for an error message such as the following one:
    
    
    Error syncing pod ("fluent-bit-xxxxxxx"), skipping: failed to "StartContainer" with CreateContainerConfigError: "configmap \"fluent-bit-config\" not found"

If you see the preceding error message, then the ConfigMap for Fluent Bit (**fluent-bit-config**) is missing. Repeat step 4 in the **Set up Container Insights with Fluent Bit** section of this article.

## Related information

[Set up the CloudWatch agent to collect cluster metrics](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html>)

[Quick Start with the CloudWatch agent and Fluent Bit](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html#Container-Insights-setup-EKS-quickstart-FluentBit>)

[Activate debug logging](<https://github.com/aws/aws-for-fluent-bit/blob/mainline/troubleshooting/debugging.md#enable-debug-logging>) on the GitHub website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
