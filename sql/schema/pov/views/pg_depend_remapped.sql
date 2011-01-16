-- Author: Joel Jacobson, Glue Finance AB, Sweden, <joel@gluefinance.com>
-- Datestamp: 2011-01-13 23:42 Europe/Stockholm
-- License: MIT (http://www.opensource.org/licenses/mit-license.php)
--
-- This view folds the internal linkages in pg_depend and replaces them
-- with a links to the objects they belong to.
--
-- This is necessary to be able to topologically sort all the objects,
-- which is done using the tsort() function also provided in the pov project.
-- The toposort gives the "creatable order" of all objects.
--
-- Meaning of the arrows:
-- this object must be created ---before---> this other object can be created
--
-- Original pg_depend:
-- (view myview) --i--> (rule _RETURN on view myview) <--n-- (table mytable)
-- 
-- We remove the internal object (the rule _RETURN on view myview) and get the following instead:
-- (view myview) <--n-- (table mytable)
--
-- Now the meaning of the digraph is "(table mytable) must be created before (view myview) can be created",
-- which is exactly what we wanted.
--
-- Since there can be a chain of internal objects, we need a recursive query to find the "source object"
-- Example:
-- (table mytable) --i--> (type mytable) --i--> (type mytable[])
--
-- If an object would depend on (type mytable[]), it actually depends on (table mytable),
-- which is why all arrows (edges) pointing to (type mytable[]) should instead point to (table mytable)
-- 
-- And yes, the query below can probably be optimized quite a lot.
--
CREATE OR REPLACE VIEW pov.pg_depend_remapped AS
WITH RECURSIVE
edges AS (
SELECT
    ARRAY[refclassid::int, refobjid::int, refobjsubid] AS from_obj,
    ARRAY[classid::int, objid::int, objsubid] AS to_obj,
    deptype
FROM pg_catalog.pg_depend
UNION
-- Add dependencies from "main object" (objsubid=0) to sub object (objsubid>0):
SELECT
    ARRAY[refclassid::int, refobjid::int, 0] AS from_obj,
    ARRAY[refclassid::int, refobjid::int, refobjsubid] AS to_obj,
    deptype
FROM pg_catalog.pg_depend WHERE refobjsubid > 0
UNION
SELECT
    ARRAY[classid::int, objid::int, 0] AS from_obj,
    ARRAY[classid::int, objid::int, objsubid] AS to_obj,
    deptype
FROM pg_catalog.pg_depend WHERE objsubid > 0
),
objects_with_internal_objects AS (
-- have internal edge pointing from object
SELECT from_obj AS obj FROM edges WHERE deptype = 'i'
EXCEPT
-- doesn't have internal edge pointing to object
SELECT to_obj FROM edges WHERE deptype = 'i'
),
objects_without_internal_objects AS (
SELECT from_obj AS obj FROM edges WHERE deptype IN ('n','a')
UNION
SELECT to_obj AS obj FROM edges WHERE deptype IN ('n','a')
EXCEPT
SELECT obj FROM objects_with_internal_objects
),
find_internal_recursively AS (
SELECT
    objects_with_internal_objects.obj AS normal_obj,
    objects_with_internal_objects.obj AS internal_obj
FROM objects_with_internal_objects
UNION ALL
SELECT
    find_internal_recursively.normal_obj,
    edges.to_obj
FROM find_internal_recursively
JOIN edges ON (edges.deptype = 'i' AND edges.from_obj = find_internal_recursively.internal_obj)
),
remap_edges AS (
SELECT
COALESCE(remap_from.normal_obj,edges.from_obj) AS from_obj,
COALESCE(remap_to.normal_obj,edges.to_obj) AS to_obj,
edges.deptype
FROM edges
LEFT JOIN find_internal_recursively AS remap_from ON (edges.from_obj = remap_from.internal_obj)
LEFT JOIN find_internal_recursively AS remap_to   ON (edges.to_obj   = remap_to.internal_obj)
WHERE edges.deptype IN ('n','a')
),
unconcat AS (
SELECT
    from_obj[1]::oid AS refclassid,
    from_obj[2]::oid AS refobjid,
    from_obj[3]::integer AS refobjsubid,
    to_obj[1]::oid AS classid,
    to_obj[2]::oid AS objid,
    to_obj[3]::integer AS objsubid,
    deptype
FROM remap_edges
)
SELECT * FROM unconcat WHERE NOT (refclassid = classid AND refobjid = objid AND refobjsubid = objsubid)
;
