# Platform Configurations

This is a work in progress, and is not complete. For the 7.0.0 release, this folder will contain one or more complete platform samples.


# Skaffold 

We use [skaffold](https://skaffold-latest.firebaseapp.com/) to provide an iterative development workflow, and also for final runtime deployment using continous delivery tools.

Each product folder has a skaffold.yaml file that can be used to iterate development on that  specific product. For example, if you
want to work on ForgeRock IG:

```bash
cd config/ig
skaffold dev
```

In addition, there is a top level skaffold.yaml that can be used to iterate on the entire platform:

```bash
cd config
skaffold dev
```

