CREATE SCHEMA pov;
CREATE LANGUAGE plperl;
CREATE LANGUAGE plpgsql;
\i sql/schema/pov/functions/_format_type.sql
\i sql/schema/pov/functions/tsort.pl
\i sql/schema/pov/functions/pg_get_object_unique_columns.sql
\i sql/schema/pov/views/pg_all_objects_unique_columns.sql
\i sql/schema/pov/views/pg_depend_remapped.sql
\i sql/schema/pov/views/pg_depend_oid_concat.sql
\i sql/schema/pov/views/pg_depend_dot.sql
\i sql/schema/pov/views/pg_depend_tsort.sql
\i sql/schema/pov/views/pg_depend_definitions.sql
