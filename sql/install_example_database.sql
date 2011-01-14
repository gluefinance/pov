CREATE SCHEMA pov;
CREATE LANGUAGE plperl;
CREATE LANGUAGE plpgsql;
\i sql/schema/pov/functions/_format_type.sql
\i sql/schema/pov/functions/tsort.pl
\i sql/schema/pov/views/pg_all_objects_unique_columns.sql
\i sql/schema/pov/views/pg_depend_remapped.sql
\i sql/schema/pov/views/pg_depend_oid_concat.sql
\i sql/schema/pov/views/pg_depend_dot.sql
\i sql/schema/pov/views/pg_depend_tsort.sql
\i sql/schema/pov/views/pg_depend_definitions.sql

-- Dependency level 1 (directly under public schema:)
CREATE TABLE t1 ( id integer, PRIMARY KEY (id) );
CREATE FUNCTION f1 ( integer ) RETURNS boolean AS $$ SELECT $1 > 1; $$ LANGUAGE sql;
CREATE SEQUENCE s1;

-- Dependency level 2:
CREATE TABLE t2 ( id integer, PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES t1(id) );
CREATE TABLE t3 ( id integer not null default nextval('s1'), PRIMARY KEY (id), CHECK(f1(id)) );

-- Dependency level 3:
CREATE VIEW v1 AS SELECT * FROM t1;
CREATE VIEW v2 AS SELECT * FROM t2;

-- Dependency level 4:
CREATE VIEW v3 AS SELECT v1.id AS id1, v2.id AS id2 FROM v1, v2;

-- Dependency level 5:
CREATE VIEW v4 AS SELECT *, f1(id1) FROM v3;

