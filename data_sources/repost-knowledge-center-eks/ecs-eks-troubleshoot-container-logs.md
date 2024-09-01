Original URL: <https://repost.aws/knowledge-center/ecs-eks-troubleshoot-container-logs>

# How do I troubleshoot missing container logs for Amazon ECS or Amazon EKS?

I can't find the container logs for my Amazon Elastic Container Service (Amazon ECS) task or Amazon Elastic Kubernetes Service (Amazon EKS) pod.

## Short description

If you are missing containers logs for Amazon ECS or Amazon EKS, then there might be problems with the host instance. Or, if your containerized application doesn't writer to the correct location, then your logs might not be visible to the Docker daemon.

The following are common scenarios where your containerized application doesn't write some or all of your logs:

  * You run the **docker logs yourContainerName** command on a container instance in Amazon ECS.
  * You use the [awslogs log driver](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html>) for a task in Amazon ECS.
  * You run the **kubectl logs yourPodName** command for an Amazon EKS cluster.



## Resolution

### Troubleshoot the logs for your Amazon ECS tasks

**Confirm that your task is correctly configured**

  * Review the log configuration for the container that has your logs. The log driver is set by the [logConfiguration](<https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html>) parameter in the [container definition](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#advanced_container_definition_params>) section of your ECS task definition. Log drivers are set per container. If your ECS task has multiple container definitions, then verify that the log configuration is correct for the containers with your logs.
  * Review your [task cleanup](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/automated_image_cleanup.html>) configuration for your container instance. The [Amazon ECS container agent](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-versions.html>) automatically removes log files to reclaim free space. To preserve your log files for longer on your container instance, reduce the frequency of your task cleanup.



**Review your CloudWatch logs**

If your tasks use the **awslogs** log driver, then the logs are streamed to Amazon CloudWatch Logs. These logs are never written to the container instance. The **docker logs yourContainerName** command returns the following error message: "Error response from daemon: configured logging driver does not support reading."

**Grant the correct permissions**

To allow Amazon Elastic Compute Cloud (Amazon EC2) launch types to stream to CloudWatch Logs, grant permissions to your [container instance's IAM role](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html>).

To allow AWS Fargate launch types to stream to CloudWatch Logs, grant permissions to the [task IAM role](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html>) used by your task.

If your logs are still missing, then complete the steps in the **Troubleshoot the application container** section.

### Troubleshoot the logs for your Kubernetes pods on Amazon EKS

To return the log files generated from a pod's container, run the following **kubectl** command:
    
    
    kubectl logs yourPodName

**Note:** The kubelet automatically removes log files after a pod exits. For more information, see [Garbage collection of unused containers and images](<https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images>) on the Kubernetes website. To preserve these log files for longer on a worker node, configure the kubelet to run garbage collection less frequently.

If your logs are still missing, then complete the steps in the **Troubleshoot the application container** section.

### Troubleshoot the application container

To troubleshoot the application container, complete the following tasks:

  * Set your application to the correct log level during your container build.  
**Note:** Your application might require you to set logging through an environment variable or in a configuration file.
  * Make your application the **ENTRYPOINT** of the container. For more information, see [ENTRYPOINT](<https://docs.docker.com/develop/develop-images/instructions/#entrypoint>) on the Docker Docs website.  
**Note:** The **ENTRYPOINT** in your dockerfile is the process where **STDOUT** and **STDERR I/O** streams are logged. For more information, see [View container logs](<https://docs.docker.com/config/containers/logging/>) on the Docker Docs website.
  * Build your container with application log files linked to **STDOUT** and **STDERR**. Or, configure your application to directly log to **/proc/1/fd/1** (**stdout**) and **/proc/1/fd/2** (**stderr**). For examples, see [nginx](<https://hub.docker.com/_/nginx>) and [httpd](<https://hub.docker.com/_/httpd>) official container images on the Docker Hub website.  
**Note:** If your use case allows, then make your application process the parent process in your container. If your container uses a shell script as the **ENTRYPOINT** , then configure the script to initialize your container data at runtime.



* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Container Service](<https://repost.aws/tags/TAefn4YSprR-uCBYmbofOpHw/amazon-elastic-container-service>)

Language

English
