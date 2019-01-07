---
title: "Updating Documentation"
date: {docdate}
draft: false
weight: 251
---


## Documentation

The documentation website (located at https://crunchydata.github.io/crunchy-containers/) is generated using link:https://gohugo.io/[Hugo] and
link:https://pages.github.com/[GitHub Pages].

== Hosting Hugo Locally (Optional)

If you would like to build the documentation locally, view the
link:https://gohugo.io/getting-started/installing/[official Installing Hugo] guide to set up Hugo locally. 

You can then start the server by running the following commands -

```
cd $CCPROOT/hugo/
hugo server
```

The local version of the Hugo server is accessible by default from
`localhost:1313`. Once you've run `hugo server`, that will let you interactively make changes to the documentation as desired and view the updates
in real-time.

== Contributing to the Documentation

All documentation is in Markdown format and uses Hugo weights for positioning of the pages.

Currently, latest, development branch, documentation is updated as needed.  The Stable, latest production release, documentation is update on merge into the Master branch and tag created.

When you're ready to commit a change, please verify that the documentation generates locally.  
