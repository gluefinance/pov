BEGIN;

SET client_min_messages = 'debug';

-- Test creating/dropping/restoring function
SELECT * FROM pov(); -- Take snapshot #1
CREATE FUNCTION myfunc() RETURNS VOID AS $$ $$ LANGUAGE sql;
\df myfunc
SELECT * FROM pov(); -- Take snapshot #2
SELECT * FROM pov(1); -- Rollback to snapshot #1, new snapshot #3
\df myfunc

-- Test creating/dropping/restoring function and the constraint which depends on it
CREATE FUNCTION mycheckfunc(int) RETURNS BOOLEAN AS $$ SELECT $1 > 1 $$ LANGUAGE sql;
CREATE TABLE mytable(id int, PRIMARY KEY(id), CHECK(mycheckfunc(id)));
\df mycheckfunc
\d mytable
SELECT * FROM pov(); -- Take snapshot #4
SELECT * FROM pov(3); -- Rollback to snapshot #3, new snapshot #5
\df mycheckfunc
\d mytable
SELECT * FROM pov(4); -- Rollback to snapshot #4, new snapshot #6
\df mycheckfunc
\d mytable

-- Test creating/dropping/restoring a view which depends on a function
CREATE VIEW myview AS SELECT *, mycheckfunc(id) FROM mytable;
\d myview
SELECT * FROM pov(); -- Take snapshot #7
SELECT * FROM pov(6); -- Rollback to snapshot #6, new snapshot #8
\d myview
\df mycheckfunc
\d mytable
SELECT * FROM pov(7); -- Take snapshot #9
\d myview
\df mycheckfunc
\d mytable


ROLLBACK;
