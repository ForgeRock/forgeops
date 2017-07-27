# prepsql

This charts prepares a Google Cloud SQL instance to be ready for an IDM deployment. 

You must edit cloud-sql.sh to your requirements. This initial script is run to create the Cloud SQL instance 
and the idm user. 

The chart is then deployed, which connects to the database and creates the schema for IDM. 

After the chart runs, you can remove it using `helm delete`.

