-- Store already existing dependencies, so we can ignore them in the generated graph
INSERT INTO pg_depend_before ( classid, objid, objsubid, refclassid, refobjid, refobjsubid, deptype ) SELECT classid, objid, objsubid, refclassid, refobjid, refobjsubid, deptype FROM pg_depend;

CREATE TABLE t1 ( id integer, PRIMARY KEY (id) );
CREATE TABLE t2 ( id integer, PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES t1(id) );
CREATE VIEW v1 AS SELECT * FROM t1;
CREATE VIEW v2 AS SELECT * FROM t2;
CREATE VIEW v3 AS SELECT v1.id AS id1, v2.id AS id2 FROM v1, v2;
CREATE FUNCTION f1 ( integer ) RETURNS boolean AS $$ SELECT $1 > 1; $$ LANGUAGE sql;
CREATE VIEW v4 AS SELECT *, f1(id1) FROM v3;
CREATE SEQUENCE s1;
CREATE TABLE t3 ( id integer not null default nextval('s1'), PRIMARY KEY (id), CHECK(f1(id)) );

-- glue=# CREATE TABLE t1 ( id integer, PRIMARY KEY (id) );
-- NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index "t1_pkey" for table "t1"
-- CREATE TABLE
-- glue=# CREATE TABLE t2 ( id integer, PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES t1(id) );
-- NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index "t2_pkey" for table "t2"
-- CREATE TABLE
-- glue=# CREATE VIEW v1 AS SELECT * FROM t1;
-- CREATE VIEW
-- glue=# CREATE VIEW v2 AS SELECT * FROM t2;
-- CREATE VIEW
-- glue=# CREATE VIEW v3 AS SELECT v1.id AS id1, v2.id AS id2 FROM v1, v2;
-- CREATE VIEW
-- glue=# CREATE FUNCTION f1 ( integer ) RETURNS boolean AS $$ SELECT $1 > 1; $$ LANGUAGE sql;
-- CREATE FUNCTION
-- glue=# CREATE VIEW v4 AS SELECT *, f1(id1) FROM v3;
-- CREATE VIEW
-- glue=# CREATE SEQUENCE s1;
-- CREATE SEQUENCE
-- glue=# CREATE TABLE t3 ( id integer not null default nextval('s1'), PRIMARY KEY (id), CHECK(f1(id)) );
-- NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index "t3_pkey" for table "t3"
-- CREATE TABLE
-- glue=# 

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

