select datname, count(*) from pg_locks, pg_database where pg_locks.database = pg_database.oid group by pg_database.datname;
