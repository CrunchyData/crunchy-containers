---
title: "Building the Containers"
date:
draft: false
weight: 250
---

# Build From Source

This section of the documentation assumes you have followed the [Installation Guide](/installation-guide/installation-guide). 
Because the build pulls down some kubernetes dependencies, you will need sudo'ers privileges to do a build. If you don't have 
the *atomic-openshift-clients* package installed on your machine you will see a warning message. This is expected and will not prevent 
the containers from working in a standalone Docker environment.

You should do the following in order to build the containers locally and be able to submit patches:

1. Fork the [Crunchy-Containers](https://github.com/CrunchyData/crunchy-containers) GitHub repository.
2. Containers builds are installed via a Makefile. You will need to run the following commands:

```
cd $CCPROOT
make setup
make all
```

if you want to build an individual container, such as Postgresql, you can do:

```
cd $CCPROOT
make setup
make postgres
```

You can find all the make targets in the Makefile.

After this, you will have all the Crunchy containers built and are ready
for use in a *standalone Docker* environment.
