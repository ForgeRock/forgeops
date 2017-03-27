# OpenAM Amster Container

Runs the Amster CLI to configure OpenAM.

This container does not have any configuration files, and expects
the configuration to be mounted as a volume.

The AMSTER_CONFIG environment variable is the path to 
the Amster script files. This defaults to /amster

By default, any files ending with *.amster will be executed by Amster. If  
a certain order is required, use sorted file names (01_install.amster, 02_myimport.amster).

The shell script `export.sh` is an example of using Amster to export configuration from OpenAM. This script assumes 
that you have a persistent volume mounted for the exported files.
