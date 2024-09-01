Original URL: <https://repost.aws/knowledge-center/codebuild-eks-unauthorized-errors>

# How do I resolve "error: You must be logged in to the server (Unauthorized)" errors when connecting to an Amazon EKS cluster from CodeBuild?

I'm trying to connect to an Amazon Elastic Kubernetes Service (Amazon EKS) cluster from AWS CodeBuild using the CodeBuild service role. Why are my kubectl commands returning "error: You must be logged in to the server (Unauthorized)" errors, and how do I troubleshoot the issue?

## Short description

[AWS Identity and Access Management (IAM) Authenticator](<https://github.com/kubernetes-sigs/aws-iam-authenticator>) doesn't permit a path in the role [Amazon Resource Name (ARN)](<https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html>) used in the configuration map. If the role ARN (**rolearn**) in your [aws-auth ConfigMap](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>) includes a path, Amazon EKS returns the following error:

"error: You must be logged in to the server (Unauthorized)"

The [CodeBuild service role](<https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-service-role>) ARN includes the following path: **/service-role**. When you specify the **rolearn** value in your aws-auth ConfigMap, you must remove the **/service-role** path—or any other path, if you're using another role. For more information, see [Managing users or IAM roles for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

If you receive errors after removing any paths from the role ARN in your aws-auth ConfigMap, follow the instructions in the following article: [How do I resolve an unauthorized server error when I connect to the Amazon EKS API server?](<https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>)

## Resolution

### Identify your CodeBuild service role's ARN and remove the /service-role path

1\. Open the [CodeBuild console](<https://console.aws.amazon.com/codesuite/codebuild/start>).

2\. In the left navigation pane, choose **Build**. Then, choose **Build projects**.

3\. Select your project name. Then, choose **Build details**.

4\. Under the **Environment** section, in the **Build details** pane, copy the CodeBuild service role ARN.

5\. In a text editor, paste the CodeBuild service role ARN and remove the **/service-role** path. Then, copy the edited ARN.

**Example CodeBuild service role ARN**
    
    
    arn:aws:iam::123456789012:role/service-role/codebuild-project-service-role

**Example CodeBuild service role ARN with the /service-role path removed**
    
    
    arn:aws:iam::123456789012:role/codebuild-project-service-role

### Add the edited CodeBuild service role's ARN to your aws-auth ConfigMap

1\. To edit the aws-auth ConfigMap in a text editor, the cluster owner or admin must run the following kubectl command:

**Note:** You can run the command from your local computer or an Amazon Elastic Compute Cloud (Amazon EC2) instance that has access to the EKS cluster. The user who created the cluster has access to the cluster by default.
    
    
    $ kubectl edit -n kube-system cm aws-auth

The aws-auth ConfigMap opens in vi editor.

**Note:** If you receive an **Error from server (NotFound): configmaps "aws-auth" not found** error, use the example aws-auth ConfigMap that's provided in the following article: [Managing users or IAM roles for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

2\. In the vi editor, add the edited CodeBuild service role's ARN to the aws-auth ConfigMap by doing the following:  
Activate insert mode by pressing **i**.  
In the **mapRoles** statement, under **system:masters** , for the **rolearn** value, enter the edited CodeBuild service role's ARN.  
Activate command mode by pressing **Esc**. Then, save and close the file by entering **:wq**.

**Example mapRoles statement that includes a correctly formatted CodeBuild service role ARN**


mapRoles: |

  * groups:
    * system:masters rolearn: arn:aws:iam::123456789012:role/codebuild-project-service-role username: codebuild-project-service-role




* * *

## Related information

[How do I resolve an unauthorized server error when I connect to the Amazon EKS API server?](<https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>)

* * *

Topics

[Developer Tools](<https://repost.aws/topics/TANatwY4hDTPSgXPhTihfD4A/developer-tools>)

Tags

[AWS CodeBuild](<https://repost.aws/tags/TA3PlC5MYDQLSIC8057qi90w/aws-codebuild>)

Language

English
