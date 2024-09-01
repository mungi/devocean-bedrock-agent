Original URL: <https://repost.aws/knowledge-center/eks-apps-tls-to-activate-https>

# How do I use TLS certificates to activate HTTPS connections for my Amazon EKS applications?

I want to use TLS certificates to activate HTTPS connections for my Amazon Elastic Kubernetes Service (Amazon EKS) applications.

## Short description

To activate HTTPS connections for your Amazon EKS applications, complete the following tasks:

  * Get a valid TLS certificate for your custom domain.
  * Use the load balancer service type to expose your Kubernetes service, or use AWS Load Balancer Controller to expose your Kubernetes ingress object.
  * Associate your custom domain with the DNS of the load balancer.



## Resolution

### Get a valid TLS certificate for your custom domain

To get a valid TLS certificate for your custom domain, complete the following steps:

  1. [Request a public AWS Certificate Manager (ACM) certificate](<https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html>) for your custom domain, or upload your own TLS certificate to ACM.

  2. [Identify the ARN of the certificate](<https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-describe.html#gs-acm-describe-console>) that you want to use with the load balancer's HTTPS listener.

  3. To create a sample NGINX deployment, run the following command:
    
        $ kubectl create deploy web --image=nginx --port 80 --replicas=3

  4. To verify that Kubernetes pods are deployed on your Amazon EKS cluster, run the following command:
    
        $ kubectl get pods -l app=web

**Note:** The pods are labeled **app=web**. Use this label as a selector for the service object to identify a set of pods.




### Use the load balancer service type to expose your Kubernetes service

**Note:** To use the ingress object to expose your application, continue to the **Expose your Kubernetes service using the ingress object** section.

To use the load balancer service type to expose your Kubernetes service, complete the following steps:

  1. To create a service.yaml manifest file, use the service type **LoadBalancer** :
    
        cat <<EOF > loadbalancer.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: lb-service
      annotations:
        # Note that the backend talks over HTTP.
        service.beta.kubernetes.io/aws-load-balancer-type: external
        # TODO: Fill in with the ARN of your certificate.
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
        # Run TLS only on the port named "https" below.
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
        # By default In-tree controller will create a Classic LoadBalancer if you require a NLB uncomment below annotation.
        # service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    spec:
      selector:
        app: web
      ports:
      - name: http
        port: 80
        targetPort: 80
      - name: https
        port: 443
        targetPort: 80
      type: LoadBalancer
    EOF

  2. Edit the annotation **service.beta.kubernetes.io/aws-load-balancer-tls-cert** to include the ACM's ARN.

  3. To apply the **loadbalancer.yaml** file, run the following command:
    
        $ kubectl create -f loadbalancer.yaml

  4. Continue to the **Associate your custom domain with the DNS of the load balancer** section.




### Use the ingress object to expose your Kubernetes service

**Note:** The following resolution assumes that you've installed [AWS Load Balancer Controller](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>) in your Amazon EKS cluster. For more information, see [aws-load-balancer-controller](<https://github.com/kubernetes-sigs/aws-load-balancer-controller>) on the GitHub website.

To use the ingress object to expose your Kubernetes service, complete the following steps:

  1. Create a Kubernetes service of type **NodePort** based on the following example:
    
        cat  <<EOF  > ingressservice.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: web-nginx
    spec:
      ports:
        - port: 80
          targetPort: 80
          protocol: TCP
      type: NodePort
      selector:
        app: web
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: "web-nginx-ingress"
      annotations:
        # Below annotation is to specify if the loadbalancer is "internal" or "internet-facing"
        alb.ingress.kubernetes.io/scheme: internet-facing
        # TODO: Fill in with the ARN of your certificate.
        alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-2:xxxx:certificate/xxxxxx
        # TODO: Fill in the listening ports.
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
        # Set HTTP to HTTPS redirects. Every HTTP listener configured is redirected to below mentioned port over HTTPS.
        alb.ingress.kubernetes.io/ssl-redirect: '443'
      labels:
        app: web
    spec:
      ingressClassName: alb
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: "web-nginx"
                    port:
                      number: 80
    EOF

**Note:** The preceding ingress manifest listens on HTTP and HTTPS, then terminates TLS on Application Load Balancer, and then redirects HTTP to HTTPS.
  2. To apply the **ingressservice.yaml** file, run the following command:
    
        $ kubectl create -f ingressservice.yaml




### Associate your custom domain with the DNS of the load balancer

To associate your custom domain with the DNS of the load balancer, complete the following steps:

  1. To return the DNS URL of the service of type **LoadBalancer** , run the following command:
    
        $ kubectl get service

  2. To return the DNS URL of the service of type **Ingress** , run the following command:
    
        $ kubectl get ingress/web-nginx-ingress

  3. [Associate your custom domain name with your load balancer name](<https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/using-domain-names-with-elb.html#dns-associate-custom-elb>).

  4. In a web browser, test your custom domain with the following HTTPS protocol:
    
        https://yourdomain.com




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
