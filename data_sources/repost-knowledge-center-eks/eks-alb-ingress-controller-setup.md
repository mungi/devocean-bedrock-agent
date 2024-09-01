Original URL: <https://repost.aws/knowledge-center/eks-alb-ingress-controller-setup>

# How do I set up an Application Load Balancer through the AWS Load Balancer Controller on an Amazon EC2 node group in Amazon EKS?

I want to set up an Application Load Balancer through the AWS Load Balancer Controller on an Amazon Elastic Compute Cloud (Amazon EC2) node group in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

Connect the AWS Load Balancer Controller to one of the following AWS service endpoints:

  * AWS Identity and Access Management (IAM)
  * Amazon EC2
  * AWS Certificate Manager (ACM)
  * Elastic Load Balancing (ELB)
  * Amazon Cognito
  * AWS WAF
  * AWS Shield



For the AWS Load Balancer Controller to work, you must have an outbound internet connection. For more information, see [How do I configure my subnets for an Amazon EKS cluster?](<https://repost.aws/knowledge-center/eks-cluster-subnet-configuration>)

To deploy the AWS Load Balancer Controller on AWS Fargate, see [How do I set up the AWS Load Balancer Controller on an Amazon EKS cluster for Fargate and deploy the 2048 game?](<https://repost.aws/knowledge-center/eks-alb-ingress-controller-fargate>)

## Resolution

### Tag your subnets to allow auto discovery

[Tag the Amazon Virtual Private Cloud (Amazon VPC) subnets](<https://repost.aws/knowledge-center/eks-vpc-subnet-discovery>) in your Amazon EKS cluster. This allows your AWS Load Balancer Controller to automatically discover subnets when you create the Application Load Balancer resource.

For public Application Load Balancers, you must have at least two public subnets in your cluster's VPC with the following tags:
    
    
    kubernetes.io/role/elb

For internal Application Load Balancers, you must have at least two private subnets in your cluster's VPC with the following tags:
    
    
    kubernetes.io/role/internal-elb

### Create an OIDC identity provider for your cluster

Use either eksctl or the AWS Management Console to [create an OpenID Connect (OIDC) identity provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>) to use with [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

Or, use the AWSL CLI to create an OIDC identity provider for your cluster. For example:
    
    
    ISSUER_URL=$(aws eks describe-cluster --name cluster-name \  --query "cluster.identity.oidc.issuer" --region region-name --output text)
    aws iam create-open-id-connect-provider \
      --url ${ISSUER_URL} \
      --thumbprint-list ca-thumbprint \
      --client-id-list sts.amazonaws.com \
      --region region-name

**Note:** Replace **cluster-name** with your cluster name, **region-name** with your AWS Region, and **ca-thumbprint** with the thumbprint of your root CA certificate. You can get the [thumbprint of the root CA certificate](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html>) that your cluster uses with **oidc.eks.region-name.amazonaws.com**.

### Create an IAM policy for the AWS Load Balancer Controller

The Amazon EKS policy that you create allows the AWS Load Balancer Controller to make calls to AWS APIs. When you grant access to AWS APIs, it's a best practice to use [AWS IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).

  1. Download an IAM policy for the AWS Load Balancer Controller from GitHub. Run one of the following commands based on your Region.  
All Regions except China Regions:
    
        ISSUER_URL=$(aws eks describe-cluster --name cluster-name \  --query "cluster.identity.oidc.issuer" --region region-name --output text)
    aws iam create-open-id-connect-provider \
      --url ${ISSUER_URL} \
      --thumbprint-list ca-thumbprint \
      --client-id-list sts.amazonaws.com \
      --region region-name

Beijing and Ningxia China Regions:
    
        curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy_cn.json

  2. To create an IAM policy that's named **AWSLoadBalancerControllerIAMPolicy** for your worker node instance profile, run the following command:
    
        aws iam create-policy \    --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://iam-policy.json

  3. Note the ARN of the policy that's returned in the output.

  4. Use the existing IAM role, or [create a new IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>) for the AWS Load Balancer Controller.  
**Note:** To use **eksctl** to create an IAM role, use the **—attach-policy-arn** parameter with the **AWSLoadBalancerControllerIAMPolicy** IAM policy's ARN.

  5. To attach **AWSLoadBalancerControllerIAMPolicy** to the IAM roles, run the following command:
    
        aws iam attach-role-policy \--policy-arn arn:aws:iam::111122223333:policy/AWSLoadBalancerControllerIAMPolicy \
    --role-name role-name

**Note:** Replace **111122223333** with your AWS account ID and **role-name** with your IAM role name.




### Deploy the AWS Load Balancer Controller

  1. [Verify that you have the required tags](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-subnet-tagging>) for the load balancer that's associated with your subnets.

  2. Install **cert-manager** so that you can inject the certificate configuration into the webhooks. Use Kubernetes 1.16 or later to run the following command:
    
        kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/$VERSION/cert-manager.yaml

  3. In the manifest file that you downloaded from GitHub, run the following command:
    
        curl -Lo ingress-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/$VERSION/v2_6_2_full.yaml

**Note:** Replace **$VERSION** with the AWS Load Balancer Controller version that you want to deploy, and modify the file name, such as **v2_6_2_full.yaml** for v2.6.2. For more information, see [The Kubernetes repository](<https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.6.2>) on GitHub. 

  4. Edit the **cluster-name** for your cluster. For example:
    
        spec:    
        containers:
        - args:
            - --cluster-name=your-cluster-name # edit the cluster name
            - --ingress-class=alb

  5. Update only the **ServiceAccount** section of only the file. For example:
    
        apiVersion: v1
    kind: ServiceAccount
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: aws-load-balancer-controller
      annotations:                                                                        # Add the annotations line
        eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/role-name              # Add the IAM role
      name: aws-load-balancer-controller
      namespace: kube-system

**Note:** Replace **111122223333** with your account ID and **role-name** with your IAM role name.

  6. To deploy the AWS Load Balancer Controller, run the following command:
    
        kubectl apply -f ingress-controller.yaml




### Deploy a sample application to test the AWS Load Balancer Controller

Deploy a sample application to verify that the AWS Load Balancer Controller creates a public Application Load Balancer because of the Ingress object.

  1. To deploy a game that's called 2048 as a sample application, run the following command:
    
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/$VERSION/docs/examples/2048/2048_full.yaml

**Note:** Replace **$VERSION** with the version (from the Kubernetes SIGs GitHub website) of the AWS Load Balancer Controller that you want to deploy.
  2. To verify that the Ingress resource was created, wait a few minutes, and then run the following command:
    
        kubectl get ingress/ingress-2048 -n game-2048

You receive output similar to the following example:
    
        NAME           CLASS    HOSTS   ADDRESS                                                                   PORTS   AGEingress-2048   <none>   *       k8s-game2048-ingress2-xxxxxxxxxx-yyyyyyyyyy.us-west-2.elb.amazonaws.com   80      2m32s

  3. If your Ingress isn't created after several minutes, then run the following command to view the AWS Load Balancer Controller logs:
    
        kubectl logs -n kube-system   deployment.apps/aws-load-balancer-controller

**Note:** The AWS Load Balancer Controller logs often show error messages to help you troubleshoot issues with your deployment.
  4. To see the sample application, open a web browser, and then go to the URL address from the output in step 2.
  5. To clean up the sample application, run the following command:
    
        kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/$VERSION/docs/examples/2048/2048_full.yaml

**Note:** Replace **$VERSION** with the version (from the Kubernetes SIGs GitHub website) of the AWS Load Balancer Controller that you want to deploy.



## Related information

[How do I troubleshoot load balancers created by the Kubernetes service controller in Amazon EKS?](<https://repost.aws/knowledge-center/eks-load-balancers-troubleshooting>)

[How can I troubleshoot issues when I use the AWS Load Balancer Controller to create a load balancer?](<https://repost.aws/knowledge-center/load-balancer-troubleshoot-creating>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
