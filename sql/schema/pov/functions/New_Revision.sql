CREATE OR REPLACE FUNCTION New_Revision(
OUT _RevisionID text
) RETURNS TEXT AS $BODY$
DECLARE
BEGIN

SET LOCAL search_path TO pov;

-- Create new RevisionID of collection of ObjectIDs.
-- If a revision already exists with the same set of objects, its RevisionID will be selected.
SELECT Set_Revision(ObjectIDs) INTO STRICT _RevisionID FROM (
    -- Make array of all objects
    SELECT
        array_agg(ObjectID) AS ObjectIDs
    FROM (
        -- Create new ObjectID for each function.
        -- If a object already exists with the same content (function definition), its ObjectID will be selected.
        SELECT Set_Object(ARRAY[create_definition,drop_definition],description) AS ObjectID FROM pov.pg_depend_definitions
        WHERE create_definition IS NOT NULL AND drop_definition IS NOT NULL AND description ~ '^(constraint|function|trigger|view)'
        ORDER BY row_number
    ) AS Objects
) AS Revision;

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
