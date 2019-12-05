# overides for containerized compatibility of pgAdmin4

# pgAdmin4 should be accessible publicly
DEFAULT_SERVER = '0.0.0.0'

# this is the default pgAdmin4 port, but this is left here for someone who wants
# to override the default port
DEFAULT_SERVER_PORT = 5050

# this is the path to the local pgadmin4 database; this is part of the persisted
# volume
SQLITE_PATH = '/var/lib/pgadmin/pgadmin4.db'

# this is the path to the local pgadmin4 sessions database; this is part of the
# persisted volume
SESSION_DB_PATH = '/var/lib/pgadmin/sessions'

# this is the path to the local pgadmin4 storage; this is part of the persisted
# volume
STORAGE_DIR = '/var/lib/pgadmin/storage'

# this allows for the default PostgreSQL binary path to be overwritten with the
# directory that is in the container
DEFAULT_BINARY_PATHS = {
    "pg":   "",
}
