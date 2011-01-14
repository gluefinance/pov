-- Users belonging to the pov_group group will have access to the functions in the schema/public/functions/ directory
CREATE GROUP pov_group;

-- When a user of the pov_group group executes pov() or pov([hash]::text),
-- it is executed as the pov user.
-- The pov user has the necessary superuser access to create/drop objects.
CREATE USER pov WITH SUPERUSER;

-- Create separate schema for pov to avoid conflicts with other contribs.
CREATE SCHEMA AUTHORIZATION pov;

-- Create plpgsql language, you will get an error if it already exists, which is safe to ignore.
CREATE LANGUAGE plpgsql;
CREATE LANGUAGE plperl;

SET ROLE TO pov;

BEGIN;

SET LOCAL search_path TO public;

-- API functions
\i sql/schema/public/functions/pov.sql

SET LOCAL search_path TO pov;
-- Tables
\i sql/schema/pov/tables/ObjectTypes.sql
\i sql/schema/pov/tables/Objects.sql
\i sql/schema/pov/tables/Revisions.sql
\i sql/schema/pov/tables/Snapshots.sql

-- Populate control data
\i sql/data/ObjectTypes.sql

-- Internal functions
\i sql/schema/pov/functions/Get_Object.sql
\i sql/schema/pov/functions/Get_Revision.sql
\i sql/schema/pov/functions/New_Revision.sql
\i sql/schema/pov/functions/Set_Object.sql
\i sql/schema/pov/functions/Set_Revision.sql
\i sql/schema/pov/functions/Hash.sql
\i sql/schema/pov/functions/Sort_Array.sql
\i sql/schema/pov/functions/_format_type.sql
\i sql/schema/pov/functions/tsort.pl
\i sql/schema/pov/functions/pg_get_object_unique_columns.sql

-- Internal views
\i sql/schema/pov/views/pg_all_objects_unique_columns.sql
\i sql/schema/pov/views/pg_depend_remapped.sql
\i sql/schema/pov/views/pg_depend_oid_concat.sql
\i sql/schema/pov/views/pg_depend_dot.sql
\i sql/schema/pov/views/pg_depend_tsort.sql
\i sql/schema/pov/views/pg_depend_definitions.sql
\i sql/schema/pov/views/pg_get_aggregate_create_def.sql
\i sql/schema/pov/views/pg_get_aggregate_drop_def.sql

SET LOCAL search_path TO public;

-- Public views
\i sql/schema/public/views/view_snapshots.sql

-- Grant permissions
\i sql/schema/grant.sql

COMMIT;
