# Crunchy Vacuum

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The crunchy-vacuum container allows you to perform a SQL VACUUM job against a PostgreSQL database container. It is possible to run different vacuum operations either manually or automatically through scheduling. The crunchy-vacuum image is executed, with the Postgres connection parameters passed to the single-primary PostgreSQL container. The type of vacuum performed is dictated by the environment variables passed into the job.

More information on the PostgreSQL VACUUM job can be found in the [official PostgreSQL documentation](https://www.postgresql.org/docs/current/static/sql-vacuum.html).

## Container Specifications

See the [official documentation](https://crunchydata.github.io/crunchy-containers/container-specifications/crunchy-vacuum/) for more details regarding how the container operates and is customized.

## Examples

For examples regarding the use of the container, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
