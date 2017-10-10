
if [ -d "/pguser" ]; then
	echo "pgpguser does exist"
	export PG_USER=$(cat /pguser/username)
	export PG_PASSWORD=$(cat /pguser/password)
fi
if [ -d "/pgroot" ]; then
	echo "pgroot does exist"
	export PG_ROOT_PASSWORD=$(cat /pgroot/password)
fi
if [ -d "/pgprimary" ]; then
	echo "pgprimary does exist"
	export PG_PRIMARY_USER=$(cat /pgprimary/username)
	export PG_PRIMARY_PASSWORD=$(cat /pgprimary/password)
fi
