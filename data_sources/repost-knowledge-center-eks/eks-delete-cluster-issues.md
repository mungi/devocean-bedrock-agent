Original URL: <https://repost.aws/knowledge-center/eks-delete-cluster-issues>

# Why can't I delete my Amazon EKS cluster?

I can't delete my Amazon Elastic Kubernetes Service (Amazon EKS) cluster. How do I resolve this?

## Short description

To delete an Amazon EKS cluster, you must first delete all managed node groups that are associated with the cluster. For more information, see [Deleting an Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html#w237aac13c27b9b3>).

**Note:** It's a best practice to delete the cluster with the same tool that you used to create the cluster.

**Important:** If you create load balancers using the [AWS Load Balancer Controller](<https://github.com/kubernetes-sigs/aws-load-balancer-controller>) (from the GitHub website), then Application Load Balancers or Network Load Balancers are created for you. If you delete your cluster before deleting the Kubernetes ingresses or services managing the load balancer, then you must manually delete the load balancer. See [Delete an Application Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-delete.html>), [Delete a Network Load Balancer](<https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-delete.html>), and [Delete your load balancer (Classic)](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-getting-started.html#delete-load-balancer>).

If you still can't delete your cluster components, then based on your scenario, consider the following options:

  * You receive the error message "The following resource(s) failed to delete" or "resource XXXXXXX has a dependent object". Complete the steps in the **Delete the AWS CloudFormation stack that created the cluster component** section.
  * You deleted your cluster, and the nodes are still active. Deleting a cluster doesn't automatically delete self-managed nodes. You must manually delete the nodes. Complete the steps in the **Delete self-managed nodes** section.
  * Your cluster is stuck in the DELETING state. Confirm that no missing AWS Identity and Access Management (IAM) policy or role is preventing your cluster from deleting. If the IAM role is missing, then complete the steps in the **Recreate the IAM service role for Amazon EKS** section.
  * The Amazon EKS **DeleteCluster** API call fails with the error message "Cannot delete because cluster XXXXXXX currently has an update in progress." However, you see that the cluster is in the **Active** state, and no update is in progress. In this case, refer to the **Complete an Amazon EKS automatic platform version upgrade** section.



**Note:** It's normal that deleting your cluster takes time. You aren't charged for a cluster that is in the DELETING state.

## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html#general-latest>).

### Delete the AWS CloudFormation stack that created the cluster component

1\. You can [delete the stack on the AWS CloudFormation console](<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html>). Or, you can use the AWS CLI [delete-stack](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/delete-stack.html>) command.

If you can't delete your stack because of dependencies, first manually delete the resources that have the dependencies, or remove the dependencies. Then, try to delete the stack again.

To [retain the resources that are failing to delete](<https://repost.aws/knowledge-center/delete-cf-stack-retain-resources>), skip the resources when you delete the stack. This option is available only on resources or stacks that are in a DELETE_FAILED state. The skipped resources remain active in the account, but the CloudFormation stack is deleted. You can then delete the resources through the AWS Management Console.

2\. After the stack is deleted, try deleting your cluster again.

If the stack is slow to delete or failed to delete, then review the [DeleteCluster](<https://docs.aws.amazon.com/eks/latest/APIReference/API_DeleteCluster.html>) API call in [AWS CloudTrail](<https://console.aws.amazon.com/cloudtrail/home/>).

### Delete self-managed nodes

If you manually created an Amazon Elastic Compute Cloud (Amazon EC2) instance, then [terminate your instance](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html>). If you created the nodes by an Auto Scaling group, then [delete the Auto Scaling group](<https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html#as-shutdown-lbs-delete-asg-cli>) to delete the nodes. If you used CloudFormation to create the nodes, then [delete the stack](<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-cli-deleting-stack.html>) to delete the nodes.

### Recreate the IAM service role for Amazon EKS

You must have an IAM service role that allows Amazon EKS to make calls to other AWS services for you. If you delete or modify the role after you create the cluster, then the cluster fails to delete some resources. For example, the cluster might not delete the elastic network interface that's used for private communication with the control plane instances.

1\. [Create the IAM role](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html>) again.

**Important:** Make sure that you choose Amazon EKS as the service to manage clusters for you.

2\. Attach the [AmazonEKSClusterPolicy](<https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html>) managed policies to the IAM role.

### Complete an Amazon EKS automatic platform version upgrade

Amazon EKS automatically upgrades all existing clusters to the latest Amazon EKS platform version for their corresponding Kubernetes minor version. Because these updates aren't initiated by you, they don't appear as updates in the console. Automatic upgrades of existing Amazon EKS platform versions are rolled out incrementally and might take some time to complete. After your clusters are in their latest platform version for their corresponding Kubernetes minor version, you can retry the cluster deletion.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
