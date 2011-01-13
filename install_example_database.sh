#!/bin/sh
dropdb test 2> /dev/null
createdb test
psql test -f sql/install_example_database.sql
echo Installed!
