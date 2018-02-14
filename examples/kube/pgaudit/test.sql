set pgaudit.log = 'write, ddl, user';
set pgaudit.log_relation = on;

create table audittest (id int);
insert into audittest values (1);
drop table audittest;
