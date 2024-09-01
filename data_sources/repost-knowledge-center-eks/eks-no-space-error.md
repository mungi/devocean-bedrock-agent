Original URL: <https://repost.aws/knowledge-center/eks-no-space-error>

# How do I resolve the "No space left on device: unknown" error on my Amazon EKS worker node?

I want to resolve the "No space left on device: unknown" error on my Amazon Elastic Kubernetes Service (Amazon EKS) worker node.

## Resolution

To resolve the **No space left on device: unknown** error on your Amazon EKS worker node, complete the following steps:

  1. Cordon the worker node to remove the worker node from the cluster and to prevent pods from being scheduled:  
**Note:** Replace **example-worker-node** with the worker node name. Make sure that you use the correct IP address as part of the worker node name (ex. **ip-123-456-78-90.aws-region.compute.internal**).
    
        kubectl cordon example-worker-node

  2. Drain the worker node:  
**Note:** Replace **example-worker-node** with the worker node name. Make sure that you use the correct IP address as part of the worker node name (ex. **ip-123-456-78-90.aws-region.compute.internal**).
    
        kubectl drain --ignore-daemonsets example-worker-node

  3. Open the [AWS Management Console](<https://docs.aws.amazon.com/signin/latest/userguide/console-sign-in-tutorials.html>).

  4. To connect to the affected worker node, use [SSH](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html>) or [Sessions Manager, a capability of AWS Systems Manager](<https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/connect-to-an-amazon-ec2-instance-by-using-session-manager.html>).

  5. Switch to the root user:
    
        sudo su -

  6. Manually prune or delete dangling and unused images. By default, the namespace is **k8s.io**.  
**Note:** You might receive the error message **Buildkit is not running or installed errors** when you run this command. You can ignore this error and any other error messages that you might receive when you run this command.
    
        nerdctl system prune --all --namespace=k8s.io

  7. Uncordon the worker node to put the worker node back into service:  
**Note:** Replace **example-worker-node** with the worker node name. Make sure that you use the correct IP address as part of the worker node name (ex. **ip-123-456-78-90.aws-region.compute.internal**).
    
        kubectl uncordon example-worker-node

  8. Check that the worker node status is **Ready**.  
**Note:** Replace **example-worker-node** with the worker node name. Make sure that you use the correct IP address as part of the worker node name (ex. **ip-123-456-78-90.aws-region.compute.internal**).
    
        kubectl get nodes | grep example-worker-node

  9. Check that you can schedule pods and that they run successfully:  
**Note:** Replace **example-worker-node** with the worker node name. Make sure that you use the correct IP address as part of the worker node name (ex. **ip-123-456-78-90.aws-region.compute.internal**).
    
        kubectl get pods -A -o wide | grep example-worker-node




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
