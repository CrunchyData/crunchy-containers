# Crunchy PG Simulator

A simple traffic simulator for PostgreSQL.

## Overview

This simulator creates a single connection to PostgreSQL and will execute
queries over a specified interval range.

## Configuration


| Name         | File        | ENV               | Description                          |
| ------------ | ----------- | ----------------- | ------------------------------------ |
| Host         | host        | PGSIM_HOST        | The PostgreSQL host address          |
| Port         | port        | PGSIM_PORT        | The PostgreSQL host port             |
| Username     | username    | PGSIM_USERNAME    | The PostgreSQL username              |
| Password     | password    | PGSIM_PASSWORD    | The PostgreSQL password              |
| Database     | database    | PGSIM_DATABASE    | The database to connect              |
| Interval     | interval    | PGSIM_INTERVAL    | The units of the simulation interval |
| Min Interval | mininterval | PGSIM_MININTERVAL | The minimum interval value           |
| Max Interval | maxinterval | PGSIM_MAXINTERVAL | The maximum interval value           |\

Valid values for *Interval* are as follows:

* millisecond
* second
* minute

## Usage

```
$> crunchy-sim --config <path to config> <path to query file>
```

If the `--config` is omitted, then the above specified ENV variables must be set.

Environment variables will always take precendence over the values provided in
a configuration file.

## Query File


The query file is a simple YAML file that specifies a set of queries that will
be run at random by the simulator.  Each query is a name-value pair and can span
mulitiple lines by utilizing scalar notation ("|" or ">") as defined by the
YAML spec.

Example:

```
foo: select 1;
bar: select now();
baz: >
INSERT INTO FOO VALUES
(1, 2, 3),
(4, 5, 6);
```

