Original URL: <https://repost.aws/knowledge-center/eks-worker-nodes-image-cache>

# How do I configure Amazon EKS worker nodes to clean up the image cache at a specified percent of disk usage?

I want to use Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes to clean up the image cache at a specified percent of disk usage.

## Short description

To clean up the image cache with Amazon EKS worker nodes, use the following kubelet garbage collection arguments:

  * The **\--image-gc-high-threshold** argument defines the percent of disk usage that initiates image garbage collection. The default is 85%.
  * The **\--image-gc-low-threshold** argument defines the LowThresholdPercent value. The kubelet deletes images until disk usage reaches this value. The default is 50%.



**Note:** In the following resolution, the kubelet garbage collection arguments clean up the image cache in the worker node when the disk usage reaches 70%. The **\--image-gc-high-threshold** is set to 70%. The **\--image-gc-low-threshold** is set to 50%.

Based on your use case, follow the resolution steps to add kubelet garbage collection to the default config file or an existing bode. Then, verify that the arguments exist in the node endpoint.

For more information, see [Garbage collection of unused containers and images](<https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images>) on the Kubernetes website.

## Resolution

**Note:** The following resolution applies to Amazon EKS-optimized Linux AMIs.

### Add the kubelet garbage collection arguments to the default kubelet-config

Use the [Custom Launch Template](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html>) feature of Amazon EKS to add the kubelet garbage collection arguments to the default kubelet-config file in the Amazon Machine Image (AMI). When you create the launch template, specify arguments in **UserData**.

  1. The following command updates the KUBELET_CONFIG file in AMI. It sets **imageGCHighThresholdPercent** =70 and **imageGCLowThresholdPercent** =60. For more information, see [Configure instance details](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/launching-instance.html#configure_instance_details_step>).
    
        #!/bin/bash
    set -o xtrace
    
    KUBELET_CONFIG=/etc/kubernetes/kubelet/kubelet-config.json
    
    # Inject imageGCHighThresholdPercent value unless it has already been set.
    if ! grep -q imageGCHighThresholdPercent $KUBELET_CONFIG;
    then
    echo "$(jq ".imageGCHighThresholdPercent=70" $KUBELET_CONFIG)" > $KUBELET_CONFIG
    fi
    
    # Inject imageGCLowThresholdPercent value unless it has already been set.
    if ! grep -q imageGCLowThresholdPercent $KUBELET_CONFIG;
    then
    echo "$(jq ".imageGCLowThresholdPercent=60" $KUBELET_CONFIG)" > $KUBELET_CONFIG
    fi
    
    /etc/eks/bootstrap.sh your-cluster-name

Note: Replace **your-cluster-name** with your Amazon EKS cluster name. If you don't use the default kubelet config file, then update the file name.
  2. Create a worker node group with the launch template.



### Add the kubelet garbage collection arguments to an existing worker node

**Important:** The following steps require that you connect to an existing worker node with SSH and have **sudo** access. You must complete these steps on all the existing worker nodes in your Amazon EKS cluster.

  1. [Connect to an existing worker node using SSH](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html>).

  2. Open the **/etc/kubernetes/kubelet/kubelet-config.json** file in your worker nodes. If you launched the worker node with **EKSCTL** , then open **/etc/eksctl/kubelet.yaml** :
    
        sudo vi /etc/kubernetes/kubelet/kubelet-config.json
    #WORKER NODES LAUNCHED USING EKSCTL
    
    sudo vi /etc/eksctl/kubelet.yaml

  3. Based on how you launched your worker nodes, add the kubelet garbage collection arguments to the **kubelet-config.json** or **kubelet.yaml** file. Then, save the file:
    
        {  "kind": "KubeletConfiguration",
      "apiVersion": "kubelet.config.k8s.io/v1beta1",
      .
      .
      .
      "imageGCHighThresholdPercent": 70,         ==> Add the argument under the same alignment as the "kind"
      "imageGCLowThresholdPercent": 60,
      "maxPods": ...
    }
    
    
    #WORKER NODES LAUNCHED USING EKSCTL
    
    kind: KubeletConfiguration
    kubeReserved:
      cpu: 70m
      ephemeral-storage: 1Gi
      memory: 1843Mi
    serverTLSBootstrap: true
    imageGCHighThresholdPercent: 70        ==> Add the arguments under the alignment "Kind" in the yaml file
    imageGCLowThresholdPercent: 60

  4. To restart the kubelet service in the worker node, run the following command:
    
        sudo service kubelet restart




### Verify that the new kubelet garbage collection arguments are in the node configz endpoint

  1. To get the name of your worker nodes, run the following command:
    
        kubectl get nodes

  2. To open a connection to the API server, run the following command:
    
        kubectl proxy

  3. To check the node configz, open a new terminal. Then, run the following command:
    
        curl -sSL "http://localhost:8001/api/v1/nodes/node_name/proxy/configz" | python3 -m json.tool

**Note:** Replace **node_name** with your node name from the list of nodes that you retrieved earlier. If cURL and Python aren't available, then open the URL in a web browser.

This command returns output from the **kubeletconfig**. This output includes your settings from the **bootstrap.sh** file. See the following example:
    
        {"kubeletconfig": {
      .
      .
      "imageGCHighThresholdPercent": 70,          <=== The new value is set to 70 as given in UserData
      "imageGCLowThresholdPercent": 60,           <=== The new value is set to 50 as given in UserData
      .
      .
    }
    }




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
