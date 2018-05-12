# Crunchy Postgres Primary

The Crunchy PostgreSQL Primary Template creates a single primary pod.

## Objects

The Crunchy PostreSQL Primary Template creates the following objects:

* PostgreSQL Secret - usernames and passwords generated from the template
* PGData PVC - Volume where PostgreSQL database will be stored
* Primary Service - Service connected to the Primary Pod
* Primary Pod - Primary database pod

## Storage

This template assumes `STORAGE_CLASS` volumes will be used.  

## Form Required 
**Name**|**Description**
:-----|:-----
**VOLUME_STORAGE_CLASS**|Name of the Storage Class that provides persistence for the container.
