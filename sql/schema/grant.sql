GRANT USAGE ON SCHEMA pov TO GROUP pov_group;

GRANT EXECUTE ON FUNCTION public.pov() TO pov_group;

GRANT EXECUTE ON FUNCTION public.pov(bigint) TO pov_group;

GRANT SELECT ON TABLE pov.Objects   TO pov_group;
GRANT SELECT ON TABLE pov.Revisions TO pov_group;
GRANT SELECT ON TABLE pov.Snapshots TO pov_group;
