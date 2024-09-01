Original URL: <https://repost.aws/knowledge-center/eks-configure-nginx-ingress-controller>

# How do I configure the NGINX Ingress Controller to increase the client request body, activate CORS to allow additional headers, and use WebSocket with Amazon EKS?

I want to configure the NGINX Ingress Controller to increase the size of the client request body with my Amazon Elastic Kubernetes Service (Amazon EKS) cluster. I also want to activate Cross-Origin Resource Sharing (CORS) to allow additional headers, and use WebSocket with the NGINX Ingress Controller.

## Short description

Choose one of the following configuration options:

  * To increase the size of the client request body, complete the steps in the **Configure the maximum body size** section.
  * To activate CORS to allow additional headers, complete the steps in the **Activate CORS** section.
  * To use WebSocket with NGINX Ingress Controller, complete the steps in the **Use WebSocket** section.



## Resolution

### Configure the maximum body size

If your body size request exceeds the maximum allowed size of the client request body, then the NGINX Ingress Controller returns an HTTP 413 error. Use the **client_max_body_size** parameter to configure a larger size:
    
    
    nginx.ingress.kubernetes.io/proxy-body-size: 8m

**Note:** The default value of the **proxy-body-size** is 1 M. Make sure to change the number to the size that you need.

In some cases, you might need to increase the maximum size for all post body data and file uploads. For PHP, you must increase the **post_max_size** and **upload_max_file_size** values in the **php.ini** configuration.

### Activate CORS

To activate CORS in an Ingress rule, add the following annotation:
    
    
    nginx.ingress.kubernetes.io/enable-cors: "true"

The following example shows that the **X-Forwarded-For** header is accepted:
    
    
    nginx.ingress.kubernetes.io/cors-allow-headers: "X-Forwarded-For"

For more information, see [Enable CORS](<https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#enable-cors>) on the Kubernetes website.

### Use WebSocket

NGINX supports WebSocket without additional configuration. To avoid a closed connection, increase the **proxy-read-timeout** and **proxy-send-timeout** values.

In the following example, 120 seconds is set for **proxy read timeout** and **proxy send timeout** :
    
    
    nginx.ingress.kubernetes.io/proxy-read-timeout: "120"nginx.ingress.kubernetes.io/proxy-send-timeout: "120"

**Note:** The default value of the preceding two annotations is **60 seconds**.

## Related information

[Annotations](<https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/>) on the Kubernetes website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
