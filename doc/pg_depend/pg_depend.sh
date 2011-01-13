#!/bin/sh
dot -opg_depend.png -Tpng pg_depend.dot
dot -opg_depend.svg -Tsvg pg_depend.dot

# Actual possible creation order
dot -opg_depend_actual.png -Tpng pg_depend_actual.dot
dot -opg_depend_actual.svg -Tsvg pg_depend_actual.dot

# Swap deptype = 'i' edges
dot -opg_depend_swapped.png -Tpng pg_depend_swapped.dot
dot -opg_depend_swapped.svg -Tsvg pg_depend_swapped.dot

# Test
dot -opg_depend_test.svg -Tsvg pg_depend_test.dot
