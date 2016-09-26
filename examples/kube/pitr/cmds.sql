select pg_create_restore_point('beforechanges');
create table pitrtest (id int);
select pg_create_restore_point('afterchanges');
select pg_create_restore_point('nomorechanges');
checkpoint;
