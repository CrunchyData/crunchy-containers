---
title: "sqlrunner"
---

The `sqlrunner` running mode will use `psql` to issue specified queries, defined in SQL files, to your PostgreSQL database.

MODE: `sqlrunner`

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
`MODE` | None | Set to `sqlrunner` to run as SQL running job
`PG_HOST` | None | Hostname of the database the sql files will be run on.
`PG_PORT` | None | The port to use when connecting to the database.
`PG_DATABASE` | None | Name of the database the sql files will be run on.
`PG_USER` | None | Username for the PostgreSQL role being used.
`PG_PASSWORD` | None | Password for the PostgreSQL role being used.

## Custom Configuration

All queries from sql files in the `/pgconf` volume will be issued to the specified `PG_DATABASE`.