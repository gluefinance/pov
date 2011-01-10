CREATE OR REPLACE FUNCTION Fuse_Normal_Objects(OUT NormalObject text, OUT Children text[]) RETURNS SETOF RECORD AS $BODY$
DECLARE
_Object text;
BEGIN

FOR _Object IN SELECT unnest FROM unnest((SELECT tsort(array_to_string(array_agg(
pg_describe_object(refclassid,refobjid,0)
|| ';'
|| pg_describe_object(classid,objid,0)
),';'),';',0,'DFS','ALL','SPLIT')
FROM (
    SELECT * FROM pg_depend WHERE deptype IN ('a','i')
) AS tsort))
LOOP
    IF _Object IS NULL THEN
        IF NormalObject IS NOT NULL THEN
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



WITH
FuseMap AS (
    SELECT NormalObject, Children FROM Fuse_Normal_Objects()
),
NewObjectOids AS (
    SELECT * FROM pg_depend
    EXCEPT
    SELECT * FROM pg_depend_before
),
NewObjects AS (
SELECT pg_describe_object(refclassid,refobjid,0) AS RefObj, pg_describe_object(classid,objid,0) AS Obj
FROM NewObjectOids
),
NormalObjects AS (
SELECT COALESCE(FuseMapRef.NormalObject,NewObjects.RefObj) AS RefObj, COALESCE(FuseMap.NormalObject,NewObjects.Obj) AS Obj FROM NewObjects
LEFT JOIN FuseMap               ON (NewObjects.Obj    = ANY(FuseMap.Children))
LEFT JOIN FuseMap AS FuseMapRef ON (NewObjects.RefObj = ANY(FuseMapRef.Children))
),
DepDigraph AS (
SELECT DISTINCT RefObj, Obj FROM NormalObjects
WHERE RefObj <> Obj
),
DotFormat AS (
SELECT 'digraph pg_depend {' AS diagraph
UNION ALL
SELECT '    "'
    || RefObj
    || '" -> "'
    || Obj
    || '"'
FROM DepDigraph
UNION ALL
SELECT '}'
),
TopoSort AS (
    SELECT tsort(array_to_string(array_agg(RefObj || ';' || Obj),';'),';',0,'sub {$a cmp $b}') FROM DepDigraph
)
SELECT * FROM TopoSort;




WITH
FuseMap AS (SELECT NormalObject, Children FROM Fuse_Normal_Objects()),
UserObjects AS (
SELECT
    refclassid, refobjid, classid, objid FROM pg_depend WHERE deptype <> 'p'
    AND (
        refclassid IN ('pg_class'::regclass,'pg_constraint'::regclass,'pg_trigger'::regclass,'pg_proc'::regclass)
        OR
        classid IN ('pg_class'::regclass,'pg_constraint'::regclass,'pg_trigger'::regclass,'pg_proc'::regclass)
    )
    AND (
    )
WHERE pg_catalog.pg_namespace.nspname NOT IN ('pg_catalog','information_schema','pov')


)
Objects AS (
SELECT
    pg_describe_object(refclassid,refobjid,0) AS RefObj,
    pg_describe_object(classid,objid,0) AS Obj
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
    SELECT tsort(array_to_string(array_agg(RefObj || ';' || Obj),';'),';',0,'DFS') FROM DepDigraph
)
SELECT * FROM TopoSort;








