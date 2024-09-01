Original URL: <https://repost.aws/knowledge-center/eks-error-invalid-identity-token>

# How do I troubleshoot the "InvalidIdentityToken" error when I use the Amazon EKS IAM role to access the service account?

The thumbprint for my Amazon Elastic Kubernetes Service (Amazon EKS) cluster changed and caused the Application Load Balancer controller to fail updates. Or, my Amazon EKS pods are in the failed state with the "InvalidIdentityToken" error.

## Resolution

Amazon EKS service accounts use OpenID Connect (OIDC) to authenticate. When you [create an AWS Identity and Access Management (IAM) OIDC identity provider (IdP) for your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>), the [thumbprint that's generated](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html>) uses the root certificate. The Amazon root Certificate Authority (CA) has a validation period of approximately 25 years.

You receive the "WebIdentityErr: failed to retrieve credentials\r\ncaused by: InvalidIdentityToken: OpenIDConnect provider's HTTPS certificate doesn't match configured thumbprint\r\n" error in the following scenarios:

  * The thumbprint that's used in the OIDC provider is expired.
  * The thumbprint doesn't match the CA.



To troubleshoot this issue and obtain a thumbprint, [install](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html#oidc-install-openssl>) and [configure](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html#oidc-configure-openssl>) the OpenSSL command line tool.

### Find the URL for the OIDC IdP

To find the URL for the OIDC IdP, complete the following steps:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>).

  2. In the navigation pane, choose **Clusters**.

  3. Select the cluster that you want to check.

  4. Choose the **Configuration** tab.

  5. Under the **Details** section, note the OICD IdP URL.  
**Example:** https://oidc.eks.us-east-1.amazonaws.com/id/1111222233334444555566667777888F/

Include **/.well-known/openid-configuration** at the end of the OICD IdP URL to form the URL for the IdP's configuration document.

**Example:** https://oidc.eks.us-east-1.amazonaws.com/id/1111222233334444555566667777888F/.well-known/openid-configuration. Access this URL in a web browser, and note the **jwks_uri** value from the output. The browser output looks similar to the following:
    
        {"issuer":"https://oidc.eks.us-east-1.amazonaws.com/id/1111222233334444555566667777888F","jwks_uri":"https://oidc.eks.us-east-1.amazonaws.com/id/1111222233334444555566667777888F/keys","authorization_endpoint":"urn:kubernetes:programmatic_authorization","response_types_supported":["id_token"],"subject_types_supported":["public"],"claims_supported":["sub","iss"],"id_token_signing_alg_values_supported":["RS256"]}




### Display certificates

Use the OpenSSL command line tool to run the following command to display all the certificates that are used:  
**Note:** Replace **oidc.eks.us-east-2.amazonaws.com** with your domain name.
    
    
    openssl s_client -connect oidc.eks.us-east-2.amazonaws.com:443 -showcerts

The output looks similar to the following:
    
    
    [root@ip-172-31-1-202 ~]# openssl s_client -connect oidc.eks.us-east-2.amazonaws.com:443 -showcertsCONNECTED(00000003)
    depth=4 C = US, O = "Starfield Technologies, Inc.", OU = Starfield Class 2 Certification Authority
    verify return:1
    depth=3 C = US, ST = Arizona, L = Scottsdale, O = "Starfield Technologies, Inc.", CN = Starfield Services Root Certificate Authority - G2
    verify return:1
    depth=2 C = US, O = Amazon, CN = Amazon Root CA 1
    verify return:1
    depth=1 C = US, O = Amazon, OU = Server CA 1B, CN = Amazon
    verify return:1
    depth=0 CN = *.execute-api.us-east-2.amazonaws.com
    verify return:1
    ---
    Certificate chain
     0 s:/CN=*.execute-api.us-east-2.amazonaws.com
       i:/C=US/O=Amazon/OU=Server CA 1B/CN=Amazon
    -----BEGIN CERTIFICATE-----
    CERTIFICATE Redacted
    -----END CERTIFICATE-----
     1 s:/C=US/O=Amazon/OU=Server CA 1B/CN=Amazon
       i:/C=US/O=Amazon/CN=Amazon Root CA 1
    -----BEGIN CERTIFICATE-----
    CERTIFICATE Redacted
    -----END CERTIFICATE-----
     2 s:/C=US/O=Amazon/CN=Amazon Root CA 1
       i:/C=US/ST=Arizona/L=Scottsdale/O=Starfield Technologies, Inc./CN=Starfield Services Root Certificate Authority - G2
    -----BEGIN CERTIFICATE-----
    CERTIFICATE Redacted
    -----END CERTIFICATE-----
     3 s:/C=US/ST=Arizona/L=Scottsdale/O=Starfield Technologies, Inc./CN=Starfield Services Root Certificate Authority - G2
       i:/C=US/O=Starfield Technologies, Inc./OU=Starfield Class 2 Certification Authority
    -----BEGIN CERTIFICATE-----
    MIIEdTCCA12gAwIBAgIJAKcOSkw0grd/MA0GCSqGSIb3DQEBCwUAMGgxCzAJBgNV
    BAYTAlVTMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTIw
    MAYDVQQLEylTdGFyZmllbGQgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0
    eTAeFw0wOTA5MDIwMDAwMDBaFw0zNDA2MjgxNzM5MTZaMIGYMQswCQYDVQQGEwJV
    UzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTElMCMGA1UE
    ChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjE7MDkGA1UEAxMyU3RhcmZp
    ZWxkIFNlcnZpY2VzIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEi
    MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVDDrEKvlO4vW+GZdfjohTsR8/
    y8+fIBNtKTrID30892t2OGPZNmCom15cAICyL1l/9of5JUOG52kbUpqQ4XHj2C0N
    Tm/2yEnZtvMaVq4rtnQU68/7JuMauh2WLmo7WJSJR1b/JaCTcFOD2oR0FMNnngRo
    Ot+OQFodSk7PQ5E751bWAHDLUu57fa4657wx+UX2wmDPE1kCK4DMNEffud6QZW0C
    zyyRpqbn3oUYSXxmTqM6bam17jQuug0DuDPfR+uxa40l2ZvOgdFFRjKWcIfeAg5J
    Q4W2bHO7ZOphQazJ1FTfhy/HIrImzJ9ZVGif/L4qL8RVHHVAYBeFAlU5i38FAgMB
    AAGjgfAwge0wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0O
    BBYEFJxfAN+qAdcwKziIorhtSpzyEZGDMB8GA1UdIwQYMBaAFL9ft9HO3R+G9FtV
    rNzXEMIOqYjnME8GCCsGAQUFBwEBBEMwQTAcBggrBgEFBQcwAYYQaHR0cDovL28u
    c3MyLnVzLzAhBggrBgEFBQcwAoYVaHR0cDovL3guc3MyLnVzL3guY2VyMCYGA1Ud
    HwQfMB0wG6AZoBeGFWh0dHA6Ly9zLnNzMi51cy9yLmNybDARBgNVHSAECjAIMAYG
    BFUdIAAwDQYJKoZIhvcNAQELBQADggEBACMd44pXyn3pF3lM8R5V/cxTbj5HD9/G
    VfKyBDbtgB9TxF00KGu+x1X8Z+rLP3+QsjPNG1gQggL4+C/1E2DUBc7xgQjB3ad1
    l08YuW3e95ORCLp+QCztweq7dp4zBncdDQh/U90bZKuCJ/Fp1U1ervShw3WnWEQt
    8jxwmKy6abaVd38PMV4s/KCHOkdp8Hlf9BRUpJVeEXgSYCfOn8J3/yNTd126/+pZ
    59vPr5KW7ySaNRB6nJHGDn2Z9j8Z3/VyVOEVqQdZe4O/Ui5GjLIAZHYcSNPYeehu
    VsyuLAOQ1xk4meTKCRlb/weWsKh/NEnfVqn3sF/tM+2MR7cEXAMPLE=
    -----END CERTIFICATE-----
    ---
    Server certificate
    subject=/CN=*.execute-api.us-east-2.amazonaws.com
    issuer=/C=US/O=Amazon/OU=Server CA 1B/CN=Amazon

If you see more than one certificate in the output, then look for the last certificate at the end of the output. The last certificate is the root CA in the certificate authority chain.

### Create a certificate file

Create a certificate file (example: certificate.crt), and copy the contents of the last certificate to the file.

Then, run the following command:
    
    
    openssl x509 -in certificate.crt -text

The output looks similar to the following:
    
    
    [root@ip-172-31-1-202 ~]# openssl x509 -in certificate.crt -textCertificate:    Data:
            Version: 3 (0x2)
            Serial Number:
                a7:0e:4a:4c:34:82:b7:7f
        Signature Algorithm: sha256WithRSAEncryption
            Issuer: C=US, O=Starfield Technologies, Inc., OU=Starfield Class 2 Certification Authority
            Validity
                Not Before: Sep  2 00:00:00 2009 GMT
                Not After : Jun 28 17:39:16 2034 GMT

Check the validity of the certificate from the values in the **Not Before** and **Not After** fields. In the preceding output, the validity of the CA is approximately 25 years.

### Replace an expired certificate

If the output shows that the certificate is expired, then you must renew the certificate with your OIDC IdP.

After you renew the certificate, run the following command with the OpenSSL command line tool to get the latest thumbprint:
    
    
    openssl x509 -in certificate.crt -fingerprint -noout

The output looks similar to the following:
    
    
    SHA1 Fingerprint=9E:99:A4:8A:99:60:B1:49:26:BB:7F:3B:02:E2:2D:A2:B0:AB:72:80

Delete the colons (:) from this string to get the final thumbprint:
    
    
    9E99A48A9960B14926BB7F3B02E22DA2B0AB7280

Run the following command to get the latest thumbprint:
    
    
    $ openssl x509 -in certificate.crt -fingerprint -noout | sed s/://g

### Update to the latest thumbprint 

If the current thumbprint is expired, then use the IAM console or AWS Command Line Interface (AWS CLI) to replace it with the latest thumbprint.

**IAM console**

To use the IAM console, complete the following steps:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>).
  2. In the navigation pane, choose **Identity providers**.
  3. Choose the IdP that you want to update.
  4. In the **Thumbprints** section, choose **Manage**.
  5. Choose **Add thumbprint** , and then enter the new value.
  6. Choose **Save changes**.



**AWS CLI**

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

Run the [update-open-id-connect-provider-thumbprint](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/update-open-id-connect-provider-thumbprint.html>) AWS CLI command:
    
    
    aws iam update-open-id-connect-provider-thumbprint --open-id-connect-provider-arn arn:aws:iam::111122223333:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/5ECB2797CB1324A37FC79E3C46851CED --thumbprint-list 9E99A48A9960B14926BB7F3B02E22DA2B0AB7280

## Related information

[Creating OpenID Connect (OIDC) identity providers](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
