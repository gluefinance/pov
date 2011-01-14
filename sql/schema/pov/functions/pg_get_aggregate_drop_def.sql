CREATE OR REPLACE FUNCTION pov.pg_get_aggregate_drop_def(oid) RETURNS TEXT AS $BODY$
SELECT 'DROP AGGREGATE ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_proc.proname || '(' || pg_catalog.pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || ')'
FROM pg_catalog.pg_proc
JOIN pg_catalog.pg_aggregate ON (pg_catalog.pg_aggregate.aggfnoid = pg_catalog.pg_proc.oid)
JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid      = pg_catalog.pg_proc.pronamespace)
WHERE pg_catalog.pg_proc.oid = $1;
$BODY$ LANGUAGE sql STABLE;
