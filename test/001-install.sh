#!/bin/sh
dropdb test 2> /dev/null
createdb test
psql test -f /crypt/postgresql-8.4.6/contrib/pgcrypto/pgcrypto.sql
cd sql
psql -f uninstall.sql test 2> /dev/null
psql -f install.sql test
cd ..
psql -f test/001-install.sql test
