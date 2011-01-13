CREATE SCHEMA pov;
CREATE LANGUAGE plperl;
CREATE LANGUAGE plpgsql;
\i sql/schema/pov/functions/_format_type.sql
\i sql/schema/pov/views/pg_all_objects_unique_columns.sql
\i sql/schema/pov/views/pg_depend_remapped.sql
\i sql/schema/pov/views/pg_depend_oid_concat.sql

\i sql/schema/pov/functions/tsort.pl


