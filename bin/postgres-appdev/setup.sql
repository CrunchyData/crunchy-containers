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

create table "PG_USER".testtable (
	name varchar(30) primary key,
	value varchar(50) not null,
	updatedt timestamp not null
);

insert into "PG_USER".testtable (name, value, updatedt) values ('CPU', '256', now());
insert into "PG_USER".testtable (name, value, updatedt) values ('MEM', '512m', now());
