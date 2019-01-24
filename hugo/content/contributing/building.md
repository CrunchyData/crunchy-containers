---
title: "Building the Containers"
date:
draft: false
weight: 250
---

# Build From Source

This section of the documentation assumes you have followed the [Installation Guide](/installation-guide/installation-guide).
You should do the following in order to build the containers locally and be able to submit patches:

1. Fork the [Crunchy-Containers](https://github.com/CrunchyData/crunchy-containers) GitHub repository.
2. Containers builds are installed via a Makefile. You will need to run the following commands:

```
cd $CCPROOT
make setup
make all
```
After this, you will have all the Crunchy containers built and are ready
for use in a *standalone Docker* environment.
