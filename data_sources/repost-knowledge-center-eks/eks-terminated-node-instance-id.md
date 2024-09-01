Original URL: <https://repost.aws/knowledge-center/eks-terminated-node-instance-id>

# How do I track the instance ID of a terminated Amazon EKS worker node by its NodeName?

An incident terminated worker nodes in my Amazon EKS cluster, and I want to match the terminated nodes’ names to their instance ID.

## Short description

In Amazon EKS, a node’s name is recorded and displayed using its **PrivateDnsName**. This name follows a format that’s similar to **ip-172-31-6-187.eu-west-1.compute.internal**.

You can use a node’s name to find its instance ID. However, the default **kubectl get nodes** command doesn't return instance ID in its output. See the following example output:
    
    
    NAME                                           STATUS   ROLES    AGE   VERSION
    ip-192-168-132-83.eu-west-1.compute.internal   Ready    <none>   37m   v1.22.12-eks-ba74326
    ip-192-168-96-83.eu-west-1.compute.internal    Ready    <none>   37m   v1.22.12-eks-ba74326

To retrieve the instance ID of active worker nodes, add extra columns as shown in the following command:
    
    
    kubectl get nodes -o custom-columns=Name:.metadata.name,Instance:.spec.providerID

You receive an output that’s similar to the following:
    
    
    Name                                            Instance
    ip-192-168-104-154.eu-west-1.compute.internal   aws:///eu-west-1a/i-0cb3f1ceeb038fb6c
    ip-192-168-157-89.eu-west-1.compute.internal    aws:///eu-west-1b/i-02e80d4889b6ccffa

However, this command doesn’t work for nodes that are terminated.

You can also use **TerminateInstances** or **TerminateInstanceInAutoScalingGroup** as the **EventName** in AWS CloudTrail to return the instance ID. However, these commands by themselves don't return an Amazon EKS node’s name.

Therefore, you must first run a separate command to retrieve a node’s **NodeName** (**PrivateDnsName**). Then, use that name to track the node’s instance ID. To find the instance ID for previously terminated worker nodes, search through [Amazon EKS control plane logs](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>) with Amazon CloudWatch Logs Insights. To do this, you must activate control plane logging before node termination. If you don’t have control plane logging activated, then use CloudTrail.

## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html#general-latest>).

### Retrieve the NodeName for your nodes

For both of the following methods, you must know the **NodeName** of a terminated node to retrieve its instance ID. To retrieve a list of terminated Amazon EKS nodes from a given time range, use CloudWatch Log Insight Query Editor:

1\. Open the [CloudWatch console](<https://console.aws.amazon.com/cloudwatch/>).

2\. In the navigation pane, choose **Logs** , and then choose **Logs Insights**.

**Note:** On the **Logs Insights** page, the query editor contains a default query that returns the 20 most recent log events.

3\. Delete the default query. Then, enter the following command:
    
    
    fields @timestamp, objectRef.name as NodeName
    | filter @logStream like /^kube-apiserver-audit/
    | filter objectRef.resource = "nodes"
    | filter responseStatus.code = 200 or responseStatus.code = 201
    | sort @timestamp desc
    | filter verb like /delete/

4\. In the **Select log group(s)** dropdown list, choose the Amazon EKS cluster log groups that you want to query.

**Note:** Your log group looks similar to **/aws/eks/cluster_name/cluster** . In this example, replace **cluster_name** with your own Amazon EKS cluster name.

5\. Use the **time interva** l selector to select a time period that you want to query.

6\. Choose **Run** to view the results.

You receive an output that’s similar to the following:
    
    
    # @timestamp                    NodeName                                     
    1 2023-01-23T08:03:03.062+00:00 ip-192-168-132-83.eu-west-1.compute.internal 
    2 2023-01-23T19:03:41.848+00:00 ip-192-168-0-141.eu-west-1.compute.internal

### Use CloudWatch Logs Insights to search Amazon EKS control plane logs

Use CloudWatch Logs Insights to search through the Amazon EKS control plane log data for events that recorded a node’s NodeName. To view these logs in Amazon CloudWatch Logs, you must [activate Amazon EKS control plane logging](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html#enabling-control-plane-log-export>) before node termination, and it must remain activated.

For example, suppose that you want to retrieve the instance ID of a node with the name **ip-192-168-132-83.eu-west-1.compute.internal**. This node’s termination date was four days ago. You can use either of two queries to retrieve the instance ID from the **NodeName**.

First, follow these steps to run a CloudWatch Logs Insights query:

1\. Open the [CloudWatch console](<https://console.aws.amazon.com/cloudwatch/>).

2\. In the navigation pane, choose **Logs** , and then choose **Logs Insights**.

**Note:** On the **Logs Insights** page, the query editor contains a default query that returns the 20 most recent log events.

3\. Delete the default query. Then, enter either one of the following queries to retrieve the instance ID from the **NodeName** :

**Query 1**
    
    
    fields @timestamp, objectRef.name as NodeName, responseObject.spec.providerID as providerID
    | filter @message like 'ip-192-168-132-83.eu-west-1.compute.internal' and @message like 'i-'
    | sort responseObject.spec.providerID desc
    | limit 10

**Query 2**
    
    
    fields @timestamp, objectRef.name as NodeName, user.extra.sessionName.0 as ID
    | filter @message like 'ip-192-168-132-83.eu-west-1.compute.internal' and @message like 'i-'
    | sort user.extra.sessionName.0 desc
    | limit 5

4\. In the **Select log group(s)** dropdown list, choose the Amazon EKS cluster log groups that you want to query.

**Note:** Your log group looks similar to **/aws/eks/cluster_name/cluster**. In this example, replace **cluster_name** with your own Amazon EKS cluster name.

5\. Use the **time interva** l selector to select a time period that you want to query.

6\. Choose **Run** to view the results.

You receive an output based on the query that you ran.

**Query 1** returns an output that’s similar to the following:
    
    
    # @timestamp                    NodeName                                     providerID
    1 2023-01-23T08:03:03.062+00:00 ip-192-168-132-83.eu-west-1.compute.internal aws:///eu-west-1a/i-06c893718d4123396

**Query 2** returns an output that’s similar to the following:
    
    
    # @timestamp                    NodeName                                     ID
    1 2023-01-22T15:00:32.637+00:00 ip-192-168-11-247.eu-west-1.compute.internal i-06c893718d4123396

### Use API calls as events in CloudTrail

You can retrieve a node’s instance ID from its **NodeName** with a combination of API calls in CloudTrail. Use both **RunInstances** and **TerminateInstances** as the **EventName**. These API calls do the following:

**TerminateInstances:** This retrieves all instance IDs from the time of the incident that terminated them. This contains only the instance ID.

**RunInstances:** This contains both the instance ID and **NodeName**.

First, use the following command to see all terminated worker nodes from the time frame of the incident that you want to audit. Replace the **start-time** and **end-time** values to set your relevant time frame:
    
    
    % aws cloudtrail lookup-events \
      --lookup-attributes AttributeKey=EventName,AttributeValue=TerminateInstances AttributeKey=ResourceType,AttributeValue=AWS::EC2::Instance \
      --start-time "January 27, 2023, 00:00:00" \
      --end-time "January 27, 2023, 23:59:00" | jq '.Events [] | .CloudTrailEvent | fromjson | .responseElements | .instancesSet | .items | .[]? | {InstanceID: .instanceId, NodeName: .privateDnsName}'

You receive an output that’s similar to the following:
    
    
    {
      "InstanceID": "i-0926c5d4216fd934d",
      "NodeName": null
    }
    {
      "InstanceID": "i-00da28f580e28ff4f",
      "NodeName": null
    }

Use the following command to retrieve the result of the **RunInstances API** call during the time frame of the incident that you want to audit. Replace the **start-time** and **end-time** values to set your relevant time frame:
    
    
    % aws cloudtrail lookup-events \
      --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances AttributeKey=ResourceType,AttributeValue=AWS::EC2::Instance \
      --start-time "January 27, 2023, 00:00:00" \
      --end-time "January 27, 2023, 23:59:00" | jq '.Events [] | .CloudTrailEvent | fromjson | .responseElements | .instancesSet | .items | .[]? | {InstanceID: .instanceId, NodeName: .privateDnsName}'

**Note:** To get the most complete information, set the **start-time** to when the worker nodes were created.

You receive an output that’s similar to the following:
    
    
    {
      "InstanceID": "i-0926c5d4216fd934d",
      "NodeName": "ip-192-168-96-83.eu-west-1.compute.internal"
    }
    {
      "InstanceID": "i-00da28f580e28ff4f",
      "NodeName": "ip-192-168-132-83.eu-west-1.compute.internal"
    }

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
