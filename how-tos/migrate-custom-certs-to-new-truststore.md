# Adding user supplied certs to truststore
The steps in this how-to help customers understand how to add user supplied certs to the truststore for PingAM and PingIDM.

## Truststore env vars on pods
The following env vars are used to point to specific paths for certificates. This info is only provided  
for greater context. They do not need to be updated.   

**AM_DEFAULT_TRUSTSTORE**: PingAM and PingIDM now use the default Java ca certificate as the default truststore.  
**AM_PEM_TRUSTSTORE**: Custom user supplied certificates to append to the truststore.  
**AM_PEM_TRUSTSTORE_DS**: The DS SSL key pair used for LDAPS connectivity between PingAM and PingDS. 

## Add user supplied certificates to the truststore - Helm

### Provide certificate via a manually created secret 
> **NOTE**: This is the preferred option. Certificate should be in pem format.
* Set platform.truststore.secret.enabled to true
* Ensure truststore.secret.create is set to "false"
* Create Kubernetes secret containing certificate:  
```bash
kubectl --namespace *mynamespace* create secret generic platform-truststore-certificates --from-file=/path/to/my/certificates
```

### Provide certificate content directly into your values.yaml
> **NOTE**: Useful for testing purposes or if you only have a single certificate
* Set platform.truststore.secret.enabled to true
* Set truststore.secret.create is set to "true"
* Add the content of the certificate to platform.truststore.secret.certificates

## Add user supplied certificates to the truststore - Kustomize
Create a Kubernetes secret containing the certificate. Must be in PEM format: 
```bash 
kubectl --namespace mynamespace create secret generic platform-truststore-certificates --from-file=/path/to/my/certificates
```

## Add existing secret containing user supplied certificates to the truststore
Either:
1. Recreate your current secret with the name platform-truststore-certificates to match the above steps, or
2. In your env (overlay/values.yaml), update the mountpoints where platform-truststore-certificates is configured with the name of your custom secret
