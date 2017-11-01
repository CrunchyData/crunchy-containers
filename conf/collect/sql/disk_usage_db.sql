SELECT datname, pg_database_size(datname)/1024/1024 as mbytes FROM pg_database 
           WHERE datname = current_database()
