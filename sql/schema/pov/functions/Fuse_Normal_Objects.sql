CREATE OR REPLACE FUNCTION Fuse_Normal_Objects(OUT NormalObject text, OUT Children text[]) RETURNS SETOF RECORD AS $BODY$
DECLARE
_Object text;
BEGIN
FOR _Object IN SELECT unnest FROM unnest((SELECT tsort(array_to_string(array_agg(
pg_describe_object(refclassid,refobjid,refobjsubid)
|| ';'
|| pg_describe_object(classid,objid,objsubid)
),';'),';',0,'DFS','ALL','SPLIT')
FROM (
    SELECT * FROM pg_depend WHERE deptype IN ('a','i')
) AS tsort))
LOOP
    IF _Object IS NULL THEN
        IF NormalObject IS NOT NULL AND Children IS NOT NULL THEN
            RETURN NEXT;
        END IF;
        NormalObject := NULL;
    ELSIF NormalObject IS NULL THEN
        NormalObject := _Object;
        Children := NULL;
    ELSE
        Children := array_append(Children,_Object);
    END IF;
END LOOP;
RETURN NEXT;
RETURN;
END;
$BODY$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION Fuse_Normal_Objects(OUT NormalObject text, OUT Children text[]) RETURNS SETOF RECORD AS $BODY$
DECLARE
_Object text;
BEGIN
FOR _Object IN SELECT unnest FROM unnest((SELECT tsort(array_to_string(array_agg(
refclassid || '.' || refobjid || '.' || refobjsubid
|| ';'
|| classid || '.' || objid || '.' || objsubid
),';'),';',0,'DFS','ALL','SPLIT')
FROM (
    SELECT * FROM pg_depend WHERE deptype IN ('a','i')
    AND NOT (refclassid = classid AND refobjid = objid)
) AS tsort))
LOOP
    IF _Object IS NULL THEN
        IF NormalObject IS NOT NULL AND Children IS NOT NULL THEN
            RETURN NEXT;
        END IF;
        NormalObject := NULL;
    ELSIF NormalObject IS NULL THEN
        NormalObject := _Object;
        Children := NULL;
    ELSE
        Children := array_append(Children,_Object);
    END IF;
END LOOP;
RETURN NEXT;
RETURN;
END;
$BODY$ LANGUAGE plpgsql STABLE;



CREATE OR REPLACE FUNCTION Fuse_Normal_Objects(OUT NormalObject text, OUT Children text[]) RETURNS SETOF RECORD AS $BODY$
DECLARE
_Object text;
BEGIN
FOR _Object IN SELECT unnest FROM unnest((SELECT tsort(array_to_string(array_agg(
refclassid || '.' || refobjid || '.' || refobjsubid
|| ';'
|| classid || '.' || objid || '.' || objsubid
),';'),';',0,'DFS','ALL','SPLIT')
FROM (
    SELECT * FROM pg_depend WHERE deptype IN ('a','i')
) AS tsort))
LOOP
    IF _Object IS NULL THEN
        IF NormalObject IS NOT NULL AND Children IS NOT NULL THEN
            RETURN NEXT;
        END IF;
        NormalObject := NULL;
    ELSIF NormalObject IS NULL THEN
        NormalObject := _Object;
        Children := NULL;
    ELSE
        Children := array_append(Children,_Object);
    END IF;
END LOOP;
RETURN;
END;
$BODY$ LANGUAGE plpgsql STABLE;



SELECT array_agg(
refclassid || '.' || refobjid || '.' || refobjsubid
|| ' '
|| classid || '.' || objid || '.' || objsubid
)
FROM (
    SELECT * FROM pg_depend WHERE deptype IN ('a','i')
) AS tsort)



FuseMap AS (
    SELECT NormalObject, Children FROM Fuse_Normal_Objects()
),
NormalObjects AS (
SELECT COALESCE(FuseMapRef.NormalObject,NewObjects.RefObj) AS RefObj, COALESCE(FuseMap.NormalObject,NewObjects.Obj) AS Obj FROM NewObjects
LEFT JOIN FuseMap               ON (NewObjects.Obj    = ANY(FuseMap.Children))
LEFT JOIN FuseMap AS FuseMapRef ON (NewObjects.RefObj = ANY(FuseMapRef.Children))
),


-- JOEL DOT
WITH
NewObjectOids AS (
    SELECT * FROM pg_depend WHERE deptype <> 'p'
    EXCEPT
    SELECT * FROM pg_depend_before
),
NewObjects AS (
SELECT
    pg_describe_object(refclassid,refobjid,refobjsubid) || ' ' || refclassid || '.' || refobjid || '.' || refobjsubid AS RefObj,
    pg_describe_object(classid,objid,objsubid)  || ' ' || classid || '.' || objid || '.' || objsubid AS Obj,
    DepType
FROM NewObjectOids
),
DepDigraph AS (
SELECT DISTINCT RefObj, Obj, DepType FROM NewObjects
WHERE RefObj <> Obj
),
DotFormat AS (
SELECT 'digraph pg_depend {' AS diagraph
UNION ALL
SELECT '    "'
    || RefObj
    || '" -> "'
    || Obj
    || '" [' || CASE
                WHEN array_to_string(array_agg(DepType),'') = 'n'         THEN 'color=black'
                WHEN array_to_string(array_agg(DepType),'') = 'i'         THEN 'color=red'
                WHEN array_to_string(array_agg(DepType),'') = 'a'         THEN 'color=blue'
                WHEN array_to_string(array_agg(DepType),'') ~ '^(ni|in)$' THEN 'color=green'
                WHEN array_to_string(array_agg(DepType),'') ~ '^(na|an)$' THEN 'color=yellow'
                ELSE 'style=dotted'
                END
    || ' label=' || array_to_string(array_agg(DepType),'') || ']'
FROM DepDigraph GROUP BY RefObj, Obj
UNION ALL
SELECT '}'
)
SELECT * FROM DotFormat;




WITH
TopoSort AS (
    SELECT tsort(array_to_string(array_agg(refclassid || '.' || refobjid || '.' || refobjsubid || ';' || classid || '.' || objid || '.' || objsubid),';'),';',0,'DFS','ALL','SPLIT') FROM pg_depend WHERE deptype <> 'p'
),
TextTopoSort AS (
SELECT pg_describe_object(split_part(unnest,'.',1)::oid, split_part(unnest,'.',2)::oid, split_part(unnest,'.',3)::integer) FROM unnest((SELECT tsort FROM TopoSort))
)
SELECT * FROM TextTopoSort;

'view pg_stat_all_tables column last_vacuum'


WITH
FuseMap AS (SELECT NormalObject, Children FROM Fuse_Normal_Objects()),
Objects AS (
SELECT
    refclassid || '.' || refobjid || '.' || refobjsubid AS RefObj,
    classid || '.' || objid || '.' || objsubid AS Obj
FROM pg_depend WHERE deptype <> 'p'
),
NormalObjects AS (
SELECT
    COALESCE(FuseMapRef.NormalObject,Objects.RefObj) AS RefObj,
    COALESCE(FuseMap.NormalObject,Objects.Obj) AS Obj
FROM Objects
LEFT JOIN FuseMap               ON (Objects.Obj    = ANY(FuseMap.Children))
LEFT JOIN FuseMap AS FuseMapRef ON (Objects.RefObj = ANY(FuseMapRef.Children))
),
DepDigraph AS (
SELECT DISTINCT RefObj, Obj FROM NormalObjects
WHERE RefObj <> Obj
),
TopoSort AS (
    SELECT tsort(array_to_string(array_agg(RefObj || ';' || Obj),';'),';',0,'DFS','SOURCE') FROM DepDigraph
),
TextTopoSort AS (
SELECT pg_describe_object(split_part(unnest,'.',1)::oid, split_part(unnest,'.',2)::oid, split_part(unnest,'.',3)::integer) FROM unnest((SELECT tsort FROM TopoSort))
)
SELECT * FROM NormalObjects;


-- JOEL
WITH
FuseMap AS (SELECT NormalObject, Children FROM Fuse_Normal_Objects()),
Objects AS (
SELECT
pg_describe_object(refclassid,refobjid,0) AS RefObj,
pg_describe_object(classid,objid,0) AS Obj
FROM (
    SELECT * FROM pg_depend WHERE deptype <> 'p'
    EXCEPT
    SELECT * FROM pg_depend_before
    ) AS innerQ
),
NormalObjects AS (
SELECT
    Objects.RefObj AS RefObjOrigin,
    Objects.Obj AS ObjOrigin,
    COALESCE(FuseMapRef.NormalObject,Objects.RefObj) AS RefObj,
    COALESCE(FuseMap.NormalObject,Objects.Obj) AS Obj
FROM Objects
LEFT JOIN FuseMap               ON (Objects.Obj    = ANY(FuseMap.Children))
LEFT JOIN FuseMap AS FuseMapRef ON (Objects.RefObj = ANY(FuseMapRef.Children))
),
DepDigraph AS (
SELECT DISTINCT RefObj, Obj FROM NormalObjects
WHERE RefObj <> Obj
),
TopoSort AS (
    SELECT tsort(array_to_string(array_agg(RefObj || ';' || Obj),';'),';',0,'DFS') FROM DepDigraph
)
SELECT * FROM TopoSort




select
refclassid,refobjid,refobjsubid,classid,objid,objsubid,deptype,
pg_describe_object(refclassid,refobjid,refobjsubid) AS RefObj,
pg_describe_object(classid,objid,objsubid) AS Obj
from pg_depend where deptype <> 'p'
and (pg_describe_object(refclassid,refobjid,refobjsubid) like '%pg_stat_user_tables%' or pg_describe_object(classid,objid,objsubid) like '%pg_stat_user_tables%')
;


select classid, objid from pg_depend where deptype = 'n'










WITH
FuseMap AS (SELECT NormalObject, Children FROM Fuse_Normal_Objects()),
Objects AS (
SELECT
    refclassid || '.' || refobjid || '.' || refobjsubid AS RefObj,
    classid || '.' || objid || '.' || objsubid AS Obj
FROM pg_depend WHERE deptype <> 'p'
),
NormalObjects AS (
SELECT
    COALESCE(FuseMapRef.NormalObject,Objects.RefObj) AS RefObj,
    COALESCE(FuseMap.NormalObject,Objects.Obj) AS Obj
FROM Objects
LEFT JOIN FuseMap               ON (Objects.Obj    = ANY(FuseMap.Children))
LEFT JOIN FuseMap AS FuseMapRef ON (Objects.RefObj = ANY(FuseMapRef.Children))
),
DepDigraph AS (
SELECT DISTINCT RefObj, Obj FROM NormalObjects
WHERE RefObj <> Obj
),
TopoSort AS (
    SELECT tsort(array_to_string(array_agg(RefObj || ' ' || Obj),' ')) FROM DepDigraph
)
SELECT * FROM FuseMap
LIMIT 1
;



























SELECT * FROM PublicNodes WHERE pg_describe_object(split_part(RefObj,'.',1)::oid, split_part(RefObj,'.',2)::oid, split_part(RefObj,'.',3)::integer) = 'NULL' OR pg_describe_object(split_part(Obj,'.',1)::oid, split_part(Obj,'.',2)::oid, split_part(Obj,'.',3)::integer) = 'NULL';













WITH
Objects AS (
SELECT
    refclassid || '.' || refobjid AS RefObj,
    classid || '.' || objid AS Obj,
    DepType
FROM pg_depend
WHERE ((refclassid = 1259 AND refobjid = 196124) OR (classid = 1259 AND objid = 196124))
),
DotFormat AS (
SELECT 'digraph pg_depend {' AS diagraph
UNION ALL
SELECT '    "'
    || RefObj
    || '" -> "'
    || Obj
    || '" [label=' || array_to_string(array_agg(DepType),'') || ']'
FROM Objects
GROUP BY RefObj, Obj
UNION ALL
SELECT '}'
)
SELECT * FROM DotFormat;






















