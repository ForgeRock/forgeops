# File Based Configuration (FBC) Notes

File Based Config (FBC) requires a config store to be present (this will be fixed for 7.x).

We are using the "ds-idrepo" instance as the all in one DS instance for the userstore, configstore, and CTS. For production deployments
a separate ctsstore will also be configured.

IMPORTANT: The file based configuration must match the AM war file version that created it. There
is currently no upgrade capability. If you update the war file (to say a new nightly build), you must regenerate
the configuration. For this reason the file configurations are not currently checked in to git (am-fbc/tmp is in .gitignore)

## Preparing the ds-idrepo and initial FBC

You must prepare the ds-idrepo instance with an amster install. You can not do this currently using file based configuration - the
AM installer must run. Once you have your ds-idrepo prepared, you are advised to retain the PVC between development sessions
so that you do not have to repeat this procedure.

Steps:

* Edit the `Dockerfile` in this directory and comment out the `COPY` instruction. This will cause the docker image to come up
  in install mode - so you can create a new configuration.
* In the dev/ folder, run `skaffold -p am-fbc dev`. This will bring up AM in FBC mode, and will also start amster to create an initial configuration.
* Let amster finish, and then run the `dump-config.sh` script:  `cd am-fbc; ./dump-config.sh`
* This script connects to the running AM instance and copies the file based configuration to the tmp/ directory on your local workstation.
* Shut down skaffold (control-c, or run `skaffold delete -p am-fbc` if it does not clean up)
* Important: Do NOT delete the ds-idrepo PVC. This has now been initialized with the structure that AM requires.

## Running with File Based Configuration

* Edit the `Dockerfile` again, and this time uncomment the `COPY` instruction. This will creates a docker image
  that is now pre-configured for running AM. 
* Deploy AM again:  `skaffold dev -p am-fbc`  
* Amster may run again - but it will see that AM is configured and will exit. 
* You can now log in to AM. If you update the configuration in the console, you can re-run the `./dump-config.sh` script to capture and save
 the updated files.

### Updating the deployment FQDN in FBC

Eventually this will be supported via commons expressions. For now, your choices are:

* Using your ide, search and replace the FQDN. The site is config/services/realm/root/iplanetamplatformservice/1.0/globalconfig/default/com-sun-identity-sites/site1/accesspoint.json


Use the script `./fix-fqdn.sh`

