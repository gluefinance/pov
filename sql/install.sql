-- Users belonging to the fsnapshot_group group will have access to the functions in the schema/public/functions/ directory
CREATE GROUP fsnapshot_group;

-- When a user of the fsnapshot_group group executes fsnapshot() or fsnapshot([hash]::text),
-- it is executed as the fsnapshot user.
-- The fsnapshot user has the necessary superuser access to create/drop objects.
CREATE USER fsnapshot WITH SUPERUSER;

-- Create separate schema for fsnapshot to avoid conflicts with other contribs.
CREATE SCHEMA AUTHORIZATION fsnapshot;

-- Create plpgsql language, you will get an error if it already exists, which is safe to ignore.
CREATE LANGUAGE plpgsql;

SET ROLE TO fsnapshot;

BEGIN;

SET LOCAL search_path TO public;

-- API functions
\i sql/schema/public/functions/fsnapshot.sql

SET LOCAL search_path TO fsnapshot;
-- Tables
\i sql/schema/fsnapshot/tables/ObjectTypes.sql
\i sql/schema/fsnapshot/tables/Objects.sql
\i sql/schema/fsnapshot/tables/Revisions.sql
\i sql/schema/fsnapshot/tables/Snapshots.sql

-- Populate control data
\i sql/data/ObjectTypes.sql

-- Internal functions
\i sql/schema/fsnapshot/functions/Get_Object.sql
\i sql/schema/fsnapshot/functions/Get_Revision.sql
\i sql/schema/fsnapshot/functions/New_Revision.sql
\i sql/schema/fsnapshot/functions/Set_Object.sql
\i sql/schema/fsnapshot/functions/Set_Revision.sql
\i sql/schema/fsnapshot/functions/Hash.sql
\i sql/schema/fsnapshot/functions/Sort_Array.sql

-- Internal views
\i sql/schema/fsnapshot/views/View_Functions.sql
\i sql/schema/fsnapshot/views/View_Constraints.sql
\i sql/schema/fsnapshot/views/View_Views.sql

SET LOCAL search_path TO public;

-- Public views
\i sql/schema/public/views/view_snapshots.sql

-- Grant permissions
\i sql/schema/grant.sql

COMMIT;
