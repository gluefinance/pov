CREATE OR REPLACE FUNCTION Sort_Array(_Array bigint[]) RETURNS BIGINT[] AS $BODY$
SELECT array_agg(unnest) FROM (SELECT unnest FROM unnest($1) ORDER BY unnest) AS Sorted;
$BODY$ LANGUAGE sql IMMUTABLE;
