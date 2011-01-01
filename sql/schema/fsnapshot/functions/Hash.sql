CREATE OR REPLACE FUNCTION Hash(_Text text) RETURNS TEXT AS $BODY$
DECLARE
_Hash text;
BEGIN
PERFORM 1 FROM pg_proc WHERE proname = 'digest' AND probin = '$libdir/pgcrypto';
IF FOUND THEN
    -- If we have contrib/pgcrypto, use SHA1
    _Hash := encode(public.digest($1, 'sha1'), 'hex');
ELSE
    -- Default to MD5
    _Hash := md5($1);
END IF;
RETURN _Hash;
END;
$BODY$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION Hash(_Text text[]) RETURNS TEXT AS $BODY$
SELECT fsnapshot.Hash(array_to_string(array_agg(fsnapshot.Hash(unnest)),'')) FROM unnest($1)
$BODY$ LANGUAGE sql IMMUTABLE;
