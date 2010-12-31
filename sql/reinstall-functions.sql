BEGIN;

SET ROLE TO snapshot;

SET LOCAL search_path TO public;
-- API functions
\i schema/public/functions/snapshot.sql

SET LOCAL search_path TO snapshot;

-- Internal functions
\i schema/snapshot/functions/Get_Object.sql
\i schema/snapshot/functions/Get_Revision.sql
\i schema/snapshot/functions/New_Revision.sql
\i schema/snapshot/functions/Set_Object.sql
\i schema/snapshot/functions/Set_Revision.sql
\i schema/snapshot/functions/SHA1.sql
\i schema/snapshot/functions/Sort_Array.sql

COMMIT;
