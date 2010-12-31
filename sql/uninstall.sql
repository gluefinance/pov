BEGIN;

DROP SCHEMA snapshot CASCADE;
DROP FUNCTION public.snapshot();
DROP FUNCTION public.snapshot(bigint);
DROP VIEW public.view_snapshots;
DROP USER snapshot;
DROP GROUP snapshot_group;

COMMIT;