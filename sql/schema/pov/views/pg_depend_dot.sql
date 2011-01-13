-- Generate directional graph of pg_depend in DOT-language.
--
-- To generate a svg or png graph, using the dot tool from Graphviz,
-- put the output from this view in a file, e.g. pg_depend.dot, then do:
-- dot -opg_depend.svg -Tsvg pg_depend.dot
-- dot -opg_depend.png -Tpng pg_depend.dot
--
CREATE OR REPLACE VIEW pov.pg_depend_dot AS
SELECT 'digraph pg_depend {' AS diagraph
UNION ALL
SELECT '    "' ||
    pg_describe_object(
        split_part(refobj,'.',1)::oid,
        split_part(refobj,'.',2)::oid,
        split_part(refobj,'.',3)::integer
    ) || ' ' || refobj
    || '" -> "' ||
    pg_describe_object(
        split_part(obj,'.',1)::oid,
        split_part(obj,'.',2)::oid,
        split_part(obj,'.',3)::integer
    ) || ' ' || obj
    || '" [' || CASE
                WHEN array_to_string(array_agg(deptype),'') ~ '^n+$'           THEN 'color=black'
                WHEN array_to_string(array_agg(deptype),'') ~ '^i+$'           THEN 'color=red'
                WHEN array_to_string(array_agg(deptype),'') ~ '^a+$'           THEN 'color=blue'
                WHEN array_to_string(array_agg(deptype),'') ~ '^(ni|in)[ni]*$' THEN 'color=green'
                WHEN array_to_string(array_agg(deptype),'') ~ '^(na|an)[na]*$' THEN 'color=yellow'
                ELSE 'style=dotted'
                END
    || ' label=' || array_to_string(array_agg(deptype),'') || ']'
FROM pov.pg_depend_oid_concat GROUP BY refobj, obj
UNION ALL
SELECT '}'
;
