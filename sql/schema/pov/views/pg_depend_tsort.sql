-- Topological sort of all non-system objects.
--
-- Before selecting the next possible object to created,
-- the list of such objects will be lexically sorted,
-- to 
--
-- The object description must not contain the delimiter ";!;!;!;".
-- This can be replaced to any bogus string.
--
CREATE OR REPLACE VIEW pov.pg_depend_tsort AS
SELECT
row_number() OVER (),
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\1')          AS description,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\2')::oid     AS classid,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\3')::oid     AS objid,
regexp_replace(unnest,'^(.+) ([0-9]+)[.]([0-9]+)[.]([0-9]+)$',E'\\4')::integer AS objsubid
FROM unnest(
    (
        -- tsort takes a lot of more arguments than these,
        -- but we don't need them for this
        SELECT pov.tsort(
            -- edges:
            array_to_string(
                array_agg(
                    pg_describe_object(
                        split_part(refobj,'.',1)::oid,
                        split_part(refobj,'.',2)::oid,
                        split_part(refobj,'.',3)::integer
                    ) || ' ' || refobj
                    || ';!;!;!;' ||
                    pg_describe_object(
                        split_part(obj,'.',1)::oid,
                        split_part(obj,'.',2)::oid,
                        split_part(obj,'.',3)::integer
                    ) || ' ' || obj
                ),
                ';!;!;!;'
            ),
            -- delimiter:
            ';!;!;!;',
            -- no debug:
            0,
            -- perl-style sort function sub:
            'sub {$a cmp $b}'
        ) FROM pov.pg_depend_oid_concat
    )
);
