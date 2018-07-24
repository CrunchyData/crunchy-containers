# Crunchy Watch

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The crunchy-watch container essentially does a health check on a primary database container and performs a failover sequence if the primary is not reached. The watch container has access to a service account that is used inside the container to issue commands to OpenShift.

**Note**: Crunchy Watch currently only works on Kubernetes and OpenShift.

## Container Specifications

See the [official documentation](https://crunchydata.github.io/crunchy-containers/container-specifications/crunchy-watch/) for more details regarding how the container operates and is customized.

## Examples

For examples regarding the use of the container, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
