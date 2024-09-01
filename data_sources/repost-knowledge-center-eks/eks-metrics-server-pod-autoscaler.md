Original URL: <https://repost.aws/knowledge-center/eks-metrics-server-pod-autoscaler>

# How do I set up Kubernetes Metrics Server and Horizontal Pod Autoscaler on Amazon EKS?

I want to set up Kubernetes Metrics Server and Horizontal Pod Autoscaler (HPA) on Amazon Elastic Kubernetes Service (Amazon EKS).

## Resolution

### Set up your environment

  1. [Create an Amazon Elastic Compute Cloud (Amazon EC2) instance](<https://docs.aws.amazon.com/efs/latest/ug/gs-step-one-create-ec2-resources.html>).
  2. [Install kubectl on your EC2 instance](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  3. [Install](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html>) and [configure](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html>) the latest version of the AWS Command Line Interface (AWS CLI) on your EC2 instance.
  4. [Configure your kubeconfig file](<https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html>) to point to the Amazon EKS cluster.



### Create a Kubernetes Metrics Server

1\. To install Metrics Server, run the following command:
    
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

2\. To confirm that Metrics Server is running, run the following command:
    
    
    kubectl get pods -n kube-system -l k8s-app=metrics-server

The output is similar to the following:
    
    
    kubectl get pods -n kube-system -l k8s-app=metrics-server
    metrics-server-85cc795fbf-79d72   1/1     Running   0          22s

### Create a php-apache deployment and a service

1\. To create a **php-apache** deployment, run the following command:
    
    
    kubectl create deployment php-apache --image=k8s.gcr.io/hpa-example

2\. To set the CPU requests, run the following command:
    
    
    kubectl patch deployment php-apache -p='{"spec":{"template":{"spec":{"containers":[{"name":"hpa-example","resources":{"requests":{"cpu":"200m"}}}]}}}}'

**Important:** If you don't set the value for **cpu** correctly, then the CPU utilization metric for the pod isn't defined and the HPA can't scale.

3\. To expose the deployment as a service, run the following command:
    
    
    kubectl create service clusterip php-apache --tcp=80

4\. To create an HPA, run the following command:
    
    
    kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

5\. To confirm that the HPA was created, run the following command:
    
    
    kubectl get hpa

6\. To create a pod to connect to the deployment that you created earlier, run the following command:
    
    
    kubectl run -i --tty load-generator --image=busybox /bin/sh

7\. To test a load on the pod in the namespace that you used in step 1, run the following script:
    
    
    while true; do wget -q -O- http://php-apache; done

**Note:** To exit the while loop and the tty session of the load generator pod, use CTRL + C to cancel the loop. Then, use CTRL + D to exit the session.

8\. To see how the HPA scales the pod based on CPU utilization metrics, run the following command (preferably from another terminal window):
    
    
    kubectl get hpa -w

The Metrics Server is now up and running, and you can use it to get resource-based metrics.

9\. To clean up the resources used for testing the HPA, run the following commands:
    
    
    kubectl delete hpa,service,deployment php-apache
    kubectl delete pod load-generator

## Related information

[Horizontal Pod Autoscaling](<https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/>) (on the Kubernetes website)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
