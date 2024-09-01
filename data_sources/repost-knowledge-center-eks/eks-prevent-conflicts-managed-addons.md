Original URL: <https://repost.aws/knowledge-center/eks-prevent-conflicts-managed-addons>

# How do I prevent configuration conflicts when I create or update my Amazon EKS managed add-ons?

I want to prevent configuration conflicts when I create or update my Amazon Elastic Kubernetes Service (Amazon EKS) managed add-ons.

## Short description

When you create or update Amazon EKS managed add-ons, you might receive the following error:

{  
"code": "ConfigurationConflict",  
"message": "Conflicts found when trying to apply. Will not continue due to resolve conflicts mode. Conflicts: <conflicting fields>"  
}

Amazon EKS advanced configuration for managed add-ons lets you override existing add-on configurations. To override custom configurations, use the parameter **resolve-conflicts OVERWRITE**.

To manage the configurations through an Amazon EKS service endpoint, use the Amazon EKS **CreateAddon** or **UpdateAddon** APIs. Then, pass the **configurationValues** parameter to apply and manage add-on custom configurations. This method prevents configuration conflicts.

The following add-ons and options are commonly used Amazon EKS advanced configurations:

  * Amazon Virtual Private Cloud (Amazon VPC) CNI
  * Amazon Elastic Block Store (Amazon EBS) CSI driver
  * CoreDNS
  * Tolerations



## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### Amazon VPC CNI

The managed Amazon VPC CNI add-on lets you set values for the **WARM_PREFIX_TARGET** , **WARM_IP_TARGET** , and **MINIMUM_IP_TARGET** parameters. These parameters control the amount of provisioned warm up IP addresses by each worker node. You must set these parameters to prevent private IP address exhaustion.

To update the managed Amazon VPC CNI add-on parameter values during the add-on installation or update, complete the following steps:

**Note:** In the following commands replace all **example-values** with your values.

1\. Write your configurations to a JSON file:
    
    
    $ cat <<EOF > example-json-file
    {
        "env": {
            "MINIMUM_IP_TARGET": "example-value",
            "WARM_ENI_TARGET": "example-value",
            "WARM_IP_TARGET": "example-value"
          }
    }
    EOF

2\. Use one of the following methods to apply the file:

  * Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>). From the cluster console dashboard, choose the **Add-ons** tab, select the **VPC CNI** add-on, choose **Edit** , and then choose **Optional configuration** settings. Paste the contents of your JSON file in the **Configuration Values** field.
  * If you're installing the add-on for the first time, then run the [create-addon](<https://docs.aws.amazon.com/cli/latest/reference/eks/create-addon.html>) command:


    
    
    $ aws eks create-addon --addon-name vpc-cni ---cluster-name <example-cluster-name> --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

  * If you're updating an existing add-on, then run the [update-addon](<https://docs.aws.amazon.com/cli/latest/reference/eks/update-addon.html>) command:


    
    
    $ aws eks update-addon --addon-name vpc-cni ---cluster-name <example-cluster-name> --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

3\. Confirm that the configurations updated:
    
    
    $ kubectl get pods -n kube-system <example-aws-node-pod-ID> -o jsonpath='{.spec.containers[*].env}'

### Amazon EBS CSI driver

The Amazon EBS CSI driver add-on manages Amazon EBS volume attachments to pods. This add-on lets you control the limit of volumes that are attached to worker nodes. To update the volume limit, you must update arguments that pass to the **ebs-plugin** container and the **volume-attach-limit** parameter with your value.

To use the Amazon EBS CSI driver add-on to update the **volume-attach-limit** parameter, complete the following steps:

1\. Write your configurations to a JSON file:
    
    
    $ cat <<EOF > example-json-file  
    {  
        "node": {  
            "volumeAttachLimit": example-value  
        }  
    }  
    EOF

2\. Use one of the following methods to apply the file:

  * Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>). From the cluster console dashboard, choose the **Add-ons** tab, select the **Amazon EBS CSI Driver** add-on, choose **Edit** , and then choose **Optional configuration** settings. Paste the contents of your JSON file in the **Configuration Values** field.
  * If you're installing the add-on for the first time, then run the **create-addon** command:


    
    
    $ aws eks create-addon --addon-name aws-ebs-csi-driver ---cluster-name <example-cluster-name> --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

  * If you're updating an existing add-on, then run the **update-addon** command:


    
    
    $ aws eks update-addon --addon-name aws-ebs-csi-driver --cluster-name <example-cluster-name --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

3\. Confirm that the configurations updated:
    
    
    $  kubectl get ds -n kube-system ebs-csi-node -o jsonpath='{.spec.template.spec.containers[*].args}'

### CoreDNS

The CoreDNS add-on lets you increase the value of resource requests and limits so that CoreDNS pods can meet large cluster requests.

To use the CoreDNS add-on to update the value of resource requests and limits, complete the following steps:

1\. Write your configurations to a JSON file:
    
    
    $ cat <<EOF > example-json-file  
    {  
        "resources": {  
            "limits": {  
                "cpu": "example-value",  
                "memory": "example-value",  
            },  
            "requests": {  
                "cpu": "example-value",  
                "memory": "example-value"  
            }  
        }  
    }  
    EOF

2\. Use one of the following methods to apply the file:

  * Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>). From the cluster console dashboard, choose the **Add-ons** tab, select the **CoreDNS** add-on, choose **Edit** , and then choose **Optional configuration** settings. Paste the contents of your JSON file in the **Configuration Values** field.
  * If you're installing the add-on for the first time, then run the **create-addon** command:


    
    
    $ aws eks create-addon --addon-name coredns ---cluster-name <example-cluster-name> --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

  * If you're updating an existing add-on, then run the **update-addon** command:


    
    
    $ aws eks update-addon --addon-name coredns --cluster-name <example-cluster-name> --resolve-conflicts OVERWRITE --configuration-values file:///example-json-file

3\. Confirm that the configurations updated:
    
    
    $ kubectl get pods -n kube-system <example-coredns-pod-ID> -o jsonpath='{.spec.containers[*].resources}'

### Tolerations

You can apply tolerations to recent versions of add-on images, and update the toleration keys and values as needed.

Example in YAML format:
    
    
    $ cat <<EOF > example-yaml-file  
    tolerations:  
          - effect: example-value  
            key: example-value  
            operator: example-value  
            value: example-value  
    EOF

## Related information

[Kubernetes field management](<https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-field-management.html>)

[Amazon EKS add-ons: Advanced configuration](<https://aws.amazon.com/blogs/containers/amazon-eks-add-ons-advanced-configuration/>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
