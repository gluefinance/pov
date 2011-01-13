WITH RECURSIVE
edges AS (
SELECT DISTINCT
    refclassid || '.' || refobjid || '.' || refobjsubid AS from_obj,
    classid || '.' || objid || '.' || objsubid AS to_obj,
    deptype
FROM pg_depend
),
normal_objects_with_internal_objects AS (
-- have internal edge pointing from object
SELECT from_obj AS obj FROM edges WHERE deptype = 'i'
EXCEPT
-- doesn't have internal edge pointing to object
SELECT to_obj FROM edges WHERE deptype = 'i'
),
find_internal_recursively AS (
SELECT
    normal_objects_with_internal_objects.obj AS normal_obj,
    normal_objects_with_internal_objects.obj AS internal_obj
FROM normal_objects_with_internal_objects
UNION ALL
SELECT
    find_internal_recursively.normal_obj,
    edges.to_obj
FROM find_internal_recursively
JOIN edges ON (edges.deptype = 'i' AND edges.from_obj = find_internal_recursively.internal_obj)
),
map_internal_to_normal AS (
SELECT
    normal_obj,
    array_agg(internal_obj) AS internal_objs
FROM find_internal_recursively
WHERE normal_obj <> internal_obj
GROUP BY normal_obj
)
SELECT * FROM map_internal_to_normal
