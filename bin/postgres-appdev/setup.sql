/*
 * Copyright 2019 - 2020 Crunchy Data Solutions, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

-- noinspection SqlNoDataSourceInspectionForFile

SET application_name="appdev_container_setup";

create extension postgis;
create extension postgis_topology;
create extension postgis_tiger_geocoder cascade;
create extension pgrouting;
create extension ogr_fdw;
create extension pg_stat_statements;
create extension hstore;
create extension plr;

ALTER USER postgres PASSWORD 'PG_ROOT_PASSWORD';

CREATE USER "PG_USER" LOGIN;
ALTER USER "PG_USER" PASSWORD 'PG_PASSWORD';

CREATE DATABASE "PG_DATABASE";
GRANT ALL PRIVILEGES ON DATABASE "PG_DATABASE" TO "PG_USER";

\c "PG_DATABASE"

create extension postgis;
create extension postgis_topology;
create extension postgis_tiger_geocoder cascade;
create extension pgrouting;
create extension ogr_fdw;
create extension pg_stat_statements;
create extension hstore;
create extension plr;

\c "PG_DATABASE" "PG_USER";

create schema "PG_USER";
