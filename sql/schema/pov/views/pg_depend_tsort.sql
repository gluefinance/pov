WITH
user_objects AS (
SELECT DISTINCT classid, objid FROM view_objects
WHERE view_objects.namespace_name IS NULL OR view_objects.namespace_name NOT IN ('pg_catalog','information_schema','pg_toast')
),
user_objects_row AS (
SELECT array_agg(classid::text || '.' || objid::text) AS id FROM user_objects
),
pg_depend_deptype_agg AS (
    SELECT
        pg_depend_remapped.classid,
        pg_depend_remapped.objid,
        pg_depend_remapped.objsubid,
        pg_depend_remapped.refclassid,
        pg_depend_remapped.refobjid,
        pg_depend_remapped.refobjsubid,
        array_to_string(array_agg(pg_depend_remapped.deptype),'') AS deptype
    FROM pg_depend_remapped, user_objects_row
    WHERE (pg_depend_remapped.classid::text || '.' || pg_depend_remapped.objid::text) = ANY(user_objects_row.id)
    GROUP BY pg_depend_remapped.classid,
    pg_depend_remapped.objid,
    pg_depend_remapped.objsubid,
    pg_depend_remapped.refclassid,
    pg_depend_remapped.refobjid,
    pg_depend_remapped.refobjsubid
),
pg_depend_oid_concat AS (
SELECT
    refclassid || '.' || refobjid || '.' || refobjsubid AS refobj,
    classid    || '.' || objid || '.' || objsubid AS obj,
    deptype
FROM pg_depend_deptype_agg
),
digraph_in_dot_format AS (
SELECT 'digraph pg_depend {' AS diagraph
UNION ALL
SELECT '    "'
    || pg_describe_object(refobj)
    || '" -> "'
    || pg_describe_object(obj)
    || '" [' || CASE
                WHEN array_to_string(array_agg(deptype),'') ~ '^n+$'           THEN 'color=black'
                WHEN array_to_string(array_agg(deptype),'') ~ '^i+$'           THEN 'color=red'
                WHEN array_to_string(array_agg(deptype),'') ~ '^a+$'           THEN 'color=blue'
                WHEN array_to_string(array_agg(deptype),'') ~ '^(ni|in)[ni]*$' THEN 'color=green'
                WHEN array_to_string(array_agg(deptype),'') ~ '^(na|an)[na]*$' THEN 'color=yellow'
                ELSE 'style=dotted'
                END
    || ' label=' || array_to_string(array_agg(deptype),'') || ']'
FROM pg_depend_oid_concat GROUP BY refobj, obj
UNION ALL
SELECT '}'
),
tsort_input AS (
SELECT refobj || ' ' || obj FROM pg_depend_oid_concat
),
pg_depend_toposort AS (
SELECT split_part(unnest,'.',1)::oid AS classid, split_part(unnest,'.',2)::oid AS objid, split_part(unnest,'.',3)::integer AS objsubid FROM unnest((SELECT tsort(array_to_string(array_agg(refobj || ' ' || obj),' ')) FROM pg_depend_oid_concat))
),
pg_depend_toposort_text AS (
SELECT
row_number() OVER (),
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\1') AS description,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\2')::oid AS classid,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\3')::oid AS objid,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\4')::integer AS objsubid
FROM unnest((SELECT tsort(array_to_string(array_agg(pg_describe_object(refobj) || ';;;separator;;;' || pg_describe_object(obj)),';;;separator;;;'),';;;separator;;;',0,'sub {$a cmp $b}') FROM pg_depend_oid_concat))
),
sorted_objects AS (
SELECT
    pg_depend_toposort_text.row_number,
    pg_depend_toposort_text.description,
    pg_depend_toposort_text.classid,
    pg_depend_toposort_text.objid,
    pg_depend_toposort_text.objsubid,
    substr(CASE
    WHEN view_objects.class_name = 'pg_language' THEN
    'CREATE LANGUAGE ' || view_objects.language_name
    WHEN view_objects.class_name = 'pg_namespace' THEN
    'CREATE SCHEMA ' || view_objects.namespace_name || ';' ||
    'ALTER SCHEMA ' || view_objects.namespace_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_namespace.nspowner FROM pg_catalog.pg_namespace WHERE pg_catalog.pg_namespace.oid = view_objects.objid))
    WHEN view_objects.class_name = 'pg_class' AND view_objects.relation_kind = 'sequence' THEN
    'CREATE SEQUENCE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ';'
    'ALTER SEQUENCE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_class.relowner FROM pg_catalog.pg_class WHERE pg_catalog.pg_class.oid = view_objects.objid))
    WHEN view_objects.class_name = 'pg_constraint' THEN
    'ALTER TABLE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' ADD CONSTRAINT ' || view_objects.constraint_name || ' ' || pg_catalog.pg_get_constraintdef(view_objects.objid)
    WHEN view_objects.class_name = 'pg_attrdef' THEN
    'ALTER TABLE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' ALTER COLUMN ' || view_objects.attribute_name || ' ADD DEFAULT ' || (SELECT pg_catalog.pg_attrdef.adsrc FROM pg_catalog.pg_attrdef WHERE pg_catalog.pg_attrdef.oid = view_objects.objid)
    WHEN view_objects.class_name = 'pg_class' AND view_objects.relation_kind = 'view' AND pg_depend_toposort_text.objsubid = 0 THEN
    'CREATE VIEW ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' AS ' || pg_catalog.pg_get_viewdef(view_objects.objid) ||
    'ALTER VIEW ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_class.relowner FROM pg_catalog.pg_class WHERE pg_catalog.pg_class.oid = view_objects.objid))
    WHEN view_objects.class_name = 'pg_trigger' THEN
    pg_get_triggerdef(view_objects.objid)
    WHEN view_objects.class_name = 'pg_proc' THEN
    pg_catalog.pg_get_functiondef(view_objects.objid) || ';' ||
    'ALTER FUNCTION ' || view_objects.namespace_name || '.' || view_objects.function_name || '(' || pg_catalog.pg_get_function_identity_arguments(view_objects.objid) || ') OWNER TO ' || pg_catalog.pg_get_userbyid((SELECT pg_catalog.pg_proc.proowner FROM pg_catalog.pg_proc WHERE pg_catalog.pg_proc.oid = view_objects.objid))
    ELSE 'RAISE EXCEPTION ''Sorry, ' || view_objects.class_name || ' is not supported yet'''
    END,0,100) AS create_definition,

    substr(CASE
    WHEN view_objects.class_name = 'pg_language' THEN
    'DROP LANGUAGE ' || view_objects.language_name
    WHEN view_objects.class_name = 'pg_namespace' THEN
    'DROP SCHEMA ' || view_objects.namespace_name
    WHEN view_objects.class_name = 'pg_class' AND view_objects.relation_kind = 'sequence' THEN
    'DROP SEQUENCE ' || view_objects.namespace_name || '.' || view_objects.relation_name
    WHEN view_objects.class_name = 'pg_constraint' THEN
    'ALTER TABLE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' DROP CONSTRAINT ' || view_objects.constraint_name
    WHEN view_objects.class_name = 'pg_attrdef' THEN
    'ALTER TABLE ' || view_objects.namespace_name || '.' || view_objects.relation_name || ' ALTER COLUMN ' || view_objects.attribute_name || ' DROP DEFAULT'
    WHEN view_objects.class_name = 'pg_class' AND view_objects.relation_kind = 'view' AND pg_depend_toposort_text.objsubid = 0 THEN
    'DROP VIEW ' || view_objects.namespace_name || '.' || view_objects.relation_name
    WHEN view_objects.class_name = 'pg_trigger' THEN
    'DROP TRIGGER ' || view_objects.trigger_name || ' ON TABLE ' || view_objects.namespace_name || '.' || view_objects.relation_name
    WHEN view_objects.class_name = 'pg_proc' THEN
    'DROP FUNCTION ' || view_objects.namespace_name || '.' || view_objects.function_name || '(' || pg_catalog.pg_get_function_identity_arguments(view_objects.objid) || ')'
    ELSE 'RAISE EXCEPTION ''Sorry, ' || view_objects.class_name || ' is not supported yet'''
    END,0,100) AS drop_definition


FROM view_objects, pg_depend_toposort_text
WHERE view_objects.objsubid = pg_depend_toposort_text.objsubid
AND view_objects.classid    = pg_depend_toposort_text.classid
AND view_objects.objid      = pg_depend_toposort_text.objid
AND (view_objects.namespace_name IS NULL OR view_objects.namespace_name NOT IN ('pg_catalog','information_schema','pg_toast'))
ORDER BY pg_depend_toposort_text.row_number
)
SELECT * FROM sorted_objects WHERE create_definition IS NOT NULL;








