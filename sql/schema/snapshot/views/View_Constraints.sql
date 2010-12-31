CREATE OR REPLACE VIEW snapshot.View_Constraints AS
SELECT
    pg_catalog.pg_constraint.oid,
    'ALTER TABLE ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_class.relname || ' ADD CONSTRAINT ' || pg_catalog.pg_constraint.conname || ' ' || pg_catalog.pg_get_constraintdef(pg_catalog.pg_constraint.oid) AS CreateObject,
    'ALTER TABLE ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_class.relname || ' DROP CONSTRAINT ' || pg_catalog.pg_constraint.conname AS DropObject
FROM snapshot.View_Functions
INNER JOIN pg_catalog.pg_depend     ON (pg_catalog.pg_depend.refobjid = snapshot.View_Functions.oid)
INNER JOIN pg_catalog.pg_constraint ON (pg_catalog.pg_constraint.oid  = pg_catalog.pg_depend.objid)
INNER JOIN pg_catalog.pg_class      ON (pg_catalog.pg_class.oid       = pg_catalog.pg_constraint.conrelid)
INNER JOIN pg_catalog.pg_namespace  ON (pg_catalog.pg_namespace.oid   = pg_catalog.pg_class.relnamespace)
;
