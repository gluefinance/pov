CREATE OR REPLACE VIEW snapshot.View_Functions AS
SELECT
    pg_catalog.pg_proc.oid,
    pg_catalog.pg_get_functiondef(pg_catalog.pg_proc.oid) || ';' || 'ALTER FUNCTION ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_proc.proname || '(' || pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || ') OWNER TO ' || pg_catalog.pg_get_userbyid(pg_catalog.pg_proc.proowner) AS CreateObject,
    'DROP FUNCTION ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_proc.proname || '(' || pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || ')' AS DropObject
FROM pg_catalog.pg_proc
INNER JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_proc.pronamespace)
-- Do not include pg_catalog, information_schema, or our own schema "snapshot"
WHERE pg_catalog.pg_namespace.nspname NOT IN ('pg_catalog','information_schema','snapshot')
-- Skip aggregates as they cannot be defined using pg_get_functiondef
AND pg_catalog.pg_proc.proisagg IS FALSE
-- Do not include the snapshot API-functions in the selection
AND (pg_catalog.pg_namespace.nspname <> 'public' OR pg_catalog.pg_proc.proname <> 'snapshot')
;
