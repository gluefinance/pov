SET check_function_bodies TO FALSE;
CREATE OR REPLACE FUNCTION get_unique_name_for_pg_am(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_am.amname::text FROM pg_am WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_amop(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_opfamily(pg_catalog.pg_amop.amopfamily) || '.'
     || get_unique_name_for_pg_operator(pg_catalog.pg_amop.amopopr) FROM pg_amop WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_amproc(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_opfamily(pg_catalog.pg_amproc.amprocfamily) || '.'
     || get_unique_name_for_pg_type(pg_catalog.pg_amproc.amproclefttype) || '.'
     || get_unique_name_for_pg_type(pg_catalog.pg_amproc.amprocrighttype) || '.'
     || pg_catalog.pg_amproc.amprocnum::text FROM pg_amproc WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_authid(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_authid.rolname::text FROM pg_authid WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_cast(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_type(pg_catalog.pg_cast.castsource) || '.'
     || get_unique_name_for_pg_type(pg_catalog.pg_cast.casttarget) FROM pg_cast WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_class(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_class.relnamespace) || '.'
     || pg_catalog.pg_class.relname::text FROM pg_class WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_constraint(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_constraint.connamespace) || '.'
     || pg_catalog.pg_constraint.conname::text FROM pg_constraint WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_conversion(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_conversion.connamespace) || '.'
     || pg_catalog.pg_conversion.conname::text FROM pg_conversion WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_database(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_database.datname::text FROM pg_database WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_enum(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_type(pg_catalog.pg_enum.enumtypid) || '.'
     || pg_catalog.pg_enum.enumlabel::text FROM pg_enum WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_foreign_data_wrapper(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_foreign_data_wrapper.fdwname::text FROM pg_foreign_data_wrapper WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_foreign_server(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_foreign_server.srvname::text FROM pg_foreign_server WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_language(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_language.lanname::text FROM pg_language WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_namespace(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_namespace.nspname::text FROM pg_namespace WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_opclass(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_am(pg_catalog.pg_opclass.opcmethod) || '.'
     || get_unique_name_for_pg_namespace(pg_catalog.pg_opclass.opcnamespace) || '.'
     || pg_catalog.pg_opclass.opcname::text FROM pg_opclass WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_operator(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_type(pg_catalog.pg_operator.oprleft) || '.'
     || get_unique_name_for_pg_type(pg_catalog.pg_operator.oprright) || '.'
     || get_unique_name_for_pg_namespace(pg_catalog.pg_operator.oprnamespace) || '.'
     || pg_catalog.pg_operator.oprname::text FROM pg_operator WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_opfamily(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_am(pg_catalog.pg_opfamily.opfmethod) || '.'
     || get_unique_name_for_pg_namespace(pg_catalog.pg_opfamily.opfnamespace) || '.'
     || pg_catalog.pg_opfamily.opfname::text FROM pg_opfamily WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_rewrite(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_rewrite.ev_class) || '.'
     || pg_catalog.pg_rewrite.rulename::text FROM pg_rewrite WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_tablespace(oid) RETURNS TEXT AS $$
    SELECT pg_catalog.pg_tablespace.spcname::text FROM pg_tablespace WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_trigger(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_trigger.tgrelid) || '.'
     || pg_catalog.pg_trigger.tgname::text FROM pg_trigger WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_ts_config(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_ts_config.cfgnamespace) || '.'
     || pg_catalog.pg_ts_config.cfgname::text FROM pg_ts_config WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_ts_dict(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_ts_dict.dictnamespace) || '.'
     || pg_catalog.pg_ts_dict.dictname::text FROM pg_ts_dict WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_ts_parser(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_ts_parser.prsnamespace) || '.'
     || pg_catalog.pg_ts_parser.prsname::text FROM pg_ts_parser WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_ts_template(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_ts_template.tmplnamespace) || '.'
     || pg_catalog.pg_ts_template.tmplname::text FROM pg_ts_template WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_type(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_type.typnamespace) || '.'
     || pg_catalog.pg_type.typname::text FROM pg_type WHERE oid = $1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_user_mapping(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_authid(pg_catalog.pg_user_mapping.umuser) || '.'
     || get_unique_name_for_pg_foreign_server(pg_catalog.pg_user_mapping.umserver) FROM pg_user_mapping WHERE oid = $1;
$$ LANGUAGE sql STABLE;



CREATE OR REPLACE FUNCTION get_unique_name_for_pg_type(oid) RETURNS TEXT AS $$
    SELECT COALESCE((SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_type.typnamespace) || '.'
     || pg_catalog.pg_type.typname::text FROM pg_type WHERE oid = $1),'');
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_attrdef(oid, integer) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_attrdef.adrelid) || '.'
     || pg_catalog.pg_attribute.attname::text FROM pg_catalog.pg_attrdef
     JOIN pg_catalog.pg_attribute ON (pg_catalog.pg_attribute.attrelid = pg_catalog.pg_attrdef.adrelid AND pg_catalog.pg_attribute.attnum = pg_catalog.pg_attrdef.adnum)
     WHERE pg_catalog.pg_attrdef.adrelid = $1 AND pg_catalog.pg_attrdef.adnum = $2;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_attribute(oid, integer) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_attribute.attrelid) || '.'
     || pg_catalog.pg_attribute.attname::text FROM pg_catalog.pg_attribute
     WHERE pg_catalog.pg_attribute.attrelid = $1 AND pg_catalog.pg_attribute.attnum = $2;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_proc(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_proc.pronamespace) || '.' || pg_catalog.pg_proc.proname::text || '(' || pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || ')'
    FROM pg_catalog.pg_proc WHERE pg_catalog.pg_proc.oid = $1;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION obj_unique_identifier(classid oid, objectid oid, objsubid integer) RETURNS TEXT AS $BODY$
SELECT
    CASE WHEN $1 = 0 AND $2 = 0 AND $3 = 0 THEN '-'
    ELSE
        $1::regclass::text
        || '.' ||
        CASE
            WHEN $1::regclass = 'pg_am'::regclass                     THEN get_unique_name_for_pg_am($2)
            WHEN $1::regclass = 'pg_amop'::regclass                   THEN get_unique_name_for_pg_amop($2)
            WHEN $1::regclass = 'pg_amproc'::regclass                 THEN get_unique_name_for_pg_amproc($2)
            WHEN $1::regclass = 'pg_authid'::regclass                 THEN get_unique_name_for_pg_authid($2)
            WHEN $1::regclass = 'pg_cast'::regclass                   THEN get_unique_name_for_pg_cast($2)
            WHEN $1::regclass = 'pg_class'::regclass                  THEN get_unique_name_for_pg_class($2)
            WHEN $1::regclass = 'pg_constraint'::regclass             THEN get_unique_name_for_pg_constraint($2)
            WHEN $1::regclass = 'pg_conversion'::regclass             THEN get_unique_name_for_pg_conversion($2)
            WHEN $1::regclass = 'pg_database'::regclass               THEN get_unique_name_for_pg_database($2)
            WHEN $1::regclass = 'pg_enum'::regclass                   THEN get_unique_name_for_pg_enum($2)
            WHEN $1::regclass = 'pg_foreign_data_wrapper'::regclass   THEN get_unique_name_for_pg_foreign_data_wrapper($2)
            WHEN $1::regclass = 'pg_foreign_server'::regclass         THEN get_unique_name_for_pg_foreign_server($2)
            WHEN $1::regclass = 'pg_language'::regclass               THEN get_unique_name_for_pg_language($2)
            WHEN $1::regclass = 'pg_namespace'::regclass              THEN get_unique_name_for_pg_namespace($2)
            WHEN $1::regclass = 'pg_opclass'::regclass                THEN get_unique_name_for_pg_opclass($2)
            WHEN $1::regclass = 'pg_operator'::regclass               THEN get_unique_name_for_pg_operator($2)
            WHEN $1::regclass = 'pg_opfamily'::regclass               THEN get_unique_name_for_pg_opfamily($2)
            WHEN $1::regclass = 'pg_proc'::regclass                   THEN get_unique_name_for_pg_proc($2)
            WHEN $1::regclass = 'pg_rewrite'::regclass                THEN get_unique_name_for_pg_rewrite($2)
            WHEN $1::regclass = 'pg_tablespace'::regclass             THEN get_unique_name_for_pg_tablespace($2)
            WHEN $1::regclass = 'pg_trigger'::regclass                THEN get_unique_name_for_pg_trigger($2)
            WHEN $1::regclass = 'pg_ts_config'::regclass              THEN get_unique_name_for_pg_ts_config($2)
            WHEN $1::regclass = 'pg_ts_dict'::regclass                THEN get_unique_name_for_pg_ts_dict($2)
            WHEN $1::regclass = 'pg_ts_parser'::regclass              THEN get_unique_name_for_pg_ts_parser($2)
            WHEN $1::regclass = 'pg_ts_template'::regclass            THEN get_unique_name_for_pg_ts_template($2)
            WHEN $1::regclass = 'pg_type'::regclass                   THEN get_unique_name_for_pg_type($2)
            WHEN $1::regclass = 'pg_user_mapping'::regclass           THEN get_unique_name_for_pg_user_mapping($2)
            ELSE NULL
        END
        ||
        CASE
            WHEN $3 = 0 THEN ''
            WHEN $1::regclass = 'pg_class'::regclass AND $3 >= 1 THEN '.' || get_unique_name_for_pg_attribute($2,$3)
            ELSE NULL
        END
    END;
$BODY$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION obj_unique_identifier(oid) RETURNS TEXT AS  obj_unique_identifier(d.classid, d.objid, d.objsubid) FROM (
    SELECT pg_depend.classid, pg_depend.objid, pg_depend.objsubid FROM pg_catalog.pg_depend
    WHERE pg_depend.objid = 
    UNION ALL
    SELECT pg_depend.refclassid, pg_depend.refobjid, pg_depend.refobjsubid FROM pg_catalog.pg_depend
    WHERE pg_depend.refobjid = 
    LIMIT 1
) AS d;
 sql STABLE;

