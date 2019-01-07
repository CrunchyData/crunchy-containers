---
title: "Building the Containers"
date: {docdate}
draft: false
weight: 250
---

# Build From Source

Assuming you have followed the [Installation Guide](/installation-guide/installation-guide)
You should do the following in order to build the containers locally and be able to submit patches.

1. fork the [Crunchy-Containers](https://github.com/CrunchyData/crunchy-containers) github repository.
2. Containers builds are via a makefile, you will need to run the following commands:

```
cd $CCPROOT
make setup
make all
```
After this, you will have all the Crunchy containers built and are ready
for use in a *standalone Docker* environment.