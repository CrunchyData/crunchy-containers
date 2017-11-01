select round((select sum(numbackends) from pg_stat_database)/boot_val::numeric,2) as utilpct, boot_val::numeric , (select sum(numbackends) from pg_stat_database) as used_val from pg_settings where name = 'max_connections';

