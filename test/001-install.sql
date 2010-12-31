BEGIN;
SET client_min_messages = 'debug';
SELECT * FROM fsnapshot();
CREATE FUNCTION myfunc() RETURNS VOID AS $$ $$ LANGUAGE sql;
\df myfunc
SELECT * FROM fsnapshot();
SELECT * FROM fsnapshot(1);
\df myfunc
ROLLBACK;
