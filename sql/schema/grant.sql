GRANT USAGE ON SCHEMA snapshot TO GROUP snapshot_group;

GRANT EXECUTE ON FUNCTION public.snapshot() TO snapshot_group;

GRANT EXECUTE ON FUNCTION public.snapshot(bigint) TO snapshot_group;

GRANT SELECT ON TABLE snapshot.Objects   TO snapshot_group;
GRANT SELECT ON TABLE snapshot.Revisions TO snapshot_group;
GRANT SELECT ON TABLE snapshot.Snapshots TO snapshot_group;
