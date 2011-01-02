-- This file constains random stuff I'm currently working with in the master branch

CREATE OR REPLACE VIEW View_View_Depends AS
SELECT
    pg_catalog.pg_depend.refobjid,
    pg_catalog.pg_rewrite.ev_class
FROM pg_catalog.pg_rewrite, pg_catalog.pg_depend
WHERE pg_catalog.pg_depend.objid = pg_catalog.pg_rewrite.oid
AND pg_catalog.pg_depend.refobjid <> pg_catalog.pg_rewrite.ev_class
AND pg_catalog.pg_depend.deptype = 'n'


CREATE OR REPLACE VIEW View_User_Views AS
SELECT
    pg_catalog.pg_class.relnamespace,
    pg_catalog.pg_class.oid,
    pg_catalog.pg_class.relname
FROM pg_catalog.pg_class
JOIN pg_catalog.pg_rewrite ON (pg_catalog.pg_rewrite.ev_class = pg_catalog.pg_class.oid)
JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_class.relnamespace)
WHERE pg_catalog.pg_class.relkind = 'v'
AND pg_catalog.pg_namespace.nspname NOT IN ('pg_catalog','information_schema')

CREATE OR REPLACE VIEW View_User_Top_Views AS
SELECT
    View_User_Views.relnamespace,
    View_User_Views.oid,
    View_User_Views.relname
FROM View_User_Views
WHERE NOT EXISTS (SELECT 1 FROM View_View_Depends WHERE View_View_Depends.ev_class = View_User_Views.oid)

CREATE OR REPLACE VIEW View_User_Leaf_Views AS
SELECT
    View_User_Views.relnamespace,
    View_User_Views.oid,
    View_User_Views.relname
FROM View_User_Views
WHERE NOT EXISTS (SELECT 1 FROM View_View_Depends WHERE View_View_Depends.refobjid = View_User_Views.oid)

