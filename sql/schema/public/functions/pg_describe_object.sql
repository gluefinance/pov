-- SQL version of the pg_catalog.pg_describe_object function,
-- for those of us not running PostgreSQL 9.
CREATE OR REPLACE FUNCTION public.pg_describe_object(text) RETURNS TEXT AS $BODY$
SELECT pg_describe_object(split_part($1,'.',1)::oid, split_part($1,'.',2)::oid, CASE split_part($1,'.',3) WHEN '' THEN 0 ELSE split_part($1,'.',3)::integer END) || ' ' || $1
$BODY$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION public.pg_describe_object(oid, oid, integer) RETURNS TEXT AS $BODY$
WITH
object             AS (SELECT $1::oid AS classoid, $2::oid AS objoid, $3::integer AS objsubid),
cols AS (
SELECT * FROM pov.pg_unique_object_columns($1,$2,$3)
),
function_num_arguments AS (
    SELECT array_upper(cols.function_input_argument_types,1)+1 AS function_num_arguments FROM cols
),
function_argument_position AS (
    SELECT function_argument_position
    FROM pg_catalog.generate_series(1,(SELECT function_num_arguments FROM function_num_arguments)) AS function_argument_position
),
function_args_in_order AS (
    SELECT function_argument_position, pov._format_type(cols.function_input_argument_types[function_argument_position-1],NULL) AS typname
    FROM function_argument_position, cols
    ORDER BY function_argument_position
),
function_info AS (
    SELECT array_to_string(array_agg(function_args_in_order.typname),',') AS function_arguments FROM function_args_in_order
),
formatted_text AS (
SELECT
    CASE
        WHEN object.classoid = 'pg_ts_template'::regclass THEN 'text search template ' || cols.text_search_template_name
        WHEN object.classoid = 'pg_ts_parser'::regclass   THEN 'text search parser ' || cols.text_search_parser_name
        WHEN object.classoid = 'pg_ts_config'::regclass   THEN 'text search configuration ' || cols.text_search_configuration_name
        WHEN object.classoid = 'pg_ts_dict'::regclass     THEN 'text search dictionary ' || cols.text_search_dictionary_name
        WHEN object.classoid = 'pg_database'::regclass    THEN 'database ' || cols.database_name
        WHEN object.classoid = 'pg_namespace'::regclass   THEN 'schema ' || cols.namespace_name
        WHEN object.classoid = 'pg_language'::regclass    THEN 'language ' || cols.language_name
        WHEN object.classoid = 'pg_conversion'::regclass  THEN 'conversion ' || cols.conversion_name
        WHEN object.classoid = 'pg_constraint'::regclass  THEN 'constraint ' || cols.namespace_name || '.' || cols.constraint_name || COALESCE(' on table ' || cols.relation_name,'')
        WHEN object.classoid = 'pg_rewrite'::regclass     THEN 'rule ' || cols.rule_name || ' on ' || cols.relation_kind || ' ' || cols.namespace_name || '.' || cols.relation_name
        WHEN object.classoid = 'pg_trigger'::regclass     THEN 'trigger ' || cols.trigger_name || ' on ' || cols.relation_kind || ' ' || cols.namespace_name || '.' || cols.relation_name
        WHEN object.classoid = 'pg_cast'::regclass        THEN 'cast from ' || cols.source_data_type_name || ' to ' || cols.target_data_type_name
        WHEN object.classoid = 'pg_amproc'::regclass      THEN 'function ' || cols.support_function_number || ' ' || cols.support_function_name || ' of operator family ' || cols.operator_family_name || ' for access method ' || cols.access_method_name
        WHEN object.classoid = 'pg_operator'::regclass    THEN 'operator ' || cols.namespace_name || '.' || cols.operator_name || '(' || cols.left_data_type_name || ',' || cols.right_data_type_name || ')'
        WHEN object.classoid = 'pg_amop'::regclass        THEN 'operator ' || cols.operator_strategy_number || ' ' || cols.namespace_name || '.' || cols.operator_name || '(' || cols.left_data_type_name || ',' || cols.right_data_type_name || ')' || ' of operator family ' || cols.operator_family_name || ' for access method ' || cols.access_method_name
        WHEN object.classoid = 'pg_opfamily'::regclass    THEN 'operator family ' || cols.operator_family_name || ' for access method ' || cols.access_method_name
        WHEN object.classoid = 'pg_opclass'::regclass     THEN 'operator class ' || cols.operator_class_name || ' for access method ' || cols.access_method_name
        WHEN object.classoid = 'pg_class'::regclass       THEN cols.relation_kind || ' ' || cols.namespace_name || '.' || cols.relation_name
        WHEN object.classoid = 'pg_type'::regclass        THEN 'type ' || cols.data_type_name
        WHEN object.classoid = 'pg_proc'::regclass        THEN 'function ' || cols.namespace_name || '.' || cols.function_name || '(' || COALESCE(function_info.function_arguments,'') || ')'
        WHEN object.classoid = 'pg_attrdef'::regclass     THEN 'default for ' || cols.relation_kind || ' ' || cols.relation_name || ' column ' || cols.attribute_name
    END || CASE WHEN object.classoid = 'pg_class'::regclass AND object.objsubid <> 0 THEN ' column ' || cols.attribute_name ELSE '' END
    AS identifier
FROM object, cols, function_info
)
SELECT identifier FROM formatted_text
$BODY$ LANGUAGE sql STABLE;
