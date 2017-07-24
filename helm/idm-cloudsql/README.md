# Sample Helm chart to deploy OpenIDM using Google Cloud SQL as the Repository

This chart deploys IDM in Kubernetes and connects to a Cloud SQL repository instance. 
A sql proxy side car is used to securely establish a connection to the database.

This relies on a secret:  `cloudsql-instance-credentials`. This secret was previously 
created using the scripts in etc/gke/prepsql. The secret is the json service
 account file for your cloud SQL instance. See the 
[cloud sql docs](https://cloud.google.com/sql/docs/postgres/) for more information.
 
 
See the etc/gke/prepsql chart which creates the schema needed by IDM.


