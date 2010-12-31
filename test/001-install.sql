BEGIN;
SET client_min_messages = 'debug';
SELECT * FROM snapshot();
CREATE FUNCTION myfunc() RETURNS VOID AS $$ $$ LANGUAGE sql;
\df myfunc
SELECT * FROM snapshot();
SELECT * FROM snapshot(1);
\df myfunc
ROLLBACK;
