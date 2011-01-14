-- This file contains the definition for the two API functions with same name but with different arguments.

CREATE OR REPLACE FUNCTION pov(
OUT _SnapshotID bigint,
OUT _RevisionID text
) RETURNS RECORD AS $BODY$
-- Takes a new pov
-- Example:
-- SELECT pov();
DECLARE
BEGIN

SET LOCAL search_path TO pov;

-- Create new revision, unless it already exists, in which case the existing one will be returned.
_RevisionID := New_Revision();

-- If unmodified, only update its heartbeat and return its SnapshotID.
UPDATE Snapshots SET Heartbeat = now() WHERE Active = 1 AND RevisionID = _RevisionID RETURNING SnapshotID INTO _SnapshotID;
IF FOUND THEN
    SET LOCAL search_path TO DEFAULT;
    RETURN;
END IF;

-- Deactivate existing pov, if any. (might affect 0 rows, it's not a bug we lack IF NOT FOUND here)
UPDATE Snapshots SET Active = 0 WHERE Active = 1;

-- Create a new SnapshotID. The RevisionID might be identical to a previous pov.
INSERT INTO Snapshots (RevisionID) VALUES (_RevisionID) RETURNING SnapshotID INTO STRICT _SnapshotID;

-- Return _SnapshotID and _RevisionID
SET LOCAL search_path TO DEFAULT;
RETURN;

END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;



CREATE OR REPLACE FUNCTION pov(
OUT _SnapshotID bigint,
OUT _RevisionID text,
_RestoreSnapshotID bigint
) RETURNS RECORD AS $BODY$
-- Rollback to given pov
-- Example:
-- SELECT pov(1);
DECLARE
_ObjectIDs text[];
_FunctionID oid;
_ObjectID text;
_SQL text;
_ObjectType text;

_CurrentSnapshotID bigint;
_CurrentRevisionID text;
_CurrentObjectIDs text[];

_RestoredRevisionID text;
_TYPE integer   := 1;
_CREATE integer := 2;
_DROP integer   := 3;
_i integer;
_Num_Objects integer;
BEGIN

-- Disable check_function_bodies to allow creation of sql functions depending on not-yet-created functions,
-- which will be created later in the restore process.
SET check_function_bodies = false;

SET LOCAL search_path TO public;

SELECT * INTO STRICT _CurrentSnapshotID, _CurrentRevisionID FROM pov();

SET LOCAL search_path TO pov;

SELECT ObjectIDs INTO _CurrentObjectIDs FROM Revisions WHERE RevisionID = _CurrentRevisionID;
IF NOT FOUND THEN
    RAISE EXCEPTION 'ERROR_POV_REVISION_NOT_FOUND RevisionID %', _CurrentRevisionID;
END IF;

-- Lookup RevisionID and ObjectIDs for SnapshotID to restore
SELECT Snapshots.RevisionID, Revisions.ObjectIDs INTO _RevisionID, _ObjectIDs FROM Snapshots
INNER JOIN Revisions ON (Revisions.RevisionID = Snapshots.RevisionID)
WHERE Snapshots.SnapshotID = _RestoreSnapshotID;
IF NOT FOUND THEN
    RAISE EXCEPTION 'ERROR_POV_SNAPSHOT_NOT_FOUND SnapshotID %', _RestoreSnapshotID;
END IF;

-- Drop objects not part of the revision.
_Num_Objects := array_upper(_CurrentObjectIDs,1);
FOR _i IN 1.._Num_Objects
LOOP
    _ObjectID := _CurrentObjectIDs[_Num_Objects-_i+1];
    IF NOT _ObjectID = ANY(_ObjectIDs) THEN
        SELECT Content[_TYPE], Content[_DROP] INTO STRICT _ObjectType, _SQL FROM Objects WHERE ObjectID = _ObjectID;
        RAISE DEBUG E'\n-%\n%\n%', _ObjectID, '-    ' || _ObjectType, '-    ' || replace(_SQL,E'\n',E'\n-    ');
        -- EXECUTE _SQL;
    END IF;
END LOOP;

-- Create unpresent objects part of the revision.
_Num_Objects := array_upper(_ObjectIDs,1);
FOR _i IN 1.._Num_Objects
LOOP
    _ObjectID := _CurrentObjectIDs[_Num_Objects];
    IF NOT _ObjectID = ANY(_CurrentObjectIDs) THEN
        SELECT Content[_TYPE], Content[_CREATE] INTO STRICT _ObjectType, _SQL FROM Objects WHERE ObjectID = _ObjectID;
        RAISE DEBUG E'\n-%\n%\n%', _ObjectID, '+    ' || _ObjectType, '+    ' || replace(_SQL,E'\n',E'\n+    ');
        -- EXECUTE _SQL;
    END IF;
END LOOP;

SET LOCAL search_path TO public;

SELECT * INTO STRICT _SnapshotID, _RestoredRevisionID FROM pov();

IF _RevisionID <> _RestoredRevisionID THEN
    RAISE EXCEPTION 'ERROR_POV_REVISION_DIFF RevisionID % RestoredRevisionID %', _RevisionID, _RestoredRevisionID;
END IF;

-- Return new _SnapshotID and the restored _RevisionID.
SET LOCAL search_path TO DEFAULT;
RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;