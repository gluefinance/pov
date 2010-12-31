CREATE OR REPLACE VIEW fsnapshot.View_Views AS
SELECT
    pg_catalog.pg_class.oid,
    'CREATE VIEW ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_class.relname || ' AS ' || pg_catalog.pg_get_viewdef(pg_catalog.pg_class.oid) || ';'
    || 'ALTER VIEW ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_class.relname || ' OWNER TO ' || pg_catalog.pg_get_userbyid(pg_catalog.pg_class.relowner) AS CreateObject,
    'DROP VIEW ' || pg_catalog.pg_namespace.nspname || '.' || pg_catalog.pg_class.relname AS DropObject
FROM fsnapshot.View_Functions
INNER JOIN pg_catalog.pg_depend     ON (pg_catalog.pg_depend.refobjid = fsnapshot.View_Functions.oid)
INNER JOIN pg_catalog.pg_rewrite    ON (pg_catalog.pg_rewrite.oid     = pg_catalog.pg_depend.objid)
INNER JOIN pg_catalog.pg_class      ON (pg_catalog.pg_class.oid       = pg_catalog.pg_rewrite.ev_class)
INNER JOIN pg_catalog.pg_namespace  ON (pg_catalog.pg_namespace.oid   = pg_catalog.pg_class.relnamespace)
WHERE pg_catalog.pg_class.relkind = 'v'
;
