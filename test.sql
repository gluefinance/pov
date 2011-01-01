BEGIN;

SET client_min_messages = 'debug';

-- Test creating/dropping/restoring function
SELECT * FROM fsnapshot(); -- 1
CREATE FUNCTION myfunc() RETURNS VOID AS $$ $$ LANGUAGE sql;
\df myfunc
SELECT * FROM fsnapshot(); -- 2
SELECT * FROM fsnapshot(1); -- 3
\df myfunc

-- Test creating/dropping/restoring function and the constraint which depends on it
CREATE FUNCTION mycheckfunc(int) RETURNS BOOLEAN AS $$ SELECT $1 > 1 $$ LANGUAGE sql;
CREATE TABLE mytable(id int, PRIMARY KEY(id), CHECK(mycheckfunc(id)));
\df mycheckfunc
\d mytable
SELECT * FROM fsnapshot(); -- 4
SELECT * FROM fsnapshot(3); -- 5
\df mycheckfunc
\d mytable
SELECT * FROM fsnapshot(4); -- 6
\df mycheckfunc
\d mytable

-- Test creating/dropping/restoring a view which depends on a function
CREATE VIEW myview AS SELECT *, mycheckfunc(id) FROM mytable;
\d myview
SELECT * FROM fsnapshot(); -- 7
SELECT * FROM fsnapshot(6); -- 8
\d myview
\df mycheckfunc
\d mytable
SELECT * FROM fsnapshot(7); -- 9
\d myview
\df mycheckfunc
\d mytable


ROLLBACK;
