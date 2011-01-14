BEGIN;

SET ROLE TO pov;

SET LOCAL search_path TO public;
-- API functions
\i sql/schema/public/functions/pov.sql

SET LOCAL search_path TO pov;

-- Internal functions
\i sql/schema/pov/functions/Get_Object.sql
\i sql/schema/pov/functions/Get_Revision.sql
\i sql/schema/pov/functions/New_Revision.sql
\i sql/schema/pov/functions/Set_Object.sql
\i sql/schema/pov/functions/Set_Revision.sql
\i sql/schema/pov/functions/Hash.sql

COMMIT;
