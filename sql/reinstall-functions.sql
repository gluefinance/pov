BEGIN;

SET ROLE TO fsnapshot;

SET LOCAL search_path TO public;
-- API functions
\i sql/schema/public/functions/fsnapshot.sql

SET LOCAL search_path TO fsnapshot;

-- Internal functions
\i sql/schema/fsnapshot/functions/Get_Object.sql
\i sql/schema/fsnapshot/functions/Get_Revision.sql
\i sql/schema/fsnapshot/functions/New_Revision.sql
\i sql/schema/fsnapshot/functions/Set_Object.sql
\i sql/schema/fsnapshot/functions/Set_Revision.sql
\i sql/schema/fsnapshot/functions/Hash.sql
\i sql/schema/fsnapshot/functions/Sort_Array.sql

COMMIT;
