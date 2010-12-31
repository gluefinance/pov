GRANT USAGE ON SCHEMA fsnapshot TO GROUP fsnapshot_group;

GRANT EXECUTE ON FUNCTION public.fsnapshot() TO fsnapshot_group;

GRANT EXECUTE ON FUNCTION public.fsnapshot(bigint) TO fsnapshot_group;

GRANT SELECT ON TABLE fsnapshot.Objects   TO fsnapshot_group;
GRANT SELECT ON TABLE fsnapshot.Revisions TO fsnapshot_group;
GRANT SELECT ON TABLE fsnapshot.Snapshots TO fsnapshot_group;
