Original URL: <https://repost.aws/knowledge-center/eks-get-control-plane-logs>

# How can I retrieve Amazon EKS control plane logs from CloudWatch Logs?

I'm troubleshooting an Amazon Elastic Kubernetes Service (Amazon EKS) issue and I need to collect logs from the components that run on the EKS control plane.

## Short description

To view the logs in Amazon CloudWatch Logs, you must turn on [Amazon EKS control plane logging](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>). You can find EKS control plane logs in the **/aws/eks/cluster-name/cluster** log group. For more information, see [Viewing cluster control plane logs](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html#viewing-control-plane-logs>).

**Note:** Replace **cluster-name** with your cluster's name.

You can use CloudWatch Logs Insights to search through the EKS control plane log data. For more information, see [Analyzing log data with CloudWatch Insights](<https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html>).

**Important:** You can view log events in CloudWatch Logs only after you turn on control plane logging in a cluster. Before you select a time range to run queries in CloudWatch Logs Insights, verify that you turned on control plane logging.

## Resolution

### Search CloudWatch Insights

  1. Open the [CloudWatch](<https://console.aws.amazon.com/cloudwatch/home?#logsV2:logs-insights>) console.
  2. In the navigation pane, choose **Logs** , and then choose **Log Insights**.
  3. In the **Select log group(s)** menu, select the **cluster log group** that you want to query.
  4. Choose **Run** to view the results.



**Note:** To export the results as a .csv file or to copy the results to the clipboard, choose **Export results**. You can change the sample query to get data for a specific use case. See these example queries for common EKS use cases.

### Sample queries for common EKS use cases

To find the cluster creator, search for the IAM entity that's mapped to the **kubernetes-admin** user.

Query:
    
    
    fields @logStream, @timestamp, @message
    | sort @timestamp desc
    | filter @logStream like /authenticator/
    | filter @message like "username=kubernetes-admin"
    | limit 50

Example output:
    
    
    @logStream, @timestamp @message
    authenticator-71976 ca11bea5d3083393f7d32dab75b,2021-08-11-10:09:49.020,"time=""2021-08-11T10:09:43Z"" level=info msg=""access granted"" arn=""arn:aws:iam::12345678910:user/awscli"" client=""127.0.0.1:51326"" groups=""[system:masters]"" method=POST path=/authenticate sts=sts.eu-west-1.amazonaws.com uid=""heptio-authenticator-aws:12345678910:ABCDEFGHIJKLMNOP"" username=kubernetes-admin"

In this output, IAM user **arn:aws:iam::12345678910:user/awscli** is mapped to user **kubernetes-admin**.

To find requests that a specific user performed, search for operations that the **kubernetes-admin** user performed.

Example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^kube-apiserver-audit/
    | filter strcontains(user.username,"kubernetes-admin")
    | sort @timestamp desc
    | limit 50

Example output:
    
    
    @logStream,@timestamp,@message
    kube-apiserver-audit-71976ca11bea5d3083393f7d32dab75b,2021-08-11 09:29:13.095,"{...""requestURI"":""/api/v1/namespaces/kube-system/endpoints?limit=500";","string""verb"":""list"",""user"":{""username"":""kubernetes-admin"",""uid"":""heptio-authenticator-aws:12345678910:ABCDEFGHIJKLMNOP"",""groups"":[""system:masters"",""system:authenticated""],""extra"":{""accessKeyId"":[""ABCDEFGHIJKLMNOP""],""arn"":[""arn:aws:iam::12345678910:user/awscli""],""canonicalArn"":[""arn:aws:iam::12345678910:user/awscli""],""sessionName"":[""""]}},""sourceIPs"":[""12.34.56.78""],""userAgent"":""kubectl/v1.22.0 (darwin/amd64) kubernetes/c2b5237"",""objectRef"":{""resource"":""endpoints"",""namespace"":""kube-system"",""apiVersion"":""v1""}...}"

To find API calls that a specific userAgent made, you can use this example query:
    
    
    fields @logStream, @timestamp, userAgent, verb, requestURI, @message
    | filter @logStream like /kube-apiserver-audit/
    | filter userAgent like /kubectl\/v1.22.0/
    | sort @timestamp desc
    | filter verb like /(get)/

Shortened example output:
    
    
    @logStream,@timestamp,userAgent,verb,requestURI,@message
    kube-apiserver-audit-71976ca11bea5d3083393f7d32dab75b,2021-08-11 14:06:47.068,kubectl/v1.22.0 (darwin/amd64) kubernetes/c2b5237,get,/apis/metrics.k8s.io/v1beta1?timeout=32s,"{""kind"":""Event"",""apiVersion"":""audit.k8s.io/v1"",""level"":""Metadata"",""auditID"":""863d9353-61a2-4255-a243-afaeb9183524"",""stage"":""ResponseComplete"",""requestURI"":""/apis/metrics.k8s.io/v1beta1?timeout=32s"",""verb"":""get"",""user"":{""username"":""kubernetes-admin"",""uid"":""heptio-authenticator-aws:12345678910:AIDAUQGC5HFOHXON7M22F"",""groups"":[""system:masters"",""system:authenticated""],""extra"":{""accessKeyId"":[""ABCDEFGHIJKLMNOP""],""arn"":[""arn:aws:iam::12345678910:user/awscli""],""canonicalArn"":[""arn:aws:iam::12345678910:user/awscli""],""sourceIPs"":[""12.34.56.78""],""userAgent"":""kubectl/v1.22.0 (darwin/amd64) kubernetes/c2b5237""...}"

To find mutating changes made to the **aws-auth** ConfigMap, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^kube-apiserver-audit/
    | filter requestURI like /\/api\/v1\/namespaces\/kube-system\/configmaps/
    | filter objectRef.name = "aws-auth"
    | filter verb like /(create|delete|patch)/
    | sort @timestamp desc
    | limit 50

Shortened example output:
    
    
    @logStream,@timestamp,@message
    kube-apiserver-audit-f01c77ed8078a670a2eb63af6f127163,2021-10-27 05:43:01.850,{""kind"":""Event"",""apiVersion"":""audit.k8s.io/v1"",""level"":""RequestResponse"",""auditID"":""8f9a5a16-f115-4bb8-912f-ee2b1d737ff1"",""stage"":""ResponseComplete"",""requestURI"":""/api/v1/namespaces/kube-system/configmaps/aws-auth?timeout=19s"",""verb"":""patch"",""responseStatus"": {""metadata"": {},""code"": 200 },""requestObject"": {""data"": { contents of aws-auth ConfigMap } },""requestReceivedTimestamp"":""2021-10-27T05:43:01.033516Z"",""stageTimestamp"":""2021-10-27T05:43:01.042364Z"" }

To find requests that were denied, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^authenticator/
    | filter @message like "denied"
    | sort @timestamp desc
    | limit 50

Example output:
    
    
    @logStream,@timestamp,@message
    authenticator-8c0c570ea5676c62c44d98da6189a02b,2021-08-08 20:04:46.282,"time=""2021-08-08T20:04:44Z"" level=warning msg=""access denied"" client=""127.0.0.1:52856"" error=""sts getCallerIdentity failed: error from AWS (expected 200, got 403)"" method=POST path=/authenticate"

To find the node that a pod was scheduled on, query the **kube-scheduler** logs.

Example query:
    
    
    fields @logStream, @timestamp, @message
    | sort @timestamp desc
    | filter @logStream like /kube-scheduler/
    | filter @message like "aws-6799fc88d8-jqc2r"
    | limit 50

Example output:
    
    
    @logStream,@timestamp,@message
    kube-scheduler-bb3ea89d63fd2b9735ba06b144377db6,2021-08-15 12:19:43.000,"I0915 12:19:43.933124       1 scheduler.go:604] ""Successfully bound pod to node"" pod=""kube-system/aws-6799fc88d8-jqc2r"" node=""ip-192-168-66-187.eu-west-1.compute.internal"" evaluatedNodes=3 feasibleNodes=2"

In this example output, pod **aws-6799fc88d8-jqc2r** was scheduled on node **ip-192-168-66-187.eu-west-1.compute.internal**.

To find HTTP 5xx server errors for Kubernetes API server requests, you can use this example query:
    
    
    fields @logStream, @timestamp, responseStatus.code, @message
    | filter @logStream like /^kube-apiserver-audit/
    | filter responseStatus.code >= 500
    | limit 50

Shortened example output:
    
    
    @logStream,@timestamp,responseStatus.code,@message
    kube-apiserver-audit-4d5145b53c40d10c276ad08fa36d1f11,2021-08-04 07:22:06.518,503,"...""requestURI"":""/apis/metrics.k8s.io/v1beta1?timeout=32s"",""verb"":""get"",""user"":{""username"":""system:serviceaccount:kube-system:resourcequota-controller"",""uid"":""36d9c3dd-f1fd-4cae-9266-900d64d6a754"",""groups"":[""system:serviceaccounts"",""system:serviceaccounts:kube-system"",""system:authenticated""]},""sourceIPs"":[""12.34.56.78""],""userAgent"":""kube-controller-manager/v1.21.2 (linux/amd64) kubernetes/d2965f0/system:serviceaccount:kube-system:resourcequota-controller"",""responseStatus"":{""metadata"":{},""code"":503},..."}}"

To troubleshoot a CronJob activation, search for API calls that the **cronjob-controller** made.

Example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /kube-apiserver-audit/
    | filter user.username like "system:serviceaccount:kube-system:cronjob-controller"
    | display @logStream, @timestamp, @message, objectRef.namespace, objectRef.name
    | sort @timestamp desc
    | limit 50

Shortened example output:
    
    
    { "kind": "Event", "apiVersion": "audit.k8s.io/v1", "objectRef": { "resource": "cronjobs", "namespace": "default", "name": "hello", "apiGroup": "batch", "apiVersion": "v1" }, "responseObject": { "kind": "CronJob", "apiVersion": "batch/v1", "spec": { "schedule": "*/1 * * * *" }, "status": { "lastScheduleTime": "2021-08-09T07:19:00Z" } } }

In this example output, the **hello** job in the **default** namespace runs every minute and was last scheduled at **2021-08-09T07:19:00Z**.

To find API calls that the **replicaset-controller** made, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /kube-apiserver-audit/
    | filter user.username like "system:serviceaccount:kube-system:replicaset-controller"
    | display @logStream, @timestamp, requestURI, verb, user.username
    | sort @timestamp desc
    | limit 50

Example output:
    
    
    @logStream,@timestamp,requestURI,verb,user.username
    kube-apiserver-audit-8c0c570ea5676c62c44d98da6189a02b,2021-08-10 17:13:53.281,/api/v1/namespaces/kube-system/pods,create,system:serviceaccount:kube-system:replicaset-controller
    kube-apiserver-audit-4d5145b53c40d10c276ad08fa36d1f11,2021-08-04 0718:44.561,/apis/apps/v1/namespaces/kube-system/replicasets/coredns-6496b6c8b9/status,update,system:serviceaccount:kube-system:replicaset-controller

To find operations that are made against a Kubernetes resource, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^kube-apiserver-audit/
    | filter verb == "delete" and requestURI like "/api/v1/namespaces/default/pods/my-app"
    | sort @timestamp desc
    | limit 10

The preceding example query filters for **delete** API calls on the **default** namespace for pod **my-app**.

Shortened example output:
    
    
    @logStream,@timestamp,@message
    kube-apiserver-audit-e7b3cb08c0296daf439493a6fc9aff8c,2021-08-11 14:09:47.813,"...""requestURI"":""/api/v1/namespaces/default/pods/my-app"",""verb"":""delete"",""user"":{""username""""kubernetes-admin"",""uid"":""heptio-authenticator-aws:12345678910:ABCDEFGHIJKLMNOP"",""groups"":[""system:masters"",""system:authenticated""],""extra"":{""accessKeyId"":[""ABCDEFGHIJKLMNOP""],""arn"":[""arn:aws:iam::12345678910:user/awscli""],""canonicalArn"":[""arn:aws:iam::12345678910:user/awscli""],""sessionName"":[""""]}},""sourceIPs"":[""12.34.56.78""],""userAgent"":""kubectl/v1.22.0 (darwin/amd64) kubernetes/c2b5237"",""objectRef"":{""resource"":""pods"",""namespace"":""default"",""name"":""my-app"",""apiVersion"":""v1""},""responseStatus"":{""metadata"":{},""code"":200},""requestObject"":{""kind"":""DeleteOptions"",""apiVersion"":""v1"",""propagationPolicy"":""Background""},
    ..."

To retrieve a count of HTTP response codes for calls made to the Kubernetes API server, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^kube-apiserver-audit/
    | stats count(*) as count by responseStatus.code
    | sort count desc

Example output:
    
    
    responseStatus.code,count
    200,35066
    201,525
    403,125
    404,116
    101,2

To find changes that are made to DaemonSets/Addons in the **kube-system** namespace, you can use this example query:
    
    
    filter @logStream like /^kube-apiserver-audit/
    | fields @logStream, @timestamp, @message
    | filter verb like /(create|update|delete)/ and strcontains(requestURI,"/apis/apps/v1/namespaces/kube-system/daemonsets")
    | sort @timestamp desc
    | limit 50

Example output:
    
    
    { "kind": "Event", "apiVersion": "audit.k8s.io/v1", "level": "RequestResponse", "auditID": "93e24148-0aa6-4166-8086-a689b0031612", "stage": "ResponseComplete", "requestURI": "/apis/apps/v1/namespaces/kube-system/daemonsets/aws-node?fieldManager=kubectl-set", "verb": "patch", "user": { "username": "kubernetes-admin", "groups": [ "system:masters", "system:authenticated" ] }, "userAgent": "kubectl/v1.22.2 (darwin/amd64) kubernetes/8b5a191", "objectRef": { "resource": "daemonsets", "namespace": "kube-system", "name": "aws-node", "apiGroup": "apps", "apiVersion": "v1" }, "requestObject": { "REDACTED": "REDACTED" }, "requestReceivedTimestamp": "2021-08-09T08:07:21.868376Z", "stageTimestamp": "2021-08-09T08:07:21.883489Z", "annotations": { "authorization.k8s.io/decision": "allow", "authorization.k8s.io/reason": "" } }

In this example output, the **kubernetes-admin** user used **kubectl** v1.22.2 to patch the **aws-node** DaemonSet.

To find the user that deleted a node, you can use this example query:
    
    
    fields @logStream, @timestamp, @message
    | filter @logStream like /^kube-apiserver-audit/
    | filter verb == "delete" and requestURI like "/api/v1/nodes"
    | sort @timestamp desc
    | limit 10

Shortened example output:
    
    
    @logStream,@timestamp,@message
    kube-apiserver-audit-e503271cd443efdbd2050ae8ca0794eb,2022-03-25 07:26:55.661,"{"kind":"Event","verb":"delete","user":{"username":"kubernetes-admin","groups":["system:masters","system:authenticated"],"arn":["arn:aws:iam::1234567890:user/awscli"],"canonicalArn":["arn:aws:iam::1234567890:user/awscli"],"sessionName":[""]}},"sourceIPs":["1.2.3.4"],"userAgent":"kubectl/v1.21.5 (darwin/amd64) kubernetes/c285e78","objectRef":{"resource":"nodes","name":"ip-192-168-37-22.eu-west-1.compute.internal","apiVersion":"v1"},"responseStatus":{"metadata":{},"status":"Success","code":200},"requestObject":{"kind":"DeleteOptions","apiVersion":"v1","propagationPolicy":"Background"},"responseObject":{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Success","details":{"name":"ip-192-168-37-22.eu-west-1.compute.internal","kind":"nodes","uid":"518ba070-154e-4400-883a-77a44a075bd0"}},"requestReceivedTimestamp":"2022-03-25T07:26:55.355378Z",}}"

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
