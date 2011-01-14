#!/bin/sh
dropdb test 2> /dev/null
createdb test
psql test -f $PGSRC/contrib/pgcrypto/pgcrypto.sql
psql -f sql/uninstall.sql test 2> /dev/null
psql -f sql/install.sql test
psql -f test.sql test 1>test.stdout.tmp 2>test.stderr.tmp
diff test.stdout test.stdout.tmp
diff test.stderr test.stderr.tmp
