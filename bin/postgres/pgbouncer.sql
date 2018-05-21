CREATE ROLE pgbouncer;
ALTER ROLE pgbouncer LOGIN PASSWORD 'PGBOUNCER_PASSWORD';

CREATE SCHEMA IF NOT EXISTS pgbouncer AUTHORIZATION pgbouncer;

CREATE OR REPLACE FUNCTION pgbouncer.get_auth(p_username TEXT)
RETURNS TABLE(username TEXT, password TEXT) AS
$$
BEGIN
    RAISE WARNING 'PgBouncer auth request: %', p_username;

    RETURN QUERY
    SELECT rolname::TEXT, rolpassword::TEXT
      FROM pg_authid
      WHERE NOT rolsuper
        AND rolname = p_username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION pgbouncer.get_auth(p_username TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION pgbouncer.get_auth(p_username TEXT) TO pgbouncer;
