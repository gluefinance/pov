CREATE OR REPLACE VIEW pov.pg_depend_oid_concat AS
WITH
-- Get all objects not in a specific schema (such as language),
-- and all objects in a namespace other than the system namespaces
user_objects AS (
SELECT DISTINCT classid, objid FROM pov.pg_all_objects_unique_columns
WHERE namespace_name IS NULL OR namespace_name NOT IN ('pg_catalog','information_schema','pg_toast','pov')
),
-- Create an array with all such objects
user_objects_row AS (
SELECT array_agg(classid::text || '.' || objid::text) AS id FROM user_objects
),
-- Select from pg_depend_remapped,
-- and concat the deptypes,
-- for objects with more than one linkage.
pg_depend_deptype_agg AS (
    SELECT
        pg_depend_remapped.classid,
        pg_depend_remapped.objid,
        pg_depend_remapped.objsubid,
        pg_depend_remapped.refclassid,
        pg_depend_remapped.refobjid,
        pg_depend_remapped.refobjsubid,
        array_to_string(array_agg(pg_depend_remapped.deptype),'') AS deptype
    FROM pov.pg_depend_remapped, user_objects_row
    WHERE (pg_depend_remapped.classid::text || '.' || pg_depend_remapped.objid::text) = ANY(user_objects_row.id)
    GROUP BY pg_depend_remapped.classid,
    pg_depend_remapped.objid,
    pg_depend_remapped.objsubid,
    pg_depend_remapped.refclassid,
    pg_depend_remapped.refobjid,
    pg_depend_remapped.refobjsubid
)
SELECT
    refclassid || '.' || refobjid || '.' || refobjsubid AS refobj,
    classid    || '.' || objid || '.' || objsubid AS obj,
    deptype
FROM pg_depend_deptype_agg
;
