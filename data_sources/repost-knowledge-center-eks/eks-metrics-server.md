Original URL: <https://repost.aws/knowledge-center/eks-metrics-server>

# Why can't I collect metrics from containers, pods, or nodes using Metrics Server in Amazon EKS?

I can't collect metrics from containers, pods, or nodes with Metrics Server in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

In Amazon EKS, Metrics Server isn't installed by default. If you recently created your cluster and can't collect metrics using Metrics Server, then confirm that you [deployed the Metrics Server application to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html>).

If you still can't collect metrics with Metrics Server, then complete the steps in the following sections:

  * Check whether you can retrieve metrics from your cluster's nodes and pods.
  * Check if the **APIService** is available and can handle requests.
  * Check GitHub for common issues.
  * Check your Horizontal Pod Autoscaler (HPA) and application resource requests if metrics are showing as **< unknown>**.



**Note:** Metrics Server isn't a best practice for long-term monitoring of application and cluster performance. For long-term monitoring, see [Resource management for pods and containers](<https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/>) on the Kubernetes website. The Kubernetes community maintains Metrics Server and reports [issues on its GitHub page](<https://github.com/kubernetes-sigs/metrics-server/issues>).

## Resolution

Refer to the following steps to troubleshoot some of the most common issues with Metrics Server.

### Check if you can retrieve metrics from your cluster's nodes and pods

Check for errors between the API server and Metrics Server. To pull metrics from the nodes and pods of your cluster, run the following commands:
    
    
    $ kubectl top nodes
    
    
    $ kubectl top pods

If you don't receive an error from either command, then refer to the **Check if the APIService is available and can handle requests** section.

If receive an error, then complete the steps in one of the following sections based on the error that you received:

  * Error from server (Forbidden)
  * Error from server (ServiceUnavailable)
  * Client.Timeout exceeded while awaiting headers
  * Connection refused



**Error from server (Forbidden)**

This error message indicates that you have an issue with RBAC authorization. To resolve this error, confirm the following points:

  * The **ServiceAccount** is attached to the deployment correctly.
  * The **ClusterRole** /**Role** and **ClusterRoleBinding** /**RoleBindings** use the correct RBAC permissions for Metrics Server.



For more information, see [Using RBAC authorization](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>) on the Kubernetes website.

If you access your cluster through a [role defined in the aws-auth ConfigMap](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>), then confirm that you set the **username** field and the mapping.

  1. To describe the **aws-auth** ConfigMap, run the following command:
    
        $ kubectl describe -n kube-system configmap aws-auth

  2. Confirm that the **username** field is set for the role accessing the cluster. See the following example:
    
        Name:         aws-auth
    Namespace:    kube-system
    Labels:       <none>
    Annotations:  <none>
    
    Data
    ====
    mapRoles:
    ----
    ...
    -
      groups:
      - system:masters
      rolearn: arn:aws:iam::123456789123:role/kubernetes-devops
      username: devops:{{SessionName}}  # Ensure this has been specified.




**Error from server (ServiceUnavailable)**

To check for an issue with the configuration of the Metrics Server service application in your cluster, run the following command:
    
    
    $ kubectl describe apiservices v1beta1.metrics.k8s.io

The output looks similar to the following example:
    
    
    Name:         v1beta1.metrics.k8s.io
    Namespace:
    Labels:       app=metrics-server
    ...
    Status:
      Conditions:
        Last Transition Time:  2020-01-09T13:57:23Z
        Message:               all checks passed
        Reason:                Passed
        Status:                True
        Type:                  Available
    Events:                    <none>

If the Metrics Server service is available and passing checks, then **Status** is set to **True**.

If you set **Status** to **True** and the issue persists, then refer to the **Check if the APIService is available and can handle requests** section.

If **Status** is set to **False** , then look for the associated **Reason** code and human readable **Message** for **Conditions** in the output. See the following example of a failing **APIService** :
    
    
    ...
    Status:
      Conditions:
        Last Transition Time:  2020-01-09T14:40:28Z
        Message:               no response from https://10.0.35.231:443: Get https://10.0.35.231:443: dial tcp 10.0.35.231:443: connect: connection refused
        Reason:                FailedDiscoveryCheck
        Status:                False
        Type:                  Available

If the **Reason** isn't **FailedDiscoveryCheck** , then refer to the **Other APIServer condition failure reasons** section.

If the reason code is **FailedDiscoveryCheck** , then the Metrics Server service is available and pods are running. The Kubernetes APIServer returns an error when it tries to reach the Metrics Server endpoint.

If the APIServer Conditions Message contains **Client.Timeout exceeded while awaiting headers** , then refer to the **Resolve the "Client.Timeout exceeded while awaiting headers" error** section.

If the APIServer Conditions Message contains **connection refused** , then refer to the **Resolve the "connection refused" error** section.

**Resolve the "Client.Timeout exceeded while awaiting headers" error**

This error message on the **APIService** indicates that a security group or network access control list (ACL) isn't configured correctly. This prevents access to the **metrics-server** pods. See the following example:
    
    
    no response from https://10.0.35.231:443: Get https://10.0.35.231:443: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)

To resolve this error, confirm that your security groups comply with [minimum traffic requirements](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) for Amazon EKS.

**Resolve the "connection refused" error**

This error in the APIServer message indicates that the container is listening on the wrong port. See the following example:
    
    
    no response from https://10.0.35.231:443: Get https://10.0.35.231:443: dial tcp 10.0.35.231:443: connect: connection refused

To resolve this error, run the following command to confirm that the values for **ports** , **image** , and **command** are correct in the **metrics-server** deployment:
    
    
    $ kubectl describe deployment metrics-server -n kube-system

The output looks similar to the following example:
    
    
    Name:                   metrics-server
    Namespace:              kube-system
    CreationTimestamp:      Wed, 08 Jan 2020 11:48:45 +0200
    Labels:                 app=metrics-server
    ...
      Containers:
       metrics-server:
        Image:      gcr.io/google_containers/metrics-server-amd64:v0.3.6
        Port:       443/TCP
        Command:
        - /metrics-server
        - --logtostderr
        - --secure-port=443
    ...

**Note:** The **Command** and **Image** values can vary depending on how Metrics Server was deployed and where the images are stored. If the **Command** contains the **\--secure-port** parameter, then the **Port** (**443/TCP** , in the preceding example) exposed by the pod must match this parameter. If the **Command** doesn't contain the **\--secure-port** parameter, then the port defaults to **443**.

### Other APIServer condition failure reasons

If you receive any of the following codes for the APIService, then take action based on the associated error message: **ServiceNotFound** , **ServiceAccessError** , **ServicePortError** , **EndpointsNotFound** , **EndpointsAccessError** , or **MissingEndpoints**.

  1. To get information on the service with the error, run the following command:
    
        $ kubectl get service -n kube-system

In the output, confirm that the Kubernetes service has the same name and namespace as defined in **APIService.Spec.Service**. Then, confirm that the port is set to **443/TCP**. See the following example:
    
        NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    metrics-server                   ClusterIP   172.20.172.133   <none>        443/TCP    65m

  2. To list endpoints, run the following command:
    
        $ kubectl get endpoints metrics-server -n kube-system

In the output, confirm that you have at least one endpoint for the **metrics-server** service:
    
        NAME             ENDPOINTS         AGE
    metrics-server   10.0.35.231:443   76m

  3. To confirm that the deployment is present and that the labels match those of the **metrics-server** service, run the following command:
    
        $ kubectl describe deploy metrics-server -n kube-system

In the output, confirm that the deployment has at least one replica:
    
        Name:                   metrics-server
    Namespace:              kube-system
    CreationTimestamp:      Wed, 08 Jan 2020 11:48:45 +0200
    Labels:                 app=metrics-server
                            release=metrics-server
    ...
    Selector:               app=metrics-server,release=metrics-server
    Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
    ...
    Pod Template:
      Labels:           app=metrics-server
                        release=metrics-server
      Service Account:  metrics-server
      Containers:
       metrics-server:
        Image:      gcr.io/google_containers/metrics-server-amd64:v0.3.6
    ...




If you still can't collect metrics with Metrics Server, then refer to the **Check if the APIService is available and can handle requests** section.

### Check if the APIService is available and can handle requests

To extract logs from your Metrics Server pods, run the following command:
    
    
    $ kubectl logs -n <namespace> -l app=metrics-server

For example, error logs in **metrics-server** start with an **E** :
    
    
    E0610 23:13:28.247604       1 reststorage.go:98] unable to fetch pod metrics for pod default/php-apache-b5f58cc5f-nv8sz: no metrics known for pod "default/php-apache-b5f58cc5f-nv8sz"
    E0610 23:13:43.260069       1 reststorage.go:98] unable to fetch pod metrics for pod default/php-apache-b5f58cc5f-nv8sz: no metrics known for pod "default/php-apache-b5f58cc5f-nv8sz"
    E0610 23:16:13.346070       1 reststorage.go:98] unable to fetch pod metrics for pod default/php-apache-b5f58cc5f-cj67b: no metrics known for pod "default/php-apache-b5f58cc5f-cj67b"
    E0610 23:16:13.346087       1 reststorage.go:98] unable to fetch pod metrics for pod default/php-apache-b5f58cc5f-sqc6l: no metrics known for pod "default/php-apache-b5f58cc5f-sqc6l"
    E0610 23:16:13.346091       1 reststorage.go:98] unable to fetch pod metrics for pod default/php-apache-b5f58cc5f-4cpwk: no metrics known for pod "default/php-apache-b5f58cc5f-4cpwk"

Metrics Server error logs indicate either a configuration issue on the Metrics Server Deployment Command or a bug with the Metrics Server container. If the error message isn't obvious or you suspect that it's a bug, then complete the steps in the **Check GitHub for common issues** section.

### Check GitHub for common issues

If you still can't collect metrics from containers, pods, or nodes, then [check GitHub for common issues with Metrics Server](<https://github.com/kubernetes-sigs/metrics-server/issues>).

### Check your HPA and application resource requests for unknown metrics

  1. To check the HPA configuration, run the following command:
    
        $ kubectl get hpa -n namespace 2048-deployment

**Note:** Replace **namespace** and **2048-deployment** with the HPA configuration values for your application. You might see **< unknown>** under the **Targets** column of the output. See the following example:
    
        NAME              REFERENCE                    TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
    2048-deployment   Deployment/2048-deployment   <unknown>/80%   1         2         2          10s

  2. Wait several minutes, and then repeat the command from step 1.

If you still receive the **< unknown>** error, run the following command:
    
        $ kubectl describe hpa -n <namespace> 2048-deployment

Then, check the **Events** section of the output for more information:
    
        Name:                                                  2048-deployment
    Namespace:                                             2048-game
    ...
    Metrics:                                               ( current / target )
      resource cpu on pods  (as a percentage of request):  <unknown> / 80%
    Min replicas:                                          1
    Max replicas:                                          2
    Deployment pods:                                       2 current / 2 desired
    Conditions:
      Type           Status  Reason                   Message
      ----           ------  ------                   -------
      AbleToScale    True    SucceededGetScale        the HPA controller was able to get the target's current scale
      ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: missing request for cpu
    Events:
      Type     Reason                   Age                     From                       Message
      ----     ------                   ----                    ----                       -------
      Warning  FailedGetResourceMetric  3m29s (x4333 over 19h)  horizontal-pod-autoscaler  missing request for cpu

If the **Message** column shows **missing request for [x]** , then your [Deployments](<https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>) or [ReplicaSet](<https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/>) probably isn't declaring resource requests in its specification. Confirm that all the containers in the pod have the requests declared. Leaving out a request might cause the metric in HPA to return the **< unknown>** response.




For more information, see [Resource management for pods and containers](<https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/>) on the Kubernetes website.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
