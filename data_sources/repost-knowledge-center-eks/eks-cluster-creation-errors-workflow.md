Original URL: <https://repost.aws/knowledge-center/eks-cluster-creation-errors-workflow>

# How can I troubleshoot errors in my Amazon EKS environment after I create a cluster?

I get errors in my Amazon Elastic Kubernetes Service (Amazon EKS) environment after I create a cluster.

## Short description

You can use the [AWSPremiumSupport-TroubleshootEKSCluster](<https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awspremiumsupport-troubleshootekscluster.html>) automation workflow to troubleshoot common errors with your Amazon EKS environment. The workflow provides a detailed report that lists errors, warnings, and links to Amazon Web Services (AWS) recommended best practices.

**Note:** To use the **AWSPremiumSupport-TroubleshootEKSCluster** automation workflow, you must be subscribed to an Enterprise or Business [Support plan](<https://aws.amazon.com/premiumsupport/plans/>).

You can use the **AWSPremiumSupport-TroubleshootEKSCluster** automation workflow if you experience any of these issues:

  * Your Kubernetes Cluster Autoscaler isn't working.
  * Your internal load balancer doesn't get created in private or public subnets.
  * You don't know if your worker nodes are using the latest Amazon Machine Image (AMI).
  * You get access denied errors in your **aws-node** pods.
  * You can't pull Amazon Elastic Container Registry (Amazon ECR) images.
  * Your managed nodes don't stabilize, or your self-managed nodes don't join a cluster.



The **AWSPremiumSupport-TroubleshootEKSCluster** automation workflow runs these checks:

  * Checks Auto Scaling groups for the Cluster AutoScaler subnet tags for internal and internet-facing load balancers and worker security groups.  
**Important:** If you have more than one security group associated to your worker nodes, then you must apply a tag to one of your security groups. Set the key of the tag to **kubernetes.io/cluster/your-cluster-name**. Set the value to **owned**. This tag is optional if you have only one security group associated to your worker nodes.
  * Checks worker nodes for the latest AMI.
  * Checks security group rules for minimum and recommended settings. For example, the workflow checks for ingress and egress from the cluster's security group (that is, all security groups attached to the cluster) and from the worker security group.
  * Checks custom network access control list (network ACL) configurations.
  * Checks AWS Identity and Access Management (IAM) policies on worker nodes, including the **AmazonEKSWorkerNodePolicy** and **AmazonEC2ContainerRegistryReadOnly** [policies](<https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html#create-worker-node-role>).
  * Checks if worker nodes can connect to the internet by checking the route tables of the subnets where they're located.



## Resolution

### Make your worker nodes discoverable

To make your work nodes discoverable, use the **AWSPremiumSupport-TroubleshootEKSCluster** automation workflow and your Amazon EKS cluster:

1\. Open the [Amazon EC2 console](<https://console.aws.amazon.com/ec2/>).

2\. On the navigation pane, choose **Instances**.

3\. Select the Amazon Elastic Compute Cloud (Amazon EC2) instances for your worker nodes, and then choose the **Tags** tab.

4\. Choose **Add/Edit Tags**.

5\. For **Key** , enter **kubernetes.io/cluster/your-cluster-name**. For **Value** , enter **'owned'/ 'shared'**.

6\. Choose **Save**.

The **AWSPremiumSupport-TroubleshootEKSCluster** automation workflow runs with the following policy. This policy must include minimum permissions to access the cluster. The cluster can be accessed only by **AutomationAssumeRole**.
    
    
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AWSPremiumSupportTroubleshootEKSCluster",
          "Effect": "Allow",
          "Action": [
            "eks:ListNodegroups",
            "eks:DescribeCluster",
            "eks:DescribeNodegroup",
            "iam:GetInstanceProfile",
            "iam:ListInstanceProfiles",
            "iam:ListAttachedRolePolicies",
            "autoscaling:DescribeAutoScalingGroups",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeInstances",
            "ec2:DescribeNatGateways",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeRouteTables"
          ],
          "Resource": "*"
        },
        {
          "Sid": "GetPublicSSMParams",
          "Effect": "Allow",
          "Action": "ssm:GetParameter",
          "Resource": [
            "arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*/amazon-linux-2/recommended/image_id",
            "arn:aws:ssm:*:*:parameter/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-*/image_id",
            "arn:aws:ssm:*:*:parameter/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-EKS_Optimized-*/image_id",
            "arn:aws:ssm:*:*:parameter/aws/service/ami-windows-latest/Windows_Server-1909-English-Core-EKS_Optimized-*/image_id",
            "arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*/amazon-linux-2-gpu/recommended/image_id"
          ]
        },
        {
          "Sid": "UploadObjectToS3",
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketPolicyStatus",
            "s3:GetBucketAcl",
            "s3:PutObject"
          ],
          "Resource": [
            "<BUCKET_ARN>",
            "<BUCKET_ARN>/AWSPremiumSupport-TroubleshootEKSCluster-*"
          ]
        }
      ]
    }

### Run the automation workflow from the AWS Systems Manager console

1\. Open the [Systems Manager console](<https://console.aws.amazon.com/systems-manager/>).

2\. In the navigation pane, choose **Automation**.

**Note:** If the Systems Manager homepage opens first, choose the menu icon to open the navigation pane, and then choose **Automation**.

3\. Choose **Execute automation**.

4\. In the **Automation document** search box, enter **AWSPremiumSupport-TroubleshootEKSCluster** , and then press **Enter**.

5\. From the search results, select **AWSPremiumSupport-TroubleshootEKSCluster**.

**Note:** The document owner is **Amazon**.

6\. In the **Document description** tab, verify that **Document version** is set to **Default version at runtime**.

7\. Choose **Next**.

8\. In the **Execute automation document** section, choose **Simple execution**.

9\. In the **Input parameters** section, set the following parameters:

Set **ClusterName** to the name of the cluster. This cluster must be running in your AWS account.  
Set **AutomationAssumeRole** to the IAM role that you want to use for the workflow.  
(Optional) If required, set **BucketName** to the Amazon Simple Storage Service (Amazon S3) bucket where you want to upload the report.

**Note** : It you want to specify the **AutomationAssumeRole** , create an IAM role and S3 bucket that apply to the policy. Then, upload the report to your own S3 bucket ( **BucketName**) for the SSM automation.

10\. Choose **Execute**.

11\. To monitor the progress, choose the running **Automation** , and then choose the **Steps** tab.

12\. When the process is finished, choose the **Descriptions** tab, and then choose **View output** to view the results.

**Note:** The results appear as a report that lists all the errors and warnings for your cluster.

### Run the automation workflow from the AWS CLI

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Create an IAM role and S3 bucket that apply to the policy if you would like to specify **AutomationAssumeRole** and upload report to your own S3 bucket ( **S3BucketName**) for running the automation workflow.

If you want the report in an S3 bucket, run this command:
    
    
    aws ssm start-automation-execution --document-name "AWSPremiumSupport-TroubleshootEKSCluster" --document-version "\$DEFAULT" --parameters '{"ClusterName":["your-eks-cluster"],"AutomationAssumeRole":["arn:aws:iam::123456789012:role/eks-troubleshooter-role"],"S3BucketName":["your_bucket"]}' --region your_region

If you don't want to upload the report to an S3 bucket, run this command:
    
    
    aws ssm start-automation-execution --document-name "AWSPremiumSupport-TroubleshootEKSCluster" --document-version "\$DEFAULT" --parameters '{"ClusterName":["your-eks-cluster"],"AutomationAssumeRole":["arn:aws:iam::123456789012:role/eks-troubleshooter-role"]}' --region your_region

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)[End User Computing](<https://repost.aws/topics/TAG9-8GrrnTvezb-2ifZO_-w/end-user-computing>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)[AWS Support Automation Workflows](<https://repost.aws/tags/TAHgFysm6PQZye8cyq2WRo2A/aws-support-automation-workflows>)

Language

English
