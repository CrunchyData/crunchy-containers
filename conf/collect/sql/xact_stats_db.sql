SELECT current_database(), datname, now(), 
	xact_commit as commits, xact_rollback as rollbacks 
	FROM pg_stat_database WHERE datname = current_database()
