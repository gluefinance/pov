#!/bin/sh
dot -opg_depend.png -Tpng pg_depend.dot
dot -opg_depend.svg -Tsvg pg_depend.dot

# Actual possible creation order
dot -opg_depend_actual.png -Tpng pg_depend_actual.dot
dot -opg_depend_actual.svg -Tsvg pg_depend_actual.dot