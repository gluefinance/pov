CREATE OR REPLACE FUNCTION SHA1(_Text text[]) RETURNS CHAR(40) AS $BODY$
SELECT encode(public.digest(array_to_string($1,''), 'sha1'), 'hex');
$BODY$ LANGUAGE sql IMMUTABLE;
