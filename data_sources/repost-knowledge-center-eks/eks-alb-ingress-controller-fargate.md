Original URL: <https://repost.aws/knowledge-center/eks-alb-ingress-controller-fargate>

# How do I set up the AWS Load Balancer Controller on an Amazon EKS cluster for Fargate and then deploy the 2048 game?

I want to set up the AWS Load Balancer Controller on an Amazon Elastic Kubernetes Service (Amazon EKS) cluster for AWS Fargate. Then, I want to deploy the 2048 game.

## Short description

You can set up AWS Load Balancer Controller without any existing Application Load Balancer (ALB) Ingress Controller deployments.

Before you set up the [AWS Load Balancer Controller](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>) on a new Fargate cluster, complete the following actions:

  * Uninstall the AWS ALB Ingress Controller for Kubernetes. The AWS Load Balancer Controller replaces the functionality of the AWS ALB Ingress Controller.
  * Use eksctl version 0.109.0 or greater. For more information, see [Installation](<https://eksctl.io/installation/>) on the eksctl website.
  * Install [Helm](<https://docs.aws.amazon.com/eks/latest/userguide/helm.html>) on the workstation.
  * Replace placeholder values in code snippets with your own values.



## Resolution

### Create an Amazon EKS cluster, service account policy, and role-based access control (RBAC) policies

To create a cluster and policies, do the following:

  1. To use **eksctl** to create an Amazon EKS cluster, run the following command:
    
        eksctl create cluster --name YOUR_CLUSTER_NAME --version 1.28 --fargate

**Note:** You don't need to [create a Fargate pod execution role](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-sg-pod-execution-role>) for clusters that use only Fargate pods **(--fargate**).

  2. Allow the cluster to use AWS Identity and Access Management (IAM) for service accounts with the following command:
    
        eksctl utils associate-iam-oidc-provider --cluster YOUR_CLUSTER_NAME --approve

**Note:** The **FargateExecutionRole** is the role that's used for the **kubelet** and **kube-proxy** to run your Fargate pod on. However, it's not the role used for the Fargate pod (that is, the **aws-load-balancer-controller**). For Fargate pods, you must use the IAM role for the service account. For more information, see [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).

  3. To download an IAM policy that allows the AWS Load Balancer Controller to make calls to AWS APIs on your behalf, run the following command:
    
        curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/install/iam_policy.json

  4. Create an IAM policy with the policy that you downloaded. Use the following command:
    
        aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

  5. Create a service account named **aws-load-balancer-controller** in the **kube-system** namespace for the AWS Load Balancer Controller. Use the following command:
    
        eksctl create iamserviceaccount \    
    --cluster=YOUR_CLUSTER_NAME \  
    --namespace=kube-system \  
    --name=aws-load-balancer-controller \  
    --attach-policy-arn=arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \  
    --override-existing-serviceaccounts \  
    --approve

  6. Run one of the following commands to verify that the new service role is created:
    
        eksctl get iamserviceaccount --cluster YOUR_CLUSTER_NAME --name aws-load-balancer-controller --namespace kube-system

-or-
    
        kubectl get serviceaccount aws-load-balancer-controller --namespace kube-system




### Install the AWS Load Balancer Controller with Helm

To install the AWS Load Balancer Controller, do the following:

  1. To add the Amazon EKS chart to Helm, run the following command:
    
        helm repo add eks https://aws.github.io/eks-charts

  2. Update the repo to pull the latest chart:
    
          helm repo update eks 

  3. Run following command to install the Helm chart . Note: Replace **clusterName** , **region** and **vpcId** with your values:
    
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller \      
    --set clusterName=YOUR_CLUSTER_NAME \  
    --set serviceAccount.create=false \  
    --set region=YOUR_REGION_CODE \  
    --set vpcId=<VPC_ID> \  
    --set serviceAccount.name=aws-load-balancer-controller \  
    -n kube-system

  4. Verify that the controller is installed successfully:
    
        $ kubectl get deployment -n kube-system aws-load-balancer-controller     

Sample output:
    
        NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
    aws-load-balancer-controller   2/2     2            2           84s




### Test the AWS Load Balancer Controller

Use the AWS Load Balancer Controller to create either an [Application Load Balancer](<https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html>) for Ingress or a [Network Load Balancer](<https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html>). You use one of these to create a k8s service. To deploy a example app called 2048 with Application Load Balancer Ingress, do the following:

  1. Create a Fargate profile that's required for the game deployment. Use the following command:
    
        eksctl create fargateprofile --cluster your-cluster --region your-region-code --name your-alb-sample-app --namespace game-2048

  2. To deploy the example game and verify that the AWS Load Balancer Controller creates an ALB Ingress resource, run the following command:
    
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/examples/2048/2048_full.yaml

  3. After a few minutes, verify that the Ingress resource was created with the following command:
    
        kubectl get ingress/ingress-2048 -n game-2048

You receive the following output:
    
        NAME           CLASS    HOSTS   ADDRESS. PORTS   AGE
    ingress-2048   <none>   *       k8s-game2048-ingress2-xxxxxxxxxx-yyyyyyyyyy.us-

**Note:** If your Ingress isn't created after several minutes, run the following command to view the AWS Load Balancer Controller logs:
    
        kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

The logs can contain error messages that help you diagnose issues with your deployment.

  4. To view the sample application, open a browser. Then, and navigate to the ADDRESS URL from the previous command output.  
**Note:** If you don't see the sample application, then wait a few minutes and refresh your browser.




### Deploy an example application

To deploy an example application with the Network Load Balancer IP address mode service, do the following:

  1. To create a Fargate profile, run the following command:
    
        eksctl create fargateprofile --cluster your-cluster --region your-region-code --name your-alb-sample-app --namespace game-2048

  2. To get the manifest to deploy the 2048 game, run the following command:
    
        curl -o 2048-game.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/examples/2048/2048_full.yaml

  3. In the manifest from **step 2** , delete this Ingress section:
    
        apiVersion: networking.k8s.io/v1kind: Ingress
    metadata:
      namespace: game-2048
      name: ingress-2048
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
    spec:ingressClassName: alb
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: service-2048           
                    port:
                      number: 80

  4. Modify the **Service** object:
    
        apiVersion: v1
    kind: Service
    metadata:
      namespace: game-2048
      name: service-2048
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-type: external
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    spec:
      ports:
        - port: 80
          targetPort: 80
          protocol: TCP
      type: LoadBalancer
      selector:
        app.kubernetes.io/name: app-2048

  5. To create the service and deployment manifest, run the following command:
    
        kubectl apply -f 2048-game.yaml

  6. To check for service creation and the DNS name of the Network Load Balancer, run the following command:
    
        kubectl get svc -n game-2048

You received the following output:
    
        NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                                PORT(S)        AGE
    service-2048   LoadBalancer   10.100.114.197   k8s-game2048-service2-xxxxxxxxxx-yyyyyyyyyy.us-east-2.elb.amazonaws.com   80:30159/TCP   23m

  7. Wait a few minutes until the load balancer is active. Then, check that you can reach the deployment. Open the fully qualified domain name (FQDN) of the NLB that's referenced in the **EXTERNAL-IP** section in a web browser.




### Troubleshoot the AWS Load Balancer Controller

If you have issues with the controller set up, then run the following commands:
    
    
    $ kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller
    $ kubectl get endpoints -n game-2048
    $ kubectl get ingress/ingress-2048 -n game-2048

The output from the logs command returns error messages (for example, with tags or subnets). These error messages can help you troubleshoot [common errors](<https://github.com/kubernetes-sigs/aws-alb-ingress-controller/issues>) from the Kubernetes GitHub website. The **get endpoints** command shows whether backed deployment pods are correctly registered. The **get ingress** commands shows whether Ingress resources are deployed. For more information, see [AWS Load Balancer Controller](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/>) on the Kubernetes website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
