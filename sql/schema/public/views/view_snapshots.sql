CREATE OR REPLACE VIEW view_snapshots AS
SELECT
    snapshot.Snapshots.SnapshotID,
    snapshot.Revisions.RevisionID,
    array_upper(snapshot.Revisions.ObjectIDs,1) AS NumObjects,
    snapshot.Snapshots.Datestamp AS SnapshotAt,
    snapshot.Revisions.Datestamp AS RevisionAt,
    snapshot.Snapshots.Heartbeat,
    snapshot.Snapshots.Active
FROM snapshot.Snapshots
INNER JOIN snapshot.Revisions ON (snapshot.Revisions.RevisionID = snapshot.Snapshots.RevisionID)
ORDER BY snapshot.Snapshots.SnapshotID;
