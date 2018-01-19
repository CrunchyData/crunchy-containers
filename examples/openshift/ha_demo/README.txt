Requires PVCs:
	crunchy-pvc
	crunchy-pvc2
	crunchy-backup-pvc
Requires secrets
Requires configmaps:
	oc create configmap pgmaster-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf --from-file=pgbackrest.conf --from-file=setup.sql
	oc create configmap pgslave-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf
