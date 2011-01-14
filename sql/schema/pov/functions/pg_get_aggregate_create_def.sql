CREATE OR REPLACE FUNCTION pov.pg_get_aggregate_create_def(oid) RETURNS TEXT AS $BODY$
SELECT 'CREATE AGGREGATE ' || pg_catalog.pg_proc.proname || '(' || pg_catalog.pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || E') (\n' ||
'    SFUNC = ' || pg_catalog.pg_aggregate.aggtransfn::text || E',\n' ||
'    STYPE = ' || pg_catalog.pg_aggregate.aggtranstype::regtype::text ||
CASE WHEN pg_catalog.pg_aggregate.aggfinalfn::text = '-' THEN '' ELSE E',\n    FINALFUNC = ' || pg_catalog.pg_aggregate.aggfinalfn::text END ||
CASE WHEN pg_catalog.pg_aggregate.agginitval IS NULL     THEN '' ELSE E',\n    INITCOND = '  || pg_catalog.quote_literal(pg_catalog.pg_aggregate.agginitval) END ||
CASE WHEN pg_catalog.pg_operator.oprname IS NULL         THEN '' ELSE E',\n    SORTOP = '    || pg_catalog.quote_literal(pg_catalog.pg_operator.oprname) END ||
E'\n)'
FROM pg_catalog.pg_proc
JOIN pg_catalog.pg_aggregate     ON (pg_catalog.pg_aggregate.aggfnoid = pg_catalog.pg_proc.oid)
LEFT JOIN pg_catalog.pg_operator ON (pg_catalog.pg_operator.oid       = pg_catalog.pg_aggregate.aggsortop)
WHERE pg_catalog.pg_proc.oid = $1;
$BODY$ LANGUAGE sql STABLE;
