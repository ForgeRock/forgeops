# Deploying Mailhog in Minikube 

## Introduction

Mailhog is a lightweight utility for sending and viewing email messages in a 
Kubernetes cluster, especially in a development environment. It is easily used 
for testing purposes. You can use Mailhog to:
* Test SMTP email delivery 
* View received email messages using the web UI
* Optionally integrate with an SMTP server for email delivery

**Note**: **This is not meant for use in production environment**. 
ForgeRock does not guarantee the individual success developers may have in 
implementing the code on their development platforms.

## References

* [Mailhog deployment guide](https://artifacthub.io/packages/helm/codecentric/mailhog)
* [Mailhog documentation on Github](https://github.com/mailhog/MailHog/tree/master/docs)

## Set up Mailhog in your Kubernetes cluster

### Prerequisites:
1. You have set up the CDK.
1. You have installed Helm.
1. Your Kubernetes context is set to your cluster.
1. You have already enabled SMTP (such as Postfix) in your host system. 

### Deploying Mailhog

1. Install Mailhog in your namespace in the cluster using Helm:

    ```
    kubectx minikube

    kubens my-namespace

    helm repo add codecentric https://codecentric.github.io/helm-charts
    
    helm install mailhog codecentric/mailhog 
    ```

1. Enable the postfix mailing daemon to route requests by inserting the following <br/>lines at the end of the `/etc/postfix/main.cf` file:

    ```
    myhostname = localhost
    relayhost = [localhost]:1025
    ```

1. Verify that the Mailhog pod is running:

    ```
    kubectl get pods | grep mailhog
    mailhog-16...zl   1/1     Running     1          23m
    ```

1. In a terminal window, set up port forwarding for SMTP (port 1025):

    ```
    export POD_NAME=mailhog-16...zl

    kubectl port-forward --namespace my-namespace $POD_NAME 1025
    ```
 
1. In another terminal window, set up port forwarding for HTTP view (port 8025):

    ```
    export POD_NAME=mailhog-16...zl

    kubectl port-forward --namespace my-namespace $POD_NAME 8025
    ```

1. Verify that you are able to send and view emails using local Mailhog server:

    1. Open a new browser window, and access the HTTP port of the  Mailhog server 
    pod, for example: my-namespace.iam.example.com:8025. 
    
    1. In a separate terminal window, run the following command:
        ```
        date | mail -s "Test Email" test@mailhog.local
        ```

    1. Notice that the message you sent appears in the Mailhog HTTP interface.   
    

## Enable the email service in IDM
After verifying that the Mailhog server is able to send and receive messages, you 
can configure email settings in the IDM server.

1. Log in to the IDM administration console and configure email settings. 
![Configure email setting in IDM console](./images/idm-email-setting.png)

## Test resetting a user's password

1. Using a web browser, access the password reset service in your deployment, <br/> for example: https://my-namespace.iam.example.com/am/?service=ResetPassword 

1. Enter the email ID of the user whose password needs to be reset - for example `t1@mailhog.local`. <br/>(**Note**: @mailhog.local is the default email domain used.)

1. A notification appears indicating that the password reset email has been sent.
![View notification of email](./images/email-notify.png)

1. View your Mailhog inbox to see if you have received the email to reset password.
![Receive email to reset password](./images/reset-password-email-0.png) 

1. Open the reset password email and click the `Reset Password link`.
![Open the email and click the Reset Password link](./images/reset-password-link.png)

1. Enter the new password.<br/>
![Change password](./images/change-password.png)

1. Verify that you can log in after you have reset the password.
![After you have rest the password](./images/after-changing-password.png).

 There you have it, a simple but effective way of setting up and testing reset 
 password in a development environment.  