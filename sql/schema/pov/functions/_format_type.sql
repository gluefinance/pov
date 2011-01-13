-- Necessary because the regular format_type function returns "-" for non existing oids,
-- while for pg_describe_object uses "NONE"
CREATE OR REPLACE FUNCTION pov._format_type(oid, integer) RETURNS TEXT AS $BODY$
SELECT CASE WHEN $1 = 0 THEN 'NONE' ELSE format_type($1, $2) END;
$BODY$ LANGUAGE sql STABLE;
