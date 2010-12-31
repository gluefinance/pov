-- Users belonging to the snapshot_group group will have access to the functions in the schema/public/functions/ directory
CREATE GROUP snapshot_group;

-- When a user of the snapshot_group group executes snapshot() or snapshot(bigint),
-- it is executed as the snapshot user.
-- The snapshot user has the necessary superuser access to create/drop objects.
CREATE USER snapshot WITH SUPERUSER;

-- Create separate schema for snapshot to avoid conflicts with other contribs.
CREATE SCHEMA AUTHORIZATION snapshot;

-- Create plpgsql language, you will get an error if it already exists, which is safe to ignore.
CREATE LANGUAGE plpgsql;

SET ROLE TO snapshot;

BEGIN;

SET LOCAL search_path TO public;

-- API functions
\i schema/public/functions/snapshot.sql

SET LOCAL search_path TO snapshot;
-- Tables
\i schema/snapshot/tables/ObjectTypes.sql
\i schema/snapshot/tables/Objects.sql
\i schema/snapshot/tables/Revisions.sql
\i schema/snapshot/tables/Snapshots.sql

-- Populate control data
\i data/ObjectTypes.sql

-- Internal functions
\i schema/snapshot/functions/Get_Object.sql
\i schema/snapshot/functions/Get_Revision.sql
\i schema/snapshot/functions/New_Revision.sql
\i schema/snapshot/functions/Set_Object.sql
\i schema/snapshot/functions/Set_Revision.sql
\i schema/snapshot/functions/SHA1.sql
\i schema/snapshot/functions/Sort_Array.sql

-- Internal views
\i schema/snapshot/views/View_Functions.sql
\i schema/snapshot/views/View_Constraints.sql
\i schema/snapshot/views/View_Views.sql

SET LOCAL search_path TO public;

-- Public views
\i schema/public/views/view_snapshots.sql

-- Grant permissions
\i schema/grant.sql

COMMIT;
