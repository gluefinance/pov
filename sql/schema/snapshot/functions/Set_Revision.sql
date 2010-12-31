CREATE OR REPLACE FUNCTION Set_Revision(_ObjectIDs bigint[]) RETURNS BIGINT AS $BODY$
DECLARE
_RevisionID bigint;
_SortedObjectIDs bigint[];
BEGIN
IF _ObjectIDs IS NULL THEN
    RAISE EXCEPTION 'ERROR_SNAPSHOT_OBJECTIDS_IS_NULL';
END IF;
_SortedObjectIDs := Sort_Array(_ObjectIDs);
SELECT RevisionID INTO _RevisionID FROM Revisions WHERE ObjectIDs = _SortedObjectIDs;
IF FOUND THEN
    RETURN _RevisionID;
END IF;
INSERT INTO Revisions (ObjectIDs) VALUES (_SortedObjectIDs) RETURNING RevisionID INTO STRICT _RevisionID;
RETURN _RevisionID;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
