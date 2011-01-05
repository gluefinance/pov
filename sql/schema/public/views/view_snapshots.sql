CREATE OR REPLACE VIEW view_snapshots AS
SELECT
    pov.Snapshots.SnapshotID,
    pov.Revisions.RevisionID,
    array_upper(pov.Revisions.ObjectIDs,1) AS NumObjects,
    pov.Snapshots.Datestamp AS povAt,
    pov.Revisions.Datestamp AS RevisionAt,
    pov.Snapshots.Heartbeat,
    pov.Snapshots.Active
FROM pov.Snapshots
INNER JOIN pov.Revisions ON (pov.Revisions.RevisionID = pov.Snapshots.RevisionID)
ORDER BY pov.Snapshots.SnapshotID;
