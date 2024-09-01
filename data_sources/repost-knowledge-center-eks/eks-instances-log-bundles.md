Original URL: <https://repost.aws/knowledge-center/eks-instances-log-bundles>

# How do I generate a log bundle for my Amazon EKS instances?

I'm troubleshooting an Amazon Elastic Kubernetes Service (Amazon EKS) instance. I need to collect all the relevant Amazon EKS logs that are associated with the instance.

## Short description

Use the [AWSSupport-CollectEKSInstanceLogs](<https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-awssupport-collecteksinstancelogs.html>) runbook to collect your Amazon EKS logs.

**Important:** For the automation to work, you must [install](<https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html>) and run AWS Systems Manager Agent (SSM Agent) on your Amazon EKS instance.

## Resolution

**Note:** The following resolution works only for worker nodes in Amazon EKS for Linux.

To generate a log bundle for Amazon EKS instances, complete the following steps:

  1. Open the [AWS Systems Manager console](<https://console.aws.amazon.com/systems-manager/>).
  2. In the navigation pane, choose **Automation**.
  3. Choose **Execute automation**.
  4. On the **Owned by Amazon** tab, in the **Automation document** search box, enter **EKSInstanceLogs**. Then, select **AWSSupport-CollectEKSInstanceLogs**.
  5. Choose **Next**.
  6. On the **Automation Inputs** page, for **EKSInstanceId** , enter your target Amazon EKS instance ID.
  7. Set the **LogDestination** and **AutomationAssumeRole** parameters.  
**Note:** The log bundle is uploaded to the Amazon Simple Storage Service (Amazon S3) bucket that's specified in the **LogDestination** field. If you didn't specify a bucket, then you can retrieve the log bundle from the instance. The log bundle is saved locally in the **/var/log/** path.
  8. Choose **Execute automation**.



When you run **AWSSupport-CollectEKSInstanceLogs** , use the following best practices and requirements:

  * It's a best practice to attach the Amazon managed **AmazonSSMManagedInstanceCore** policy to the relevant AWS Identity and Access Management (IAM) role. The IAM role is for the Amazon Elastic Compute Cloud (Amazon EC2) instance that's targeted for automation.
  * If you provide the S3 bucket name in the **LogDestination** field before the automation runs, then the instance profile can write to the bucket.
  * To run the automation and send the command to the instance, you must have at least the **ssm:ExecuteAutomation** and **ssm:SendCommand** permissions.
  * To read the automation output, you must have the **ssm:GetAutomationExecution** permission.
  * For Amazon Linux 2, IMDS endpoints support both IMDSv2 and IMDSv1 by default. If you choose to configure IMDSv2, then the other version no longer works. Because **AWSSupport-CollectEKSInstanceLogs** uses IMDSv1, you might notice a **Pending** step when the collected logs are uploaded.



## Related information

[Configure instance permissions for Systems Manager](<https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html>)

[EKS Logs Collector](<https://github.com/awslabs/amazon-eks-ami/tree/master/log-collector-script/linux>) on the GitHub website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)[End User Computing](<https://repost.aws/topics/TAG9-8GrrnTvezb-2ifZO_-w/end-user-computing>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)[AWS Support Automation Workflows](<https://repost.aws/tags/TAHgFysm6PQZye8cyq2WRo2A/aws-support-automation-workflows>)

Language

English
