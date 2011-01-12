#!/bin/sh
dot -opg_depend.png -Tpng pg_depend.dot
dot -opg_depend.svg -Tsvg pg_depend.dot