-- Topological sort of all non-system objects.
--
CREATE OR REPLACE VIEW pov.pg_depend_definitions AS
SELECT
    pov.pg_depend_tsort.row_number,
    pov.pg_depend_tsort.description,
    pov.pg_depend_tsort.classid,
    pov.pg_depend_tsort.objid,
    pov.pg_depend_tsort.objsubid,
    CASE

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_language' THEN
        'CREATE LANGUAGE ' || pov.pg_all_objects_unique_columns.language_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_namespace' THEN
        'CREATE SCHEMA ' || pov.pg_all_objects_unique_columns.namespace_name || ';' ||
        'ALTER SCHEMA ' || pov.pg_all_objects_unique_columns.namespace_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_namespace.nspowner FROM pg_catalog.pg_namespace WHERE pg_catalog.pg_namespace.oid = pov.pg_all_objects_unique_columns.objid))

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_class' AND pov.pg_all_objects_unique_columns.relation_kind = 'sequence' THEN
        'CREATE SEQUENCE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ';'
        'ALTER SEQUENCE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_class.relowner FROM pg_catalog.pg_class WHERE pg_catalog.pg_class.oid = pov.pg_all_objects_unique_columns.objid))

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_class' AND pov.pg_all_objects_unique_columns.relation_kind = 'view' AND pov.pg_depend_tsort.objsubid = 0 THEN
        'CREATE VIEW ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' AS ' || pg_catalog.pg_get_viewdef(pov.pg_all_objects_unique_columns.objid) ||
        'ALTER VIEW ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_class.relowner FROM pg_catalog.pg_class WHERE pg_catalog.pg_class.oid = pov.pg_all_objects_unique_columns.objid))

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_constraint' THEN
        'ALTER TABLE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' ADD CONSTRAINT ' || pov.pg_all_objects_unique_columns.constraint_name || ' ' || pg_catalog.pg_get_constraintdef(pov.pg_all_objects_unique_columns.objid)

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_attrdef' THEN
        'ALTER TABLE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' ALTER COLUMN ' || pov.pg_all_objects_unique_columns.attribute_name || ' ADD DEFAULT ' || (SELECT pg_catalog.pg_attrdef.adsrc FROM pg_catalog.pg_attrdef WHERE pg_catalog.pg_attrdef.oid = pov.pg_all_objects_unique_columns.objid)

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_trigger' THEN
        pg_get_triggerdef(pov.pg_all_objects_unique_columns.objid)

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_proc' THEN
        pg_catalog.pg_get_functiondef(pov.pg_all_objects_unique_columns.objid) || ';' ||
        'ALTER FUNCTION ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.function_name || '(' || pg_catalog.pg_get_function_identity_arguments(pov.pg_all_objects_unique_columns.objid) || ') OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_proc.proowner FROM pg_catalog.pg_proc WHERE pg_catalog.pg_proc.oid = pov.pg_all_objects_unique_columns.objid))

    END AS create_definition,

    CASE

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_language' THEN
        'DROP LANGUAGE ' || pov.pg_all_objects_unique_columns.language_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_namespace' THEN
        'DROP SCHEMA ' || pov.pg_all_objects_unique_columns.namespace_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_class' AND pov.pg_all_objects_unique_columns.relation_kind = 'sequence' THEN
        'DROP SEQUENCE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_constraint' THEN
        'ALTER TABLE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' DROP CONSTRAINT ' || pov.pg_all_objects_unique_columns.constraint_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_attrdef' THEN
        'ALTER TABLE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name || ' ALTER COLUMN ' || pov.pg_all_objects_unique_columns.attribute_name || ' DROP DEFAULT'

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_class' AND pov.pg_all_objects_unique_columns.relation_kind = 'view' AND pov.pg_depend_tsort.objsubid = 0 THEN
        'DROP VIEW ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_trigger' THEN
        'DROP TRIGGER ' || pov.pg_all_objects_unique_columns.trigger_name || ' ON TABLE ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.relation_name

        WHEN pov.pg_all_objects_unique_columns.class_name = 'pg_proc' THEN
        'DROP FUNCTION ' || pov.pg_all_objects_unique_columns.namespace_name || '.' || pov.pg_all_objects_unique_columns.function_name || '(' || pg_catalog.pg_get_function_identity_arguments(pov.pg_all_objects_unique_columns.objid) || ')'

    END AS drop_definition

FROM pov.pg_all_objects_unique_columns, pov.pg_depend_tsort
WHERE pov.pg_all_objects_unique_columns.objsubid = pov.pg_depend_tsort.objsubid
AND pov.pg_all_objects_unique_columns.classid    = pov.pg_depend_tsort.classid
AND pov.pg_all_objects_unique_columns.objid      = pov.pg_depend_tsort.objid
AND (
    pov.pg_all_objects_unique_columns.namespace_name IS NULL
    OR
    pov.pg_all_objects_unique_columns.namespace_name NOT IN ('pg_catalog','information_schema','pg_toast','pov')
)
AND (
    pov.pg_all_objects_unique_columns.function_name IS NULL
    OR
    pov.pg_all_objects_unique_columns.namespace_name IS NULL
    OR
    (pov.pg_all_objects_unique_columns.function_name <> 'pov' AND pov.pg_all_objects_unique_columns.namespace_name <> 'public')
)
ORDER BY pov.pg_depend_tsort.row_number
;
