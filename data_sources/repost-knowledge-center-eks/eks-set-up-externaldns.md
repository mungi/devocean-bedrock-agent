Original URL: <https://repost.aws/knowledge-center/eks-set-up-externaldns>

# How do I set up ExternalDNS with Amazon EKS?

I want to set up ExternalDNS with my Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

To install ExternalDNS, use AWS Identity and Access Management (IAM) permissions to grant Amazon EKS the necessary access to interact with Amazon Route 53.

**Note:** Before you begin the following resolution, make sure that you have a domain name and a Route 53 hosted zone.

## Resolution

### Set up IAM permissions and deploy ExternalDNS

Complete the following steps:

  1. Create the following policy to set up IAM permissions that give the ExternalDNS pod permissions to create, update, and delete Route 53 records in your AWS account:
    
        {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource": [
            "arn:aws:route53:::hostedzone/"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
            "route53:ListTagsForResource"
          ],
          "Resource": [
            ""
          ]
        }
      ]
    }

**Note:** You can modify the preceding policy to allow updates to specific hosted zone IDs.

  2. Use the policy to create an IAM role for the service account:
    
        eksctl create iamserviceaccount --name SERVICE_ACCOUNT_NAME --namespace NAMESPACE 
    --cluster CLUSTER_NAME --attach-policy-arn IAM_POLICY_ARN --approve

**Note:** Replace **SERVICE_ACCOUNT_NAME** with your service account's name, **NAMESPACE** with your namespace, **CLUSTER_NAME** with your cluster's name, and **IAM_POLICY_ARN** with your IAM policy's ARN.  
To check the name of your service account, run the following command:
    
        kubectl get sa

In the following example output, **external-dns** is the name that's given to the service account when it's created:
    
        NAME           SECRETS   AGE
    default        1         23h
    external-dns   1         23h

  3. Run the following command to determine if RBAC is turned on in your Amazon EKS cluster: 
    
        kubectl api-versions | grep rbac.authorization.k8s.io

**Note:** For the preceding command, verify the most recent version of ExternalDNS that's available on the GitHub project.

  4. Run the following command to deploy ExternalDNS:
    
        kubectl apply DEPLOYMENT_MANIFEST_FILE_NAME.yaml

**Note:** Replace **DEPLOYMENT_MANIFEST_FILE_NAME** with your deployment manifest's file name.

If RBAC is turned on, then use the following manifest to deploy ExternalDNS:
    
        apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: external-dns
      labels:
        app.kubernetes.io/name: external-dns
    rules:
      - apiGroups: [""]
        resources: ["services","endpoints","pods","nodes"]
        verbs: ["get","watch","list"]
      - apiGroups: ["extensions","networking.k8s.io"]
        resources: ["ingresses"]
        verbs: ["get","watch","list"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: external-dns-viewer
      labels:
        app.kubernetes.io/name: external-dns
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: external-dns
    subjects:
      - kind: ServiceAccount
        name: external-dns
        namespace: default # change to desired namespace: externaldns, kube-addons
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: external-dns
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      strategy:
        type: Recreate
      selector:
        matchLabels:
          app.kubernetes.io/name: external-dns
      template:
        metadata:
          labels:
            app.kubernetes.io/name: external-dns
        spec:
          serviceAccountName: external-dns
          containers:
            - name: external-dns
              image: registry.k8s.io/external-dns/external-dns:v0.14.0
              args:
                - --source=service
                - --source=ingress
                - --domain-filter=example.com # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
                - --provider=aws
                - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
                - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
                - --registry=txt
                - --txt-owner-id=external-dns
              env:
                - name: AWS_DEFAULT_REGION
                  value: eu-west-1 # change to region where EKS is installed

If RBAC isn't turned on, then use the following manifest to deploy ExternalDNS:
    
        apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: external-dns
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      strategy:
        type: Recreate
      selector:
        matchLabels:
          app.kubernetes.io/name: external-dns
      template:
        metadata:
          labels:
            app.kubernetes.io/name: external-dns
        spec:
          containers:
            - name: external-dns
              image: registry.k8s.io/external-dns/external-dns:v0.14.0
              args:
                - --source=service
                - --source=ingress
                - --domain-filter=example.com # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
                - --provider=aws
                - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
                - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
                - --registry=txt
                - --txt-owner-id=my-hostedzone-identifier
              env:
                - name: AWS_DEFAULT_REGION
                  value: eu-west-1 # change to region where EKS is installed

  5. Run the following command to verify that the deployment is successful:
    
        kubectl get deployments

Example output:
    
        NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    external-dns   1/1     1            1           85m

Or, check the logs to verify that the records are updated:
    
        kubectl logs external-dns-9f85d8d5b-sx5f

Example output:
    
        ....
    ....
    time="2023-12-14T17:16:16Z" level=info msg="Instantiating new Kubernetes client"
    time="2023-12-14T17:16:16Z" level=info msg="Using inCluster-config based on serviceaccount-token"
    time="2023-12-14T17:16:16Z" level=info msg="Created Kubernetes client https://10.100.0.1:443"
    time="2023-12-14T17:16:18Z" level=info msg="Applying provider record filter for domains: [xxxxx.people.aws.dev. .xxxxx.people.aws.dev. xxxxx.people.aws.dev. .xxxxx.people.aws.dev.]"
    time="2023-12-14T17:16:18Z" level=info msg="All records are already up to date"
    ....
    ....




### Verify ExternalDNS

To confirm that ExternalDNS is set up correctly, complete the following steps:

  1. Create a service that's exposed as **LoadBalancer**. The service must be routed externally through the domain name that's hosted on Route 53:
    
        kubectl apply SERVICE_MANIFEST_FILE_NAME.yaml
    
    Note: Replace SERVICE_MANIFEST_FILE_NAME with your service manifest's file name.
    
    Manifest:
    
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      annotations:
        external-dns.alpha.kubernetes.io/hostname: nginx.xxxxx.people.aws.dev
    spec:
      ports:
        - port: 80
          targetPort: 80
          protocol: TCP
      type: LoadBalancer
      selector:
        app: nginx
    
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx
    spec:
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
            - image: nginx
              name: nginx
              ports:
                - containerPort: 80
                  name: http

**Note:** ExternalDNS uses the **external-dns.alpha.kubernetes.io/hostname** annotation on services. It also uses the associated values. To assign multiple names to a service, configure the **external-dns.alpha.kubernetes.io/hostname** annotation with a comma separator.

  2. Check that the NGINX service is created with the **LoadBalancer** type:
    
        kubectl get svc

Example output:
    
        NAME         TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
    kubernetes   ClusterIP      10.100.0.1      <none>                                                                   443/TCP        05h
    nginx        LoadBalancer   10.100.254.68   xxxxyyyyzzzz-123456789.eu-west-1.elb.amazonaws.com   80:30792/TCP   74m
    

**Note:** The service automatically creates a Route 53 record for the hosted zone.

  3. Run the following command to view logs, and confirm that the Route 53 record is created successfully:
    
        kubectl logs external-dns-9f85d8d5b-sx5fg

Example output:
    
        ...
    ...
    ...
    time="2023-12-14T17:19:19Z" level=info msg="Desired change: CREATE cname-nginx.xxxxx.people.aws.dev TXT [Id: /hostedzone/Z0786329GDVAZMXYZ]"
    time="2023-12-14T17:19:19Z" level=info msg="Desired change: CREATE nginx.xxxxx.people.aws.dev A [Id: /hostedzone/Z0786329GDVAZMXYZ]"
    time="2023-12-14T17:19:19Z" level=info msg="Desired change: CREATE nginx.xxxxx.people.aws.dev TXT [Id: /hostedzone/Z0786329GDVAZMXYZ]"
    time="2023-12-14T17:19:20Z" level=info msg="3 record(s) in zone xxxxx.people.aws.dev. [Id: /hostedzone/Z0786329GDVAZMXYZ] were successfully updated"
    ...
    ...
    ...




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
