Original URL: <https://repost.aws/knowledge-center/eks-kubernetes-dashboard-custom-path>

# How do I access the Kubernetes Dashboard on a custom path in Amazon EKS?

I want to access the Kubernetes dashboard on a custom path in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

To access the Kubernetes dashboard, you must complete the following:

1\. Create or use an existing self-signed certificate, and then upload the certificate to the AWS Certificate Manager (ACM).

2\. Deploy the NGINX Ingress Controller, and then expose it as a NodePort service.

3\. Create an Ingress object for the Application Load Balancer Ingress Controller. Have the Ingress object forward all the requests from the Application Load Balancer to the NGINX Ingress Controller that you deploy using a manifest file.

4\. Deploy the Kubernetes dashboard.

5\. Create an Ingress for the NGINX Ingress Controller.

Here's how the resolution works:

1\. The Application Load Balancer forwards all incoming traffic to the NGINX Ingress Controller.

2\. The NGINX Ingress Controller evaluates the path-pattern of the incoming request (for example, **/custom-path/additionalcustompath**).

3\. The NGINX Ingress Controller rewrites the URL to **/additionalcustompath** before forwarding the request to the **kubernetes-dashboard** service.

**Note:** This solution doesn't work on clusters running kubernetes versions earlier than 1.19.

## Resolution

### Create or use an existing self-signed certificate, and then upload the certificate to ACM

If your Application Load Balancer uses an existing ACM certificate, then skip to "Deploy the NGINX Ingress Controller and expose it as a NodePort service".

**Note:** The following steps apply to the Amazon Linux Amazon Machine Image (AMI) release 2018.03.

1\. Generate a self-signed certificate using OpenSSL:
    
    
    openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout kube-dash-private.key -out kube-dash-public.crt

**Important:** Provide a fully qualified domain for **Common Name**. Application Load Balancer allows only ACM certificates with fully qualified domain names to be attached to the listener 443.

The output looks similar to the following:
    
    
    Country Name (2 letter code) [XX]:
    State or Province Name (full name) []:
    Locality Name (eg, city) [Default City]:
    Organization Name (eg, company) [Default Company Ltd]:
    Organizational Unit Name (eg, section) []:
    Common Name (eg, your name or your server's hostname) []:kube-dashboard.com     ==>This is important
    Email Address []:

3\. Install the [AWS Command Line Interface (AWS CLI)](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html>) and [set up the credentials](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html>).

**Note:** If you receive errors when running AWS CLI commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

4\. Upload the private key and the certificate to the ACM in your AWS Region:
    
    
    aws acm import-certificate --certificate fileb://kube-dash-public.crt --private-key fileb://kube-dash-private.key --region us-east-1

**Note:** Replace **us-east-1** with your AWS Region.

The output looks similar to the following:
    
    
    {
    "CertificateArn": "arn:aws:acm:us-east-1:your-account:certificate/your-certificate-id"
    }

5\. Open the [ACM console](<https://console.aws.amazon.com/acm/>), and then verify that the domain name appears in your imported ACM certificate.

**Note:** If the domain name doesn't appear in the ACM console, it's a best practice to recreate the certificate with a valid fully qualified domain name.

### Deploy the NGINX Ingress Controller and expose it as a NodePort service

1\. Create the namespace ingress-nginx:
    
    
    kubectl create ns ingress-nginx

2\. Install [Helm version 3](<https://docs.aws.amazon.com/eks/latest/userguide/helm.html>).

3\. Use Helm to deploy the NGINX Ingress Controller:
    
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.service.type=NodePort

**Note:** For nginx-ingress controller to run on Fargate nodes, set allowPrivilegeEscalation: false in "nginx-ingress-nginx-controller" deployment

### Create an Ingress object for the Application Load Balancer Ingress Controller

Create an Ingress object using a manifest file. Have the Ingress object forward all requests from the Application Load Balancer Ingress Controller to the NGINX Ingress Controller that you deployed earlier.

1\. Deploy the [Application Load Balancer Ingress Controller](<https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html>).

2\. Create an Ingress object for the Application Load Balancer Ingress Controller based on the following alb-ingress.yaml file:
    
    
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: "alb-ingress"
      namespace: "ingress-nginx"
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:your-region:your-account-id:certificate/XXXX-XXXX-XXXX-XXXX-XXXXX
        alb.ingress.kubernetes.io/healthcheck-path: /dashboard/
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
        alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      labels:
        app: dashboard
    spec:
      ingressClassName: alb
      rules:
      - http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ssl-redirect
                port:
                  name: use-annotation
          - path: /
            pathType: Prefix
            backend:
              service:
                name: "nginx-ingress-nginx-controller"
                port:
                  number: 80

**Note:** Replace **alb.ingress.kubernetes.io/certificate-arn** with the Amazon Resource Name (ARN) of your ACM certificate. For Fargate, add "alb.ingress.kubernetes.io/target-type: ip" in annotations

The preceding manifest file uses the following annotations:

The "alb.ingress.kubernetes.io/scheme" annotation creates an internet-facing Application Load Balancer. The "alb.ingress.kubernetes.io/certificate-arn" annotation associates the ARN of your ACM certificate with the 443 listener of the Application Load Balancer. The "alb.ingress.kubernetes.io/listen-ports" annotation creates the listeners for ports 80 and 443. The "alb.ingress.kubernetes.io/actions.ssl-redirect" annotation redirects all the requests coming to ports 80 to 443. The "alb.ingress.kubernetes.io/healthcheck-path" annotation sets the health check path to /dashboard/.

3\. Apply the manifest file from the preceding step 2:
    
    
    kubectl apply -f alb-ingress.yaml

### Deploy the Kubernetes dashboard

To deploy the Kubernetes dashboard, see [Tutorial: Deploy the Kubernetes dashboard (web UI)](<https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html>).

### Create an Ingress for the NGINX Ingress Controller

1\. Create an Ingress for the NGINX Ingress Controller based on the following **ingress-dashboard.yaml** file:
    
    
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: dashboard
      namespace: kubernetes-dashboard
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        nginx.ingress.kubernetes.io/rewrite-target: /$2
        nginx.ingress.kubernetes.io/configuration-snippet: |
          rewrite ^(/dashboard)$ $1/ redirect;
    spec:
      ingressClassName: nginx
      rules:
      - http:
          paths:
          - path: /dashboard(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443

**Note:** The "nginx.ingress.kubernetes.io/rewrite-target" annotation rewrites the URL before forwarding the request to the backend pods. In /**dashboard(/|$)(.*)** for **path, (.*)** stores the dynamic URL that's generated while accessing the Kubernetes dashboard. The "nginx.ingress.kubernetes.io/rewrite-target" annotation replaces the captured data in the URL before forwarding the request to the **kubernetes-dashboard** service. The "nginx.ingress.kubernetes.io/configuration-snippet" annotation rewrites the URL to add a trailing slash ("/") only if **ALB-URL/dashboard** is accessed.

2\. Apply the manifest file **ingress-dashboard.yaml** :
    
    
    kubectl apply -f ingress-dashboard.yaml

3\. Check the Application Load Balancer URL in the **ADDRESS** of the **alb-ingress** that you created earlier:
    
    
    kubectl get ingress alb-ingress -n ingress-nginx

You can now access the Kubernetes dashboard using **ALB-URL/dashboard/**. If you access **ALB-URL/dashboard** , then a trailing slash ("/") is automatically added to the URL.

### Clean up the resources that you created earlier

1\. Delete the ingress for the NGINX Ingress Controller:
    
    
    helm uninstall nginx -n ingress-nginx

2\. Delete the Kubernetes dashboard components and the Metrics Server:
    
    
    kubectl delete -f eks-admin-service-account.yaml
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
    kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml>

3\. Delete the **alb-ingress** :
    
    
    kubectl delete -f alb-ingress.yaml

**Note:** If you created AWS Identity and Access Management (IAM) resources, then you can delete the [IAM role](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_manage_delete.html>) and [IAM policy](<https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-delete.html>).

4\. Delete the AWS Load Balancer Controller:
    
    
    helm uninstall aws-load-balancer-controller -n kube-system

5\. Delete the **ingress-ngix** namespace:
    
    
    kubectl delete ns ingress-nginx

6\. To delete the ACM certificate that you created, run the following command:
    
    
    aws acm delete-certificate \
        --certificate-arn arn:aws:acm:us-east-1:your-account-id:certificate/XXXX-XXXX-XXXX-XXXX-XXXXX \
        --region us-east-1

**Note:** Replace **certificate-arn** with your certificate ARN. Replace **us-east-1** with your AWS Region. Replace **your-account-id** with your account ID.

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
