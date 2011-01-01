-- This file contains the definition for the two API functions with same name but with different arguments.

CREATE OR REPLACE FUNCTION fsnapshot(
OUT _SnapshotID bigint,
OUT _RevisionID text
) RETURNS RECORD AS $BODY$
-- Takes a new fsnapshot
-- Example:
-- SELECT fsnapshot();
DECLARE
BEGIN

SET LOCAL search_path TO fsnapshot;

-- Create new revision, unless it already exists, in which case the existing one will be returned.
_RevisionID := New_Revision();

-- If unmodified, only update its heartbeat and return its SnapshotID.
UPDATE Snapshots SET Heartbeat = now() WHERE Active = 1 AND RevisionID = _RevisionID RETURNING SnapshotID INTO _SnapshotID;
IF FOUND THEN
    SET LOCAL search_path TO DEFAULT;
    RETURN;
END IF;

-- Deactivate existing fsnapshot, if any. (might affect 0 rows, it's not a bug we lack IF NOT FOUND here)
UPDATE Snapshots SET Active = 0 WHERE Active = 1;

-- Create a new FSnapshotID. The RevisionID might be identical to a previous fsnapshot.
INSERT INTO Snapshots (RevisionID) VALUES (_RevisionID) RETURNING SnapshotID INTO STRICT _SnapshotID;

-- Return _SnapshotID and _RevisionID
SET LOCAL search_path TO DEFAULT;
RETURN;

END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;



CREATE OR REPLACE FUNCTION fsnapshot(
OUT _SnapshotID bigint,
OUT _RevisionID text,
_RestoreSnapshotID bigint
) RETURNS RECORD AS $BODY$
-- Rollback to given fsnapshot
-- Example:
-- SELECT fsnapshot(1);
DECLARE
_ObjectIDs text[];
_FunctionID oid;
_ObjectID text;
_SQL text;

_CurrentSnapshotID bigint;
_CurrentRevisionID text;
_CurrentObjectIDs text[];

_RestoredRevisionID text;
_CREATE integer := 2;
_DROP integer   := 3;
BEGIN

-- Disable check_function_bodies to allow creation of sql functions depending on not-yet-created functions,
-- which will be created later in the restore process.
SET check_function_bodies = false;

SET LOCAL search_path TO public;

SELECT * INTO STRICT _CurrentSnapshotID, _CurrentRevisionID FROM fsnapshot();

SET LOCAL search_path TO fsnapshot;

SELECT ObjectIDs INTO _CurrentObjectIDs FROM Revisions WHERE RevisionID = _CurrentRevisionID;
IF NOT FOUND THEN
    RAISE EXCEPTION 'ERROR_FSNAPSHOT_REVISION_NOT_FOUND RevisionID %', _CurrentRevisionID;
END IF;

-- Lookup RevisionID and ObjectIDs for FSnapshotID to restore
SELECT Snapshots.RevisionID, Revisions.ObjectIDs INTO _RevisionID, _ObjectIDs FROM Snapshots
INNER JOIN Revisions ON (Revisions.RevisionID = Snapshots.RevisionID)
WHERE Snapshots.SnapshotID = _RestoreSnapshotID;
IF NOT FOUND THEN
    RAISE EXCEPTION 'ERROR_FSNAPSHOT_SNAPSHOT_NOT_FOUND FSnapshotID %', _RestoreSnapshotID;
END IF;

-- Drop objects not part of the revision.
FOR _ObjectID IN
SELECT DropObjects.ObjectID FROM (
    SELECT unnest AS ObjectID FROM unnest(_CurrentObjectIDs)
    EXCEPT
    SELECT unnest AS ObjectID FROM unnest(_ObjectIDs)
) AS DropObjects
INNER JOIN Objects     ON (Objects.ObjectID = DropObjects.ObjectID)
INNER JOIN ObjectTypes ON (ObjectTypes.Name = Objects.Content[1])
ORDER BY ObjectTypes.ObjectTypeID DESC
LOOP
    SELECT Content[_DROP] INTO STRICT _SQL FROM Objects WHERE ObjectID = _ObjectID;
    RAISE DEBUG E'\n-%\n%', _ObjectID, '-    ' || replace(_SQL,E'\n',E'\n-    ');
    EXECUTE _SQL;
END LOOP;

-- Create objects not in the current revision.
FOR _ObjectID IN
SELECT CreateObjects.ObjectID FROM (
    SELECT unnest AS ObjectID FROM unnest(_ObjectIDs)
    EXCEPT
    SELECT unnest AS ObjectID FROM unnest(_CurrentObjectIDs)
) AS CreateObjects
INNER JOIN Objects     ON (Objects.ObjectID = CreateObjects.ObjectID)
INNER JOIN ObjectTypes ON (ObjectTypes.Name = Objects.Content[1])
ORDER BY ObjectTypes.ObjectTypeID ASC
LOOP
    SELECT Content[_CREATE] INTO STRICT _SQL FROM Objects WHERE ObjectID = _ObjectID;
    RAISE DEBUG E'\n+%\n%', _ObjectID, '+    ' || replace(_SQL,E'\n',E'\n+    ');
    EXECUTE _SQL;
END LOOP;

SET LOCAL search_path TO public;

SELECT * INTO STRICT _SnapshotID, _RestoredRevisionID FROM fsnapshot();

IF _RevisionID <> _RestoredRevisionID THEN
    RAISE EXCEPTION 'ERROR_FSNAPSHOT_REVISION_DIFF RevisionID % RestoredRevisionID %', _RevisionID, _RestoredRevisionID;
END IF;

-- Return new _SnapshotID and the restored _RevisionID.
SET LOCAL search_path TO DEFAULT;
RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;