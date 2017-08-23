
/* create these extensions if you want to do GIS work */
create extension postgis;
create extension postgis_topology;
create extension fuzzystrmatch;
create extension postgis_tiger_geocoder;

/* the following are required for other container operations */
alter user postgres password 'PG_ROOT_PASSWORD';

create user PG_MASTER_USER with REPLICATION  PASSWORD 'PG_MASTER_PASSWORD';
create user PG_USER with password 'PG_PASSWORD';

create table mastertable (key varchar(20), value varchar(20));
grant all on mastertable to PG_MASTER_USER;

create database PG_DATABASE;

grant all privileges on database PG_DATABASE to PG_USER;

\c PG_DATABASE

/* the following can be customized for your purposes */

\c PG_DATABASE PG_USER;

create table customtable (
	key varchar(30) primary key,
	value varchar(50) not null,
	updatedt timestamp not null
);

insert into customtable (key, value, updatedt) values ('CPU', '256', now());

grant all on customtable to PG_MASTER_USER;
