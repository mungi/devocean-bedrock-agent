Original URL: <https://repost.aws/knowledge-center/eks-vpc-subnet-discovery>

# How do I automatically discover the subnets that my Application Load Balancer uses in Amazon EKS?

I want to automatically discover the subnets that my Application Load Balancer uses in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

To identify the subnet that your Application Load Balancer uses, the Kubernetes Cloud Controller Manager (**cloud-controller-manager**) and AWS Load Balancer Controller (**aws-load-balancer-controller**) query a cluster's subnets. The query uses the following tag as a filter:
    
    
    kubernetes.io/cluster/cluster-name      shared

**Note:** Replace **cluster-name** with your Amazon EKS cluster's name.

To allow the AWS Load Balancer Controller to automatically discover the subnets that your Application Load Balancer uses, tag your subnets.

## **Resolution**

### Add tags to subnets

To tag your subnets, complete the following steps:

  1. Deploy the [AWS Load Balancer Controller add-on](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>) for your Amazon EKS cluster.

  2. Verify that the AWS Load Balancer Controller is installed:
    
        kubectl get deployment -n kube-system aws-load-balancer-controller

**Note:** If you're deploying in a different namespace, then replace **-n kube-system** with the appropriate namespace.

  3. Create a Kubernetes Ingress resource on your cluster with the following annotation:
    
        annotations:    kubernetes.io/ingress.class: alb

**Note:** The AWS Load Balancer Controller creates load balancers. The Ingress resource configures the Application Load Balancer to route HTTP(S) traffic to different pods within your cluster.

  4. Add either an **internal** or **internet-facing** annotation to specify where you want the Ingress to create your load balancer:
    
        alb.ingress.kubernetes.io/scheme: internal
    -or-
    alb.ingress.kubernetes.io/scheme: internet-facing

**Note:** Choose **internal** to create an internal load balancer, or **internet-facing** to create a public load balancer.

  5. Use tags to allow the AWS Load Balancer Controller to create a load balancer that automatically discovers your subnets. The tags can't have any leading or trailing spaces. For example:
    
        kubernetes.io/role/internal-elb                Set to 1 or empty tag value for internal load balancers
    kubernetes.io/role/elb                         Set to 1 or empty tag value for internet-facing load balancers

**Note:** You can use tags for auto discovery instead of the manual **alb.ingress.kubernetes.io/subnets** annotation.  
Example of a subnet with the correct tags for a cluster that has an internal load balancer:
    
        kubernetes.io/role/internal-elb          1

Example of a subnet with the correct tags for a cluster that has a public load balancer:
    
        kubernetes.io/role/elb                     1

**Note:** For cluster versions 1.18 and earlier, Amazon EKS adds the following tag to all subnets that are passed during cluster creation. The tag isn't added to version 1.19 clusters. If you use the tag and you update to cluster version 1.19, then you don't have to add the tag again. The tag stays on your subnet. 

You can use the following tag to control where an Application Load Balancer is allocated. For multiple clusters, use this tag in addition to the required tags to automatically allocate an Application Load Balancer in the EKS cluster: 
    
        kubernetes.io/cluster/$CLUSTER_NAME    shared

  6. Verify that your subnets have the correct tags:
    
        aws ec2 describe-subnets --subnet-ids your-subnet-xxxxxxxxxxxxxxxxx

  7. Deploy a sample application to verify that the AWS Load Balancer Controller creates an Application Load Balancer because of the Ingress object:
    
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full.yaml

  8. Verify that the Ingress resource is created and has an associated Application Load Balancer:
    
        kubectl get ingress/2048-ingress -n game-2048

Depending on the annotations (**alb.ingress.kubernetes.io/scheme:**) that you defined in the Ingress object and subnets, either an internal or internet-facing load balancer is created.




### Troubleshoot common tag errors

The following errors commonly occur when you use tags to automatically discover subnets.

**Permissions denied error**

You receive the following error message when your account's AWS Identity and Access Management (IAM) role for the AWS Load Balancer Controller doesn't have the required permissions:

"{"level":"error","ts":1621443417.9175518,"logger":"controller","msg":"Reconciler error","controller":"ingress","name":" ingress-2048","namespace":" game-2048","error":"couldn't auto-discover subnets: UnauthorizedOperation: You are not authorized to perform this operation.\n\tstatus code: 403, request id: 72ee57ae-f804-4f81-b069-8b04114b67b0"}"

To resolve this issue, complete the following steps:

  1. Verify that your service account is associated with the AWS Load Balancer Controller:
    
        $ kubectl get deploy aws-load-balancer-controller -n kube-system -o yaml | grep -i serviceAccount

You receive an output that's similar to the following one:
    
        serviceAccount: aws-load-balancer-controllerserviceAccountName: aws-load-balancer-controller

**Note:** If you're deploying in a different namespace, then replace **-n kube-system** with the appropriate namespace.

  2. Check which IAM role is attached to the service account that's associated with the AWS Load Balancer Controller:
    
        $ kubectl describe sa aws-load-balancer-controller -n kube-system | grep role-arn

You receive an output that's similar to the following one:
    
        annotations: eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxx:role/eksctl-cluster18-addon-iamserviceaccount-kub-Role1-xxxxxxxxxxxxx

  3. Grant all relevant permissions to your IAM role, such as [ec2:DescribeAvailabilityZones](<https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeAvailabilityZones.html>). For more information about how AWS Load Balancer Controller assumes an IAM role to perform API calls, see [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>). For a list of relevant permissions, see the [IAM JSON policy](<https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json>) on GitHub's AWS Load Balancer Controller web page.




**Single subnet discovery error**

You receive one of the following error messages when your AWS Load Balancer Controller doesn't discover at least one subnet:

"{"level":"error","ts":1608229710.3212903,"logger":"controller","msg":"Reconciler error","controller":"ingress","name":"ingress-2048","namespace":"game-2048","error":"couldn't auto-discover subnets: unable to resolve at least one subnet"}"

-or-

"kubebuilder/controller "msg"="Reconciler error" "error"="failed to build LoadBalancer configuration due to  
retrieval of subnets failed to resolve 2 qualified subnets. Subnets must contain the kubernetes.io/cluster/\u003ccluster name\u003e tag with a value of shared or owned and the kubernetes.io/role/elb tag signifying it should be used for ALBs Additionally, there must be at least 2 subnets with unique availability zones as required by ALBs. Either tag subnets to meet this requirement or use the subnets annotation on the ingress resource to explicitly call out what subnets to use for ALB creation. The subnets that did resolve were []" "controller"="alb-ingress-controller" "request"={"Namespace":"default","Name":"2048-ingress"}"

To resolve this issue, add the appropriate tags on your subnets to allow the AWS Load Balancer Controller to use auto-discovery to create a load balancer:

**Private subnets tags:**
    
    
    kubernetes.io/role/internal-elb                Set to 1 or empty tag value for internal load balancers

**Public subnets tags:**
    
    
    kubernetes.io/role/elb                         Set to 1 or empty tag value for internet-facing load balancers

**Note:** You can manually assign subnets to your load balancer with the **alb.ingress.kubernetes.io/subnets** annotation.

Tag your subnets with the following format without any leading or trailing spaces:

Key: **kubernetes.io/cluster/your-cluster-name**

Value: **shared** or **owned**

If you use the AWS Load Balancer Controller version v2.1.1 or earlier, then you must tag your subnets in the preceding format. Tagging is optional for versions 2.1.2 or later.

It's a best practice to tag a subnet in the following scenarios:

  * You have multiple clusters that run in the same virtual private cloud (VPC).
  * You have multiple AWS services that share subnets in a VPC.
  * You want more control over where load balancers are allocated for each cluster.



**Multiple subnet discovery errors**

You receive the following error message when your AWS Load Balancer Controller doesn't discover two or more qualified subnets:

"msg"="Reconciler error" "error"="failed to build LoadBalancer configuration due to failed to resolve 2 qualified subnet with at least 8 free IP Addresses for ALB  
{"level":"error","ts":1606329481.2930484,"logger":"controller","msg":"Reconciler error","controller":"ingress","name":"reciter-ing","namespace":"reciter","error":"InvalidSubnet: Not enough IP space available in subnet-xxxxxxxxxxxxxx. ELB requires at least 8 free IP addresses in each subnet.\n\tstatus code: 400, request id: 2a37780c-f411-xxxxx-xxxxx-xxxxxxxxx"}

To resolve this issue, complete the following steps:

  1. Confirm that you have at least two subnets in two different Availability Zones. This is a requirement to create an Application Load Balancer.  
**Note:** You can create a Network Load Balancer with a single subnet.
  2. For each subnet, specify a CIDR block with at least a **/27** bitmask (for example: **10.0.0.0/27**) and at least eight free IP addresses.
  3. Confirm that the [tags](<https://repost.aws/knowledge-center/eks-vpc-subnet-discovery>) on the subnets are formatted correctly. For example, tags can't have any leading or trailing spaces.



* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
