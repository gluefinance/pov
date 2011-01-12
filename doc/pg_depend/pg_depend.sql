-- Store already existing dependencies, so we can ignore them in the generated graph
INSERT INTO pg_depend_before ( classid, objid, objsubid, refclassid, refobjid, refobjsubid, deptype ) SELECT classid, objid, objsubid, refclassid, refobjid, refobjsubid, deptype FROM pg_depend;

-- Dependency level 1 (directly under public schema:)
CREATE TABLE t1 ( id integer, PRIMARY KEY (id) );
CREATE FUNCTION f1 ( integer ) RETURNS boolean AS $$ SELECT $1 > 1; $$ LANGUAGE sql;
CREATE SEQUENCE s1;

-- Dependency level 2:
CREATE TABLE t2 ( id integer, PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES t1(id) );
CREATE TABLE t3 ( id integer not null default nextval('s1'), PRIMARY KEY (id), CHECK(f1(id)) );

-- Dependency level 3:
CREATE VIEW v1 AS SELECT * FROM t1;
CREATE VIEW v2 AS SELECT * FROM t2;

-- Dependency level 4:
CREATE VIEW v3 AS SELECT v1.id AS id1, v2.id AS id2 FROM v1, v2;

-- Dependency level 5:
CREATE VIEW v4 AS SELECT *, f1(id1) FROM v3;

-- Circular dependencies:
CREATE TABLE tselfref  ( id int not null PRIMARY KEY, parentid int not null REFERENCES tselfref(id) );
CREATE TABLE tcircular ( id int not null PRIMARY KEY, id2      int not null REFERENCES tselfref(id) );
ALTER TABLE  tselfref ADD COLUMN id2 int not null REFERENCES tcircular ( id );


-- Generate .dot file, pg_depend.dot contains the output of the query
WITH
NewObjectOids AS (
    SELECT * FROM pg_depend WHERE deptype <> 'p'
    EXCEPT
    SELECT * FROM pg_depend_before
),
NewObjects AS (
SELECT
    pg_describe_object(refclassid,refobjid,0) || ' ' || refclassid || '.' || refobjid AS RefObj,
    pg_describe_object(classid,objid,0)       || ' ' || classid    || '.' || objid    AS Obj,
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

-- Swap normal-internal and automatic edges
WITH
NewObjectOids AS (
    SELECT * FROM pg_depend WHERE deptype <> 'p'
    EXCEPT
    SELECT * FROM pg_depend_before
),
NewObjectOidsAggDepType AS (
    SELECT classid,objid,objsubid,refclassid,refobjid,refobjsubid,array_to_string(array_agg(deptype),'') AS deptype
    FROM NewObjectOids GROUP BY classid,objid,objsubid,refclassid,refobjid,refobjsubid
),
NewObjects AS (
SELECT
    CASE WHEN DepType ~ '^(a|ni|in|an|na)$' THEN
        pg_describe_object(classid,objid,0)       || ' ' || classid    || '.' || objid
    ELSE
        pg_describe_object(refclassid,refobjid,0) || ' ' || refclassid || '.' || refobjid
    END AS RefObj,
    CASE WHEN DepType ~ '^(a|ni|in|an|na)$' THEN
        pg_describe_object(refclassid,refobjid,0) || ' ' || refclassid || '.' || refobjid
    ELSE
        pg_describe_object(classid,objid,0)       || ' ' || classid    || '.' || objid
    END AS Obj,
    DepType
FROM NewObjectOidsAggDepType
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
),
TopoSort AS (SELECT unnest FROM unnest((SELECT tsort(array_to_string(array_agg(RefObj || ';' || Obj),';'),';',2) FROM DepDigraph)))
SELECT * FROM TopoSort;

