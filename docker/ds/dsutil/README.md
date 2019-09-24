# dsutil

Deploys the ds tools and some sample scripts. Utility scripts are placed in /opt/opendj/bin, and will be
in your path. Used for debugging, testing, etc. 

To run, cd to this folder and run:

`skaffold dev`

Then in another shell window:

`kubectl exec dsutil-xxxx -it bash `  where dsutil-xxx is the name of the pod.

The `exec.sh` script does the same thing as above.

The utilities included:

* ds-bench.sh - a small DS micro benchmark suite. `ds-bench.sh all`  for example (see the help).
