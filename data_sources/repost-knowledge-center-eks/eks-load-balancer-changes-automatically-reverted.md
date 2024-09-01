Original URL: <https://repost.aws/knowledge-center/eks-load-balancer-changes-automatically-reverted>

# How do I stop security group rules, listeners, or other changes from reverting on a load balancer in Amazon EKS?

When I try to make changes to my load balancer for Amazon Elastic Kubernetes Service (Amazon EKS), the changes automatically revert.

## Short description

When you use AWS Load Balancer Controller to create a load balancing service or an ingress resource, the controller configures many default parameters. This includes any parameters that you don’t specify in the manifest file, such as a health check path, default timeout, or security group rules.

However, you can use an AWS API call to directly change the default configuration. You can make this API call from the Amazon Elastic Compute Cloud (Amazon EC2) console, AWS Command Line Interface (AWS CLI), or another third-party tool. In this case, the controller reverts these changes to their original values during the next cluster reconciliation. For more information, see [Controllers and Reconciliation](<https://cluster-api.sigs.k8s.io/developer/providers/implementers-guide/controllers_and_reconciliation.html>) on the Kubernetes Cluster API website.

The following issues commonly occur because of reverted load balancer changes in Amazon EKS:

  * The load balancer’s custom security group rules automatically revert to 0.0.0.0/0, or they disappear.
  * The load balancer automatically deletes or adds listener rules.
  * Custom idle timeout values automatically revert to the default values.
  * The certificate automatically reverts to the previous version.
  * You can’t update the health check path because Amazon EKS reverted its values.
  * Amazon EKS modifies roles through the load balancer’s properties.



To troubleshoot these issues, first determine what caused your load balancer to make these changes. Specifically, find the relevant API call for the changed resource and the tool that made the call. Then, implement your changes in the manifest file.

**Note:** In the following resolution, a “load balancer” refers to a load balancing service, such as Network Load Balancer or Classic Load Balancer. Or, a load balancer can be an ingress resource, such as Application Load Balancer.

## Resolution

To define the expected state of a load balancer, you must specify changes in the manifest file’s annotations. Otherwise, the annotations force the changes to revert to the default, unchanged values.

If you try to use an AWS API call to directly change these values, then the controller considers this an out-of-band change. During the next reconciliation, the controller reverts the changes to their original values to sync with your Kubernetes service manifest configuration. Depending on the attribute that the controller reverts, this might result in a long downtime for your service.

AWS Load Balancer Controller uses multiple paths of logic for reconciliation. The following scenarios might cause **aws-load-balancer-controller** pods to restart:

  * An upgrade for the control plane, worker node, or platform
  * An instance refresh due to underlying problems such as hardware failure or health issues
  * Any activity that results in an update, delete, or patch API call on the controller pods
  * Automatic, periodic reconciliation  
**Note:** By default, the controller’s reconciliation period is 1 hour. However, this feature doesn’t work on versions 2.4.7 and earlier of Amazon EKS.



In these cases, AWS Load Balancer Controller initiates the reconciliation, and your load balancer refers to the most recent manifest file configuration. If you previously made any changes to your load balancer through an API call, then those changes revert.

### Identify the source of changes

Find the API call that relates to the updated resource. Search in AWS CloudTrail for the time frame that the changes occurred. For all AWS Load Balancer API Calls, see the [Elastic Load Balancing (ELB) API reference](<https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/Welcome.html>). For Amazon EC2 API calls, see the [Amazon EC2 API reference](<https://docs.aws.amazon.com/AWSEC2/latest/APIReference/Welcome.html>).

For example, if the controller reverts **SecurityGroup** rules, then you see that the API **RevokeSecurityGroupIngress** is invoked. You can then use the corresponding CloudTrail event to identify the API user. If the controller uses **WorkerNode** roles, then you see the node role that made the API call:
    
    
    ....
    "type": "AssumedRole",
    "arn": "arn:aws:sts::***********:assumed-role/eksctl-mycluster-NodeInstanceRole/i-***********",
    "sessionContext": {
        "sessionIssuer": {
            "type": "Role",
            "arn": "arn:aws:iam::***********:role/eksctl-mycluster-nodegr-NodeInstanceRole",
            "userName": "eksctl-mycluster-nodegr-NodeInstanceRole"
        },
        ...
        eventName ": "
        RevokeSecurityGroupIngress ",
        "userAgent": "elbv2.k8s.aws/v2.4.5 aws-sdk-go/1.42.27 (go1.19.3; linux; amd64)",
        "requestParameters": {
            "groupId": "sg-****",
            "ipPermissions": {
                "items": [{
                            "ipProtocol": "tcp",
                            "fromPort": 443,
                            "toPort": 443,
                            "groups": {},
                            "ipRanges": {
                                "items": [{
                                    "cidrIp": "0.0.0.0/0"
                                }]
                            }]

If you use dedicated roles for AWS Load Balancer Controller, then you see the service account’s AWS Identity and Access Management (IAM) role.

### Avoid unwanted changes

Don’t make out-of-band changes to any parameter of your load balancer. This includes changes from the Amazon EC2 console, the AWS CLI, or any tool that directly calls AWS APIs.

For example, you want to update security group rules. Use the **.spec.loadBalancerSourceRanges** or **service.beta.kubernetes.io/load-balancer-source-ranges** annotations. You can use these annotations to [restrict CIDR IP addresses for a load balancer](<https://repost.aws/knowledge-center/eks-cidr-ip-address-loadbalancer>). For more information on these annotations, see [Access control](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/#lb-source-ranges>) on the AWS Load Balancer Controller GitHub website.

Use only proper annotations in the manifest file to update timeout values, health check paths, certificate ARNs, and other properties. For all supported service and ingress annotations, see [Service annotations](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/>) and [Ingress annotations](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/>) on the AWS Load Balancer Controller GitHub website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
