Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-unhealthy-targets-nlb>

# How do I troubleshoot unhealthy targets for Network Load Balancers in Amazon EKS?

I want to resolve unhealthy targets for Network Load Balancers in my Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

The following are common reasons why the targets for your Network Load Balancer are unhealthy:

  * The health check is incorrectly configured.
  * There's an unexpected exception from the pod.
  * A Network Load Balancer with the externalTrafficPolicy set to local with a custom Amazon VPC DNS on the DHCP options set. 



## Resolution

### Verify if the target group is an IP address or instance

Run the following command:
    
    
    kubectl get service service_name -o yaml

**Note:** Replace **service_name** with your service's name.

If the **service.beta.kubernetes.io/aws-load-balancer-nlb-target-type** annotation isn't present, then the default target type is an instance.

### Verify that the health check is correctly configured

Check which Elastic Load Balancing (ELB) annotations are configured for your service. For more information on annotations, see [Service](<https://kubernetes.io/docs/concepts/services-networking/service/#other-elb-annotations>) on the Kubernetes website.

Run the following command to get a list of annotations:
    
    
    kubectl get service service_name -o yaml

Example output:
    
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"# The number of successive successful health checks required for a backend to be considered healthy for traffic. Defaults to 2, must be between 2 and 10
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "3"
    # The number of unsuccessful health checks required for a backend to be considered unhealthy for traffic. Defaults to 6, must be between 2 and 10
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "20"
    # The approximate interval, in seconds, between health checks of an individual instance. Defaults to 10, must be between 5 and 300
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "5"
    # The amount of time, in seconds, during which no response means a failed health check. This value must be less than the service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval value. Defaults to 5, must be between 2 and 60
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: TCP
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: traffic-port
    # can be integer or traffic-port
    
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/" 
    # health check path for HTTP(S) protocols
    

If the annotations are incorrectly configured, then the targets can be unhealthy.

### Manually initiate the health check from a host machine that runs in the Amazon VPC

For instance target types, run the following **curl** command with **NodePort** :
    
    
    curl-ivk node_IP:NodePort

**Note:** Replace **node_IP** with your node's IP address.

For IP address target types, run the following **curl** command:
    
    
    curl -ivk pod_IP:pod_port

**Note:** Replace **pod_IP** with your pod's IP address. Replace **pod_port** with the name of the port on which the application listens inside the container.

### Check for an unexpected exception from the pod

**Instance target type**

  1. Check the service specification for the current health check configuration annotations. For a full list, see [health check configuration annotations](<https://github.com/kubernetes/kubernetes/blob/297faec79a38d61d18aef7145e4d13c408dd63a2/staging/src/k8s.io/legacy-cloud-providers/aws/aws.go#L190-L223>) on the GitHub website:
    
        kubectl get service service_name -o yaml

  2. Check if there are endpoints to verify that there are pods behind the service:
    
        kubectl get endpoints service_name -o yaml

  3. If no endpoints exist for the service, then check that the pod labels and service labels match:
    
        kubectl describe servicekubectl describe pod pod_name or kubectl get pod --show-labels

Note: Replace **pod_name** with your pod's name.

  4. Check if the pods are in **Running** status:
    
        kubectl get pod -o wide

  5. Check the pods' statuses to verify that the pods are can run without any restarts:
    
        kubectl get pods -o wide

  6. If there are restarts, then collect the pod logs to determine the cause:
    
        kubectl logs pod_namekubectl logs pod_name --previous

  7. Log in to a host machine in the Amazon VPC where you can communicate with the node. Then, use the **curl** command with **NodePort** to check if the pods return the expected HTTP status code:
    
        curl node_IP:NodePort

If the **curl** command didn't return the expected HTTP status code, then the backend pods don't return the expected HTTP status code.

  8. Use the same host machine to connect to the pod's IP address and check if the pod is correctly configured:
    
        curl pod_IP:pod_port

If the curl command didn't return the expected HTTP status code, then the pod isn't correctly configured.




**Note:** If the service's [externalTrafficPolicy](<https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip>) (from the Kubernetes website) is set to **Local** , then only the nodes where the service's backend pods are running are seen as healthy targets.

**IP address target type**

  1. Check the service specification for the current health check configuration annotations. For a list, see [health check configuration annotations](<https://github.com/kubernetes/kubernetes/blob/297faec79a38d61d18aef7145e4d13c408dd63a2/staging/src/k8s.io/legacy-cloud-providers/aws/aws.go#L190-L223>) on the GitHub website.
    
        kubectl get service service_name -o yaml

  2. Log in to a host machine in the Amazon VPC and use the **curl** command to communicate with pod's IP address:
    
        curl pod_IP:pod_port

If the **curl** command didn't return the expected HTTP status code, then the pod isn't correctly configured.




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
