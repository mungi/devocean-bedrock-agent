Original URL: <https://repost.aws/knowledge-center/eks-topology-aware-hints>

# How do I use Topology Aware Hints in Amazon EKS?

I want to use Topology Aware Hints (TAH) in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## **Resolution**

**Note:** TAH might not be suitable for clusters that have Amazon Elastic Compute Cloud (Amazon EC2) Spot Instances, Horizontal Pod Autoscaling, or auto scaling turned on. When you use these cluster configurations, you can't achieve an allocation that's proportional to the CPU cores allocated to nodes and exceed the allowed overhead threshold. Also, if there are pod assignment constraints that prohibit endpoint redistribution, then kube-proxy doesn't use TAH.

Before you begin, take the following actions:

  * Make sure that your Amazon EKS cluster version is 1.24 or later.
  * Set up an Amazon EKS cluster and a managed node group with three nodes. Each node must have the same CPU capacity and be distributed across three Availability Zones.



To use TAH in Amazon EKS, complete the following steps:

  1. Create a new namespace:  
**Note:** Replace **example-namespace** with your namespace name.
    
        apiVersion: v1  
    kind: Namespace  
    metadata:  
      name: "example-namespace"  
      labels:  
        pod-security.kubernetes.io/audit: restricted  
        pod-security.kubernetes.io/enforce: restricted   
        pod-security.kubernetes.io/warn: restricted

  2. Use the **BusyBox** image to create a sample deployment:  
**Note:** Replace **example-deployment-name** with your deployment name and **example-namespace** with your namespace name.
    
        apiVersion: apps/v1  
    kind: Deployment  
    metadata:  
      name: example-deployment-name  
      namespace: example-namespace  
    spec:  
      replicas: 3  
      selector:  
        matchLabels:  
          app: demo  
      template:  
        metadata:  
          labels:  
            app: demo  
        spec:  
          dnsPolicy: Default  
          enableServiceLinks: false  
          automountServiceAccountToken: false   
          securityContext:  
            seccompProfile:  
              type: RuntimeDefault  
            runAsNonRoot: true   
            runAsUser: 1000   
            runAsGroup: 1000  
          containers:  
            - name: busybox  
              image: public.ecr.aws/docker/library/busybox:latest  
              command: ["/bin/sh"]  
              args:  
                - "-c"  
                - |  
                  echo "<html><body><h1>PodName: $MY_POD_NAME  NodeName: $MY_NODE_NAME podIP:$MY_POD_IP</h1></body></html>" > /tmp/index.html;  
                  while true; do  
                    printf 'HTTP/1.1 200 OK\n\n%s\n' $(cat /tmp/index.html) | nc -l -p 8080       
                  done  
              ports:  
                - containerPort: 8080  
              env:  
              - name: MY_NODE_NAME  
                valueFrom:  
                 fieldRef:  
                  fieldPath: spec.nodeName  
              - name: MY_POD_IP  
                valueFrom:  
                  fieldRef:  
                    fieldPath: status.podIP  
              - name: MY_POD_NAME  
                valueFrom:  
                  fieldRef:  
                    fieldPath: metadata.name  
              resources:  
                limits:  
                  memory: "128Mi"  
                  cpu: "500m"  
                requests:  
                  memory: "64Mi"  
                  cpu: "250m"  
              securityContext:  
                readOnlyRootFilesystem: true  
                allowPrivilegeEscalation: false  
                capabilities:  
                  drop:  
                    - ALL  
              volumeMounts:  
              - name: tmp  
                mountPath: /tmp  
          volumes:  
            - name: tmp  
              emptyDir: {}

  3. Expose the deployment as a **ClusterIP** service type, and then add **service.kubernetes.io/topology-mode: auto** as an annotation:  
**Note:** Replace **example-service-name** with your service name and **example-namespace** with your namespace name. In version 1.27 or later, the **service.kubernetes.io/topology-mode: auto** annotation is changed to **service.kubernetes.io/topology-aware-hints: auto**.
    
        apiVersion: v1  
    kind: Service  
    metadata:  
      name: example-service-name  
      namespace: example-namespace  
      annotations:  
       service.kubernetes.io/topology-mode: auto  
    spec:  
      selector:  
        app: demo  
      ports:  
        - protocol: TCP  
          port: 80  
          targetPort: 8080

  4. Check if the TAHs are populated in the endpoint:  
**Note:** Replace **example-namespace** with your namespace name and **example-endpoint-name** with your endpoint name.
    
        `kubectl get ``endpointslices.discovery.k8s.io`` example-endpoint-name -n example-namespace -oyaml`

Example output:
    
        endpoints:  
    - addresses:  
      - 10.0.21.125  
      conditions:  
        ready: true  
        serving: true  
        terminating: false  
      hints:  
        forZones:  
        - name: eu-west-1b  
      nodeName: ip-10-0-17-215.eu-west-1.compute.internal  
      targetRef:  
        kind: Pod  
        name: example-deployment-name-5875bbbb7c-m2j8t  
        namespace: example-namespace  
        uid: 4e789648-965e-4caa-91db-bd27d240ea59  
      zone: eu-west-1b

  5. Deploy a test pod to check if the traffic is routed to a pod in the same Availability Zone:  
**Note:** Replace **example-node-name** with your node name.
    
        kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname":"example-node-name"}}}'  
    

  6. Find the pod and node that your test pod connects to:
    
        curl example-service-name:80

Example output:
    
        PodName: 7b7b9bf455-c27z9  
    HTTP/1.1 200 OK  
    NodeName: ip-10-0-9-45.eu-west-1.compute.internal  
    HTTP/1.1 200 OK  
    podIP: example-10.0.11.140

  7. Use **PodName** and **NodeName** from the preceding step's output to check if traffic aligns with the same Availability Zone that your test pod is deployed in.

  8. Scale the deployment to four replicas, and then inspect the EndpointSlices:  
**Note:** Replace **example-namespace** with your namespace name and **example-deployment-name** with your deployment name.
    
        kubectl -n example-namespace scale deployments example-deployment-name --replicas=4   
    

**Note:** A deployment that's scaled to four replicas results in at least one Availability Zone that has a 50% ratio of endpoints. Also, the overhead threshold of 20% is exceeded and TAHs aren't used for kube-proxy.




## **Related information**

[Topology Aware Routing](<https://kubernetes.io/docs/concepts/services-networking/topology-aware-routing/>) on the Kubernetes website

[Exploring the effect of Topology Aware Hints on network traffic in Amazon Elastic Kubernetes Service](<https://aws.amazon.com/blogs/containers/exploring-the-effect-of-topology-aware-hints-on-network-traffic-in-amazon-elastic-kubernetes-service/>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
