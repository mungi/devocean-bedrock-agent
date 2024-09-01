Original URL: <https://repost.aws/knowledge-center/eks-access-kubernetes-services>

# How do I provide external access to multiple Kubernetes services in my Amazon EKS cluster?

I want to provide external access to multiple Kubernetes services in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

Use the NGINX ingress controller or AWS Load Balancer Controller for Kubernetes to provide external access to multiple Kubernetes services in your Amazon EKS cluster. The NGINX ingress controller is maintained primarily by NGINX. To check for issues with the NGINX ingress controller, see the [list of issues](<https://github.com/kubernetes/ingress-nginx/issues>) on the GitHub website. The AWS Load Balancer Controller is maintained by Amazon Web Services (AWS). To check for issues with AWS Load Balancer Controller, see the [list of issues](<https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues>) on the GitHub website.

**Important:** The ingress controller and [IngressClass](<https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class>) (from the Kubernetes website) aren't the same as the [Ingress](<https://kubernetes.io/docs/concepts/services-networking/ingress/>) (from the Kubernetes website). The Ingress is a Kubernetes resource that exposes HTTP and HTTPS routes from outside the cluster to the services within the cluster. The ingress controller usually fulfills the Ingress with a load balancer. You can't use Ingress without an ingress controller. The **IngressClass** is used to identify which ingress controller to use for fulfilling the Ingress object request.

**Prerequisite:** [Install the AWS Load Balancer Controller](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>). It's a best practice to use the AWS Load Balancer Controller to create and manage a Network Load Balancer for the **LoadBalancer** type service objects in Amazon EKS.

## Resolution

The following resolution uses the [kubernetes/ingress-nginx](<https://github.com/kubernetes/ingress-nginx>) ingress controller on the Kubernetes GitHub website. The other ingress controller that's available for public use is the [nginxinc/kubernetes-ingress](<https://github.com/nginxinc/kubernetes-ingress>) on the NGINX GitHub website.

### Deploy the NGINX ingress controller for Kubernetes

You can deploy the NGINX ingress controller for Kubernetes by either transmission control protocol (TCP) or transport layer security (TLS).

**Note:** The following resolution is tested on Amazon EKS version 1.22, NGINX ingress controller version 1.3.0, and AWS Load Balancer Controller version 2.4.3.

**(Option 1) NGINX ingress controller with TCP on Network Load Balancer**

1\. Get the YAML file to deploy the following Kubernetes objects: **namespace** , **serviceaccounts** , **configmap** , **clusterroles** , **clusterrolebindings** , **roles** , **rolebindings** , **services** , **deployments** , **ingressclasses** , and **validatingwebhookconfigurations**.
    
    
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml

2\. Edit the file. Then, in the **ingress-nginx-controller** service object section replace all service.beta.kubernetes.io annotations with following:
    
    
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"

3\. Apply the manifest:
    
    
    kubectl apply -f deploy.yaml

Example output:
    
    
    namespace/ingress-nginx created 
    serviceaccount/ingress-nginx created 
    configmap/ingress-nginx-controller created 
    clusterrole.rbac.authorization.k8s.io/ingress-nginx created 
    clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created 
    role.rbac.authorization.k8s.io/ingress-nginx created 
    rolebinding.rbac.authorization.k8s.io/ingress-nginx created 
    service/ingress-nginx-controller-admission created 
    service/ingress-nginx-controller created 
    deployment.apps/ingress-nginx-controller created 
    ingressclass.networking.k8s.io/nginx created
    validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created 
    serviceaccount/ingress-nginx-admission created 
    clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created 
    clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created

**(Option 2)** **NGINX** **ingress controller TLS termination on Network Load Balancer**

By default, the previous solution terminates TLS in the NGINX ingress controller. You can also configure the NGINX Ingress service to terminate TLS at the Network Load Balancer.

1\. Download the **deploy.yaml** template:
    
    
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/nlb-with-tls-termination/deploy.yaml

2\. Edit the file. Then, in the **ingress-nginx-controller** service object section, replace all **service.beta.kubernetes.io** annotations with following:
    
    
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:XXXXXXXX:certificate/XXXXXX-XXXXXXX-XXXXXXX-XXXXXXXX
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"

**Note:** Make sure to include your ARN for **service.beta.kubernetes.io/aws-load-balancer-ssl-cert**.

3\. Edit the file, and change the Amazon Virtual Private Cloud (Amazon VPC) CIDR for the Kubernetes cluster:
    
    
    proxy-real-ip-cidr: XXX.XXX.XXX/XX

4\. Apply the manifest:
    
    
    kubectl apply -f deploy.yaml

**Note:** The previous manifest uses **ExternalTrafficPolicy** as **local** to preserve the source (client) IP address. Using this configuration with a custom DHCP name in the Amazon VPC causes an issue. To prevent the issue from occurring, apply the following patch to the **kube-proxy** :
    
    
    kubectl edit daemonset kube-proxy -n kube-system

5\. Edit the manifest to include the following snippet:
    
    
    spec:
      template:
        spec:
          containers:
            - name: kube-proxy
              command:
                - kube-proxy
                - --hostname-override=$(NODE_NAME)
                - --v=2
                - --config=/var/lib/kube-proxy-config/config
               env:
                - name: NODE_NAME
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: spec.nodeName

### Verify the deployed resources

**AWS Load Balancer controller**

Command:
    
    
    kubectl get all -n kube-system --selector app.kubernetes.io/instance=aws-load-balancer-controller

Example output:
    
    
    NAME                                                READY   STATUS    RESTARTS   AGE   IP               NODE                                           NOMINATED NODE   READINESS GATES
    pod/aws-load-balancer-controller-85cd8965dc-ctkjt   1/1     Running   0          48m   192.168.37.36    ip-192-168-59-225.us-east-2.compute.internal   none             none 
    pod/aws-load-balancer-controller-85cd8965dc-wpwx9   1/1     Running   0          48m   192.168.53.110   ip-192-168-59-225.us-east-2.compute.internal   none&gt;         none 
    NAME                                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR 
    service/aws-load-balancer-webhook-service   ClusterIP   10.100.154.44   none          443/TCP   19h   app.kubernetes.io/instance=aws-load-balancer-controller,app.kubernetes.io/name=aws-load-balancer-controller 
    NAME                                           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                   IMAGES                                                                                    SELECTOR 
    deployment.apps/aws-load-balancer-controller   2/2     2            2           19h   aws-load-balancer-controller 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.0   app.kubernetes.io/instance=aws-load-balancer-controller,app.kubernetes.io/name=aws-load-balancer-controller 
    NAME                                                      DESIRED   CURRENT   READY   AGE   CONTAINERS                     IMAGES                                                                                    SELECTOR 
    replicaset.apps/aws-load-balancer-controller-85cd8965dc   2         2         2       19h   aws-load-balancer-controller   602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.0   app.kubernetes.io/instance=aws-load-balancer-controller,app.kubernetes.io/name=aws-load-balancer-controller,pod-template-hash=85cd8965dc

**NGINX ingress controller**

Command:
    
    
    kubectl get all -n ingress-nginx --selector app.kubernetes.io/instance=ingress-nginx

Example output:
    
    
    NAME                                           READY  STATUS   RESTARTS  AGE   IP               NODE                                           NOMINATED NODE  READINESS GATES
    pod/ingress-nginx-controller-54d8b558d4-k4pdf  1/1    Running  0         56m   192.168.46.241   ip-192-168-59-225.us-east-2.compute.internal   none            none
    NAME                                        TYPE           CLUSTER-IP      EXTERNAL-IP                                                                     PORT(S)                      AGE   SELECTOR
    service/ingress-nginx-controller            LoadBalancer   10.100.99.129   ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80:32578/TCP,443:30724/TCP   15h   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
    service/ingress-nginx-controller-admission  ClusterIP      10.100.190.61   none                                                                            443/TCP                      15h   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
    NAME                                       READY   UP-TO-DATE   AVAILABLE    AGE   CONTAINERS   IMAGES                                                                                                               SELECTOR
    deployment.apps/ingress-nginx-controller   1/1     1            1            15h   controller   k8s.gcr.io/ingress-nginx/controller:v1.1.1@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
    NAME                                                  DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                                                                                                               SELECTOR
    replicaset.apps/ingress-nginx-controller-54d8b558d4   1         1         1       15h   controller   k8s.gcr.io/ingress-nginx/controller:v1.1.1@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx,pod-template-hash=54d8b558d4
    NAME                                       COMPLETIONS   DURATION   AGE   CONTAINERS   IMAGES                                                                                                                         SELECTOR
    job.batch/ingress-nginx-admission-create   1/1           2s         15h   create       k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660   controller-uid=242bdf56-de16-471d-a691-1ca1dbc10a41
    job.batch/ingress-nginx-admission-patch    1/1           2s         15h   patch        k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660   controller-uid=a9e710d2-5001-4d40-a435-ddc8993bfe42

**IngressClass**

Command:
    
    
    kubectl get ingressclass

Example output:
    
    
    NAME    CONTROLLER             PARAMETERS                             AGE 
    alb     ingress.k8s.aws/alb    IngressClassParams.elbv2.k8s.aws/alb   19h 
    nginx   k8s.io/ingress-nginx   none                                   15h

### Test the deployment setup

**Note:** The following step is running two microservices. The microservices are exposed internally with **Kubernetes** as the default type.

1\. Set up your deployments or microservices. For example, **hostname-app** and **apache-app**.

Example of a **hostname-app-svc.yaml** file for **hostname-app** :
    
    
    apiVersion: apps/v1 
    kind: Deployment 
    metadata:
      name: hostname-app
      namespace: default 
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: hostname-app
      template:
        metadata:
          labels:
            app: hostname-app
        spec:
          containers:
          - name: hostname-app
            image: k8s.gcr.io/serve_hostname:1.1 
    
    --- 
    apiVersion: v1 
    kind: Service 
    metadata:
      name: hostname-svc
      namespace: default 
    spec:
      ports:
      - port: 80
        targetPort: 9376
        protocol: TCP
      selector:
        app: hostname-app

Example of an **apache-app-svc.yaml** file for **apache-app** :
    
    
    apiVersion: apps/v1 
    kind: Deployment 
    metadata:
      name: apache-app
      namespace: default 
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: apache-app
      template:
        metadata:
          labels:
            app: apache-app
        spec:
          containers:
          - name: apache-app
            image: httpd:latest
            ports:
            - containerPort: 80 
    
    --- 
    apiVersion: v1 
    kind: Service 
    metadata:
      name: apache-svc
      namespace: default
      labels: 
    spec:
      ports:
      - port: 80
        targetPort: 80
        protocol: TCP
      selector:
        app: apache-app

2\. Apply your configurations.

hostname-app:
    
    
    kubectl apply -f hostname-app-svc.yaml

apache-app:
    
    
    kubectl apply -f apache-app-svc.yaml

3\. Verify that the resources are created.

**Deployments**

Command:
    
    
    kubectl get deployment hostname-app apache-app -n default

Example output:
    
    
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE 
    hostname-app   2/2     2            2           29m
    apache-app     2/2     2            2           29m

**Services**

Command:
    
    
    kubectl get svc apache-svc hostname-svc -n default

Example output:
    
    
    NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE 
    apache-svc     ClusterIP   10.100.73.51    none          80/TCP    29m 
    hostname-svc   ClusterIP   10.100.100.44   none          80/TCP    29m

### Test the NGINX ingress controller

1\. Access the DNS URL of the load balancer that you retrieved from the command line:
    
    
    curl -I ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com

Example output:
    
    
    HTTP/1.1 404 Not Found 
    Date: Thu, 03 Mar 2022 14:03:11 GMT 
    Content-Type: text/html 
    Content-Length: 146 
    Connection: keep-alive

**Note:** The default server returns a **404 Not Found** page for all domain requests that don't have defined ingress rules. Based on the defined rules, the ingress controller doesn't divert traffic to the specified backend service unless the request matches the configuration. Because the host field is configured for the Ingress object, you must supply the **Host** header of the request with the same hostname. In a testing environment, use a curl flag to provide the **Host** header. In a production environment, map the load balancer DNS name to the hostname on any DNS provider, such as Amazon Route 53.

2\. Implement the ingress so that it interfaces with your services using a single load balancer provided by the NGINX ingress controller.

Example **micro-ingress.yaml** :
    
    
    apiVersion: networking.k8s.io/v1 
    kind: Ingress 
    metadata:
      name: micro-ingress
      namespace: default
      annotations: 
        kubernetes.io/ingress.class: nginx 
    spec:
      rules:
        - host: hostname.mydomain.com
          http:
            paths:
            - backend:
                service:
                  name: hostname-svc
                  port:
                    number: 80
              path: /
              pathType: Prefix
      - host: apache.mydomain.com
        http:
          paths:
          - backend:
              service:
                name: apache-svc
                port:
                  number: 80
            path: /
            pathType: Prefix

**Note:** For more information, see [Name based virtual hosting](<https://kubernetes.io/docs/concepts/services-networking/ingress/#name-based-virtual-hosting>) (from the Kubernetes website).

3\. Verify that the resource is created.

**Ingress**

Command:
    
    
    kubectl get ingress -n default

Example output:
    
    
    NAME           CLASS   HOSTS                                       ADDRESS                                                                         PORTS   AGE 
    micro-ingress  none    hostname.mydomain.com,apache.mydomain.com   ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80      29m

4\. Add the **Host** header to the request.

First configured domain:
    
    
    curl -i -H "Host: hostname.mydomain.com" http://aaa71bxxxxx-11xxxxx10.us-east-2.elb.amazonaws.com/

Example output:
    
    
    HTTP/1.1 200 OK Date: Sat, 26 Mar 2022 18:50:38 GMT Content-Type: text/plain; charset=utf-8 Content-Length: 29 Connection: keep-alive

Second configured domain:
    
    
    curl -i -H "Host: apache.mydomain.com" http://aaa71bxxxxx-11xxxxx10.us-east-2.elb.amazonaws.com/

Example output:
    
    
    HTTP/1.1 200 OK 
    Date: Sat, 26 Mar 2022 18:51:00 GMT 
    Content-Type: text/html 
    Content-Length: 45 
    Connection: keep-alive 
    Last-Modified: Mon, 11 Jun 2007 18:53:14 GMT 
    ETag: "2d-432a5e4a73a80" 
    Accept-Ranges: bytes

After adding the **Host** header, the ingress controller redirects traffic to the backend configured service as it matches the configuration that's defined in the Ingress.

To keep the same domain name but divert the traffic based on the path that's accessed, you must add path-based routing with the Ingress.

For example:
    
    
    apiVersion: networking.k8s.io/v1 
    kind: Ingress 
    metadata:
      name: path-ingress
      namespace: default
      annotations:
        kubernetes.io/ingress.class: nginxd
        nginx.ingress.kubernetes.io/rewrite-target: / 
    spec:
      rules:
      - host: mydomain.com
        http:
          paths:
          - backend:
              service:
                name: hostname-svc
                port:
                  number: 80
            path: /hostname
            pathType: Prefix
      - host: mydomain.com
        http:
          paths:
          - backend:
              service:
                name: apache-svc
                port:
                  number: 80
            path: /apache
            pathType: Prefix

**Note:** If requests have **mydomain.com** as the **Host** header, then the preceding example returns only the 200 response. The requests are accessed on either the **/hostname** or **/apache paths**. For all other requests, 404 responses are returned.

5\. Verify that the path-based routing is added:

Command:
    
    
    kubectl get ingress -n default

Output:
    
    
    NAME            CLASS  HOSTS                                       ADDRESS                                                                         PORTS  AGE
    micro-ingress   none   hostname.mydomain.com,apache.mydomain.com   ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80     164m
    path-ingress    none   mydomain.com,mydomain.com                   ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80     120m

Command:
    
    
    curl -i -H "Host: mydomain.com" http://aaa71bxxxxx-11xxxxx10.us-east-2.elb.amazonaws.com/hostname

-or-
    
    
    curl -i -H "Host: mydomain.com" http://aaa71bxxxxx-11xxxxx10.us-east-2.elb.amazonaws.com/apache

### Test the ingress using the AWS Load Balancer controller

1\. Launch the Application Load Balancer using the following example Ingress manifest:
    
    
    apiVersion: networking.k8s.io/v1 
    kind: Ingress 
    metadata:
      name: micro-ingress-alb
      namespace: default
      annotations:
        kubernetes.io/ingress.class: alb 
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip 
    spec:
      rules:
      - host: alb.hostname.mydomain.com
        http:
          paths:
          - backend:
              service:
                name: hostname-svc
                port:
                  number: 80
            path: /
            pathType: Prefix
       - host: alb.apache.mydomain.com
         http:
           - backend:
                service:
                  name: apache-svc
                  port:
                    number: 80
             path: /
             pathType: Prefix

2\. Verify that the Application Load Balancer launches.

Command:
    
    
    kubectl get ingress -n default

Output:
    
    
    NAME               CLASS  HOSTS                                               ADDRESS                                                                         PORTS  AGE
    micro-ingress      none   hostname.mydomain.com,apache.mydomain.com           ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80     164m
    micro-ingress-alb  none   alb.hostname.mydomain.com,alb.apache.mydomain.com   k8s-default-microing-8a252bde81-1907206594.us-east-2.elb.amazonaws.com          80     18m
    path-ingress       none   mydomain.com,mydomain.com                           ad9bba7a8239a475297d24bd2f617782-a579e639079f8270.elb.us-east-2.amazonaws.com   80     120m

Request based on first configured domain:
    
    
    curl -i -H "Host: alb.hostname.mydomain.com" http://k8s-default-microing-8a252bde81-1907206594.us-east-2.elb.amazonaws.com

Example output:
    
    
    HTTP/1.1 200 OK Date: Sat, 26 Mar 2022 20:46:02 GMT Content-Type: text/plain; charset=utf-8 Content-Length: 29 Connection: keep-alive

Request based on second configured domain:
    
    
    curl -i -H "Host: alb.apache.mydomain.com" http://k8s-default-microing-8a252bde81-1907206594.us-east-2.elb.amazonaws.com

Example output:
    
    
    HTTP/1.1 200 OK 
    Date: Sat, 26 Mar 2022 20:46:14 GMT 
    Content-Type: text/html Content-Length: 45 
    Connection: keep-alive 
    Server: Apache/2.4.53 (Unix) 
    Last-Modified: Mon, 11 Jun 2007 18:53:14 GMT 
    ETag: "2d-432a5e4a73a80" 
    Accept-Ranges: bytes

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
