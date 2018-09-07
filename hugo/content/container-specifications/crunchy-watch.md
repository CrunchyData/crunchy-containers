---
title: "crunchy-watch"
date: 2018-05-24T12:06:15-07:00
draft: false
---

Crunchy Watch is an application wrapped in a container that watches a PostgreSQL
primary database and waits for a failure to occur, at which point a failover is
performed to promote a replica.

The crunchy-watch container, while originally part of the Container Suite, has been
split out into its own project. More information on the Watch container and it's
capabilities can be found in the new project repository located at
https://github.com/CrunchyData/crunchy-watch.
