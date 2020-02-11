/*
 * Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
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
 
/* the following are required for other container operations */
alter user postgres password 'PG_ROOT_PASSWORD';

create user PG_PRIMARY_USER with REPLICATION  PASSWORD 'PG_PRIMARY_PASSWORD';
create user PG_USER with password 'PG_PASSWORD';

create table primarytable (key varchar(20), value varchar(20));
grant all on primarytable to PG_PRIMARY_USER;

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

grant all on customtable to PG_PRIMARY_USER;
