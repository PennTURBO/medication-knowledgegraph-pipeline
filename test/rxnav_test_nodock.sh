#!/bin/bash
#nc -vz localhost <sql port>
#cd test
set -vx
2>&1 Rscript --verbose rxnav_test_nodock.R
