-- This file constains random stuff I'm currently working with in the master branch

CREATE OR REPLACE VIEW View_View_Depends AS
SELECT
    pg_catalog.pg_depend.refobjid,
    pg_catalog.pg_rewrite.ev_class
FROM pg_catalog.pg_rewrite, pg_catalog.pg_depend
WHERE pg_catalog.pg_depend.objid     = pg_catalog.pg_rewrite.oid
AND pg_catalog.pg_depend.refobjid   <> pg_catalog.pg_rewrite.ev_class
AND pg_catalog.pg_depend.deptype     = 'n'
AND pg_catalog.pg_depend.objsubid    = 0
AND pg_catalog.pg_depend.refobjsubid = 1
;

CREATE OR REPLACE VIEW View_User_Views AS
SELECT
    pg_catalog.pg_class.oid,
    pg_catalog.pg_namespace.nspname,
    pg_catalog.pg_class.relname
FROM pg_catalog.pg_class
JOIN pg_catalog.pg_rewrite ON (pg_catalog.pg_rewrite.ev_class = pg_catalog.pg_class.oid)
JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_class.relnamespace)
WHERE pg_catalog.pg_class.relkind = 'v'
AND pg_catalog.pg_namespace.nspname NOT IN ('pg_catalog','information_schema')
;

CREATE OR REPLACE VIEW View_User_Top_Views AS
SELECT * FROM View_User_Views
WHERE NOT EXISTS (SELECT 1 FROM View_View_Depends WHERE View_View_Depends.ev_class = View_User_Views.oid)
ORDER BY nspname,relname
;

CREATE OR REPLACE VIEW View_User_Leaf_Views AS
SELECT * FROM View_User_Views
WHERE NOT EXISTS (SELECT 1 FROM View_View_Depends WHERE View_View_Depends.refobjid = View_User_Views.oid)
ORDER BY nspname,relname
;

CREATE OR REPLACE VIEW View_User_Views_Create_Order AS
WITH RECURSIVE View_User_Top_Views_Tree AS (
SELECT
    View_User_Top_Views.*,
    View_User_Top_Views.nspname || '.' || View_User_Top_Views.relname AS Edges,
    ARRAY[View_User_Top_Views.oid] AS Chain,
    0 AS Level
FROM View_User_Top_Views
UNION ALL
SELECT
    View_User_Views.*,
    View_User_Top_Views_Tree.Edges || ' -> ' || View_User_Views.nspname || '.' || View_User_Views.relname,
    View_User_Top_Views_Tree.Chain || View_User_Views.oid,
    View_User_Top_Views_Tree.Level+1
FROM View_User_Top_Views_Tree
JOIN View_View_Depends ON (View_View_Depends.refobjid = View_User_Top_Views_Tree.oid)
JOIN View_User_Views   ON (View_User_Views.oid        = View_View_Depends.ev_class)
), View_User_Top_Views_RowNums AS (
    SELECT row_number() OVER (ORDER BY Level,Edges), * FROM View_User_Top_Views_Tree
)
SELECT * FROM View_User_Top_Views_RowNums
ORDER BY row_number
;

-- glue=# SELECT * FROM View_User_Views_Create_Order;
--  row_number |  oid  | nspname |           relname            |                                            edges                                             |        chain        | level 
-- ------------+-------+---------+------------------------------+----------------------------------------------------------------------------------------------+---------------------+-------
--           1 | 52039 | public  | view_user_views              | public.view_user_views                                                                       | {52039}             |     0
--           2 | 52035 | public  | view_view_depends            | public.view_view_depends                                                                     | {52035}             |     0
--           3 | 52048 | public  | view_user_leaf_views         | public.view_user_views -> public.view_user_leaf_views                                        | {52039,52048}       |     1
--           4 | 52044 | public  | view_user_top_views          | public.view_user_views -> public.view_user_top_views                                         | {52039,52044}       |     1
--           5 | 52052 | public  | view_user_views_create_order | public.view_user_views -> public.view_user_views_create_order                                | {52039,52052}       |     1
--           6 | 52057 | public  | view_user_views_drop_order   | public.view_user_views -> public.view_user_views_drop_order                                  | {52039,52057}       |     1
--           7 | 52048 | public  | view_user_leaf_views         | public.view_view_depends -> public.view_user_leaf_views                                      | {52035,52048}       |     1
--           8 | 52052 | public  | view_user_views_create_order | public.view_view_depends -> public.view_user_views_create_order                              | {52035,52052}       |     1
--           9 | 52057 | public  | view_user_views_drop_order   | public.view_view_depends -> public.view_user_views_drop_order                                | {52035,52057}       |     1
--          10 | 52057 | public  | view_user_views_drop_order   | public.view_user_views -> public.view_user_leaf_views -> public.view_user_views_drop_order   | {52039,52048,52057} |     2
--          11 | 52052 | public  | view_user_views_create_order | public.view_user_views -> public.view_user_top_views -> public.view_user_views_create_order  | {52039,52044,52052} |     2
--          12 | 52057 | public  | view_user_views_drop_order   | public.view_view_depends -> public.view_user_leaf_views -> public.view_user_views_drop_order | {52035,52048,52057} |     2
-- (12 rows)


CREATE OR REPLACE VIEW View_User_Views_Drop_Order AS
WITH RECURSIVE View_User_Leaf_Views_Tree AS (
SELECT
    View_User_Leaf_Views.*,
    View_User_Leaf_Views.nspname || '.' || View_User_Leaf_Views.relname AS Edges,
    ARRAY[View_User_Leaf_Views.oid] AS Chain,
    0 AS Level
FROM View_User_Leaf_Views
UNION ALL
SELECT
    View_User_Views.*,
    View_User_Leaf_Views_Tree.Edges || ' <- ' || View_User_Views.nspname || '.' || View_User_Views.relname,
    View_User_Leaf_Views_Tree.Chain || View_User_Views.oid,
    View_User_Leaf_Views_Tree.Level+1
FROM View_User_Leaf_Views_Tree
JOIN View_View_Depends ON (View_View_Depends.ev_class = View_User_Leaf_Views_Tree.oid)
JOIN View_User_Views   ON (View_User_Views.oid        = View_View_Depends.refobjid)
), View_User_Leaf_Views_RowNums AS (
    SELECT row_number() OVER (ORDER BY Level,Edges), * FROM View_User_Leaf_Views_Tree
)
SELECT * FROM View_User_Leaf_Views_RowNums
ORDER BY row_number
;

-- glue=# SELECT * FROM View_User_Views_Drop_Order;
--  row_number |  oid  | nspname |           relname            |                                            edges                                             |        chain        | level 
-- ------------+-------+---------+------------------------------+----------------------------------------------------------------------------------------------+---------------------+-------
--           1 | 52052 | public  | view_user_views_create_order | public.view_user_views_create_order                                                          | {52052}             |     0
--           2 | 52057 | public  | view_user_views_drop_order   | public.view_user_views_drop_order                                                            | {52057}             |     0
--           3 | 52044 | public  | view_user_top_views          | public.view_user_views_create_order <- public.view_user_top_views                            | {52052,52044}       |     1
--           4 | 52039 | public  | view_user_views              | public.view_user_views_create_order <- public.view_user_views                                | {52052,52039}       |     1
--           5 | 52035 | public  | view_view_depends            | public.view_user_views_create_order <- public.view_view_depends                              | {52052,52035}       |     1
--           6 | 52048 | public  | view_user_leaf_views         | public.view_user_views_drop_order <- public.view_user_leaf_views                             | {52057,52048}       |     1
--           7 | 52039 | public  | view_user_views              | public.view_user_views_drop_order <- public.view_user_views                                  | {52057,52039}       |     1
--           8 | 52035 | public  | view_view_depends            | public.view_user_views_drop_order <- public.view_view_depends                                | {52057,52035}       |     1
--           9 | 52039 | public  | view_user_views              | public.view_user_views_create_order <- public.view_user_top_views <- public.view_user_views  | {52052,52044,52039} |     2
--          10 | 52039 | public  | view_user_views              | public.view_user_views_drop_order <- public.view_user_leaf_views <- public.view_user_views   | {52057,52048,52039} |     2
--          11 | 52035 | public  | view_view_depends            | public.view_user_views_drop_order <- public.view_user_leaf_views <- public.view_view_depends | {52057,52048,52035} |     2
-- (11 rows)
