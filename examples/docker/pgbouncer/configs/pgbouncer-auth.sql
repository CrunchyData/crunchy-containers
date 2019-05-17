--- pgBouncer Auth Query User Setup

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pgbouncer') THEN
        CREATE ROLE pgbouncer;
    END IF;
END
$$;

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
