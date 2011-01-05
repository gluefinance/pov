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

-- Internal views
\i sql/schema/pov/views/View_Functions.sql
\i sql/schema/pov/views/View_Constraints.sql
\i sql/schema/pov/views/View_Views.sql

SET LOCAL search_path TO public;

-- Public views
\i sql/schema/public/views/view_snapshots.sql

-- Grant permissions
\i sql/schema/grant.sql

COMMIT;
