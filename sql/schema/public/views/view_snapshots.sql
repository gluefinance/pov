CREATE OR REPLACE VIEW view_snapshots AS
SELECT
    fsnapshot.Snapshots.SnapshotID,
    fsnapshot.Revisions.RevisionID,
    array_upper(fsnapshot.Revisions.ObjectIDs,1) AS NumObjects,
    fsnapshot.Snapshots.Datestamp AS fsnapshotAt,
    fsnapshot.Revisions.Datestamp AS RevisionAt,
    fsnapshot.Snapshots.Heartbeat,
    fsnapshot.Snapshots.Active
FROM fsnapshot.Snapshots
INNER JOIN fsnapshot.Revisions ON (fsnapshot.Revisions.RevisionID = fsnapshot.Snapshots.RevisionID)
ORDER BY fsnapshot.Snapshots.SnapshotID;
