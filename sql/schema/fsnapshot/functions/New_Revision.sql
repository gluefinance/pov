CREATE OR REPLACE FUNCTION New_Revision(
OUT _RevisionID text
) RETURNS TEXT AS $BODY$
DECLARE
BEGIN

SET LOCAL search_path TO fsnapshot;

-- Create new RevisionID of collection of ObjectIDs.
-- If a revision already exists with the same set of objects, its RevisionID will be selected.
SELECT Set_Revision(ObjectIDs) INTO STRICT _RevisionID FROM (
    -- Make array of all objects
    SELECT
        array_agg(ObjectID) AS ObjectIDs
    FROM (
        -- Create new ObjectID for each function.
        -- If a object already exists with the same content (function definition), its ObjectID will be selected.
        SELECT Set_Object(ARRAY[CreateObject,DropObject],'function') AS ObjectID FROM View_Functions
        UNION
        SELECT Set_Object(ARRAY[CreateObject,DropObject],'constraint') AS ObjectID FROM View_Constraints
    ) AS Objects
) AS Revision;

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
