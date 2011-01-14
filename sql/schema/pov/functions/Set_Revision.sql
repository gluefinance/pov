CREATE OR REPLACE FUNCTION Set_Revision(_ObjectIDs text[]) RETURNS TEXT AS $BODY$
DECLARE
_RevisionID text;
BEGIN
IF _ObjectIDs IS NULL THEN
    RAISE EXCEPTION 'ERROR_POV_OBJECTIDS_IS_NULL';
END IF;
_RevisionID := Hash(_ObjectIDs);
PERFORM 1 FROM Revisions WHERE RevisionID = _RevisionID;
IF FOUND THEN
    RETURN _RevisionID;
END IF;
INSERT INTO Revisions (RevisionID,ObjectIDs) VALUES (_RevisionID,_ObjectIDs) RETURNING RevisionID INTO STRICT _RevisionID;
RETURN _RevisionID;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
