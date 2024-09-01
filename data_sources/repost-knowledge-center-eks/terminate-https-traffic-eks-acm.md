Original URL: <https://repost.aws/knowledge-center/terminate-https-traffic-eks-acm>

# How do I terminate HTTPS traffic on Amazon EKS workloads with ACM?

I want to terminate HTTPS traffic on Amazon Elastic Kubernetes Service (Amazon EKS) workloads with AWS Certificate Manager (ACM).

## Short description

To terminate HTTPS traffic at the Elastic Load Balancing level for a Kubernetes Service object, you must:

  1. Request a public ACM certificate for your custom domain.
  2. Publish your Kubernetes service with the **type** field set to **LoadBalancer**.
  3. Specify the [Amazon Resource Name (ARN)](<https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html>) of your ACM certificate on your Kubernetes service using the [service.beta.kubernetes.io/aws-load-balancer-ssl-cert](<https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws>) annotation from the Kubernetes website. The annotation allows the Kubernetes API server to associate that certificate with the Classic Load Balancer when it's created.
  4. Associate your custom domain with the load balancer.



The following resolution assumes that:

  * You have an active Amazon EKS cluster with associated worker nodes.
  * You are working with a Classic Load Balancer.



**Note:** To use an Application Load Balancer, you must deploy [application load balancing on Amazon EKS](<https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html>).

**Note:** Terminating TLS connections on a Network Load Balancer is supported only in Kubernetes 1.15 or greater. For more information, see [Support TLS termination with AWS NLB](<https://github.com/kubernetes/kubernetes/issues/73297>) on the Kubernetes website.

## Resolution

1\. [Request a public ACM certificate](<https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html>) for your custom domain.

2\. Identify the [ARN of the certificate](<https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-describe.html#gs-acm-describe-console>) that you want to use with the load balancer's HTTPS listener.

3\. To identify the nodes registered to your Amazon EKS cluster, run the following command in the environment where [kubectl is configured](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>):
    
    
    $ kubectl get nodes

4\. In your text editor, create a **deployment.yaml** manifest file based on the following:
    
    
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo-deployment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: echo-pod
      template:
        metadata:
          labels:
            app: echo-pod
        spec:
          containers:
          - name: echoheaders
            image: k8s.gcr.io/echoserver:1.10
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 8080

5\. To create a Kubernetes **Deployment** object, run the following command:
    
    
    $ kubectl create -f deployment.yaml

6\. To verify that Kubernetes pods are deployed on your Amazon EKS cluster, run the following command:
    
    
    $ kubectl get pods

**Note:** The pods are labeled **app=echo-pod**. You can use this label as a selector for the **Service** object to identify a set of pods.

7\. In your text editor, create a **service.yaml** manifest file based on the following example. Then, edit the **service.beta.kubernetes.io/aws-load-balancer-ssl-cert** annotation to provide the ACM ARN from step 2.
    
    
    apiVersion: v1
    kind: Service
    metadata:
      name: echo-service
      annotations:
        # Note that the backend talks over HTTP.
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
        # TODO: Fill in with the ARN of your certificate.
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
        # Only run SSL on the port named "https" below.
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
    spec:
      selector:
        app: echo-pod
      ports:
      - name: http
        port: 80
        targetPort: 8080
      - name: https
        port: 443
        targetPort: 8080
      type: LoadBalancer

8\. To create a **Service** object, run the following command:
    
    
    $ kubectl create -f service.yaml

9\. To return the DNS URL of the service of type **LoadBalancer** , run the following command:
    
    
    $ kubectl get service

**Note:** If you have numerous active services running in your cluster, then get the URL of the correct service of type **LoadBalancer** from the command output.

10\. Open the [Amazon Elastic Compute Cloud (Amazon EC2) console](<https://console.aws.amazon.com/ec2/>), and then choose **Load Balancers**.

11\. Select your load balancer, and then choose **Listeners**.

12\. For **Listener ID** , confirm that your load balancer port is set to **443**.

13\. For **SSL Certificate** , confirm that the SSL certificate that you defined in the YAML file is attached to your load balancer.

14\. [Associate your custom domain name with your load balancer name](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/using-domain-names-with-elb.html#dns-associate-custom-elb>).

15\. In a web browser, test your custom domain with the following HTTPS protocol:
    
    
    https://yourdomain.com

A successful response returns a webpage with details about the client. This response includes the hostname, pod information, server values, request information, and request headers.

**Important:** You can't install certificates with 4096-bit RSA keys or EC keys on your load balancer through integration with ACM. To use the keys with your load balancer, you must upload certificates with 4096-bit RSA or EC keys to AWS Identity and Access Management (IAM). Then, use the corresponding ARN with the **service.beta.kubernetes.io/aws-load-balancer-ssl-cert** annotation.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
