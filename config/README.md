# Platform Configurations

This is a work in progress, and is not complete. For the 7.0.0 release, this folder will contain one or more platform samples.


# Skaffold 

[skaffold](https://skaffold-latest.firebaseapp.com/) is used to provide an iterative development workflow, and also for final runtime deployment using continous delivery tools.

There is a top level skaffold.yaml that can be used to iterate on the entire platform:

```bash
cd config
skaffold dev
```

