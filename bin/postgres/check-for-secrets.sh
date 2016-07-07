
if [ -d "/pguser" ]; then
	echo "pgpguser does exist"
	export PG_USER=$(cat /pguser/username)
	export PG_PASSWORD=$(cat /pguser/password)
fi
if [ -d "/pgroot" ]; then
	echo "pgroot does exist"
	export PG_ROOT_PASSWORD=$(cat /pgroot/password)
fi
if [ -d "/pgmaster" ]; then
	echo "pgmaster does exist"
	export PG_MASTER_USER=$(cat /pgmaster/username)
	export PG_MASTER_PASSWORD=$(cat /pgmaster/password)
fi
