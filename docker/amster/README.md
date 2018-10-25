# AM Amster Container

Runs the Amster CLI to configure AM. 

This container does not have any configuration files, and expects
the configuration to be mounted as a volume.

The AMSTER_SCRIPTS environment variable points to the script directory. Any files 
ending with *.amster will be executed by Amster. If  
a certain order is required, use sorted file names (01_install.amster, 02_myimport.amster).

See docker-entrypoint.sh for a detailed description of the environment variables.

The shell script `export.sh` is an example of using Amster to export configuration from AM. This script assumes 
that you have a persistent volume mounted for the exported files.

