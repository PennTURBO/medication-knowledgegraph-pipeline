#!/bin/bash
set -vx
#nc -vz localhost 3306
#nc -vz 172.18.0.1 3306
#nc -vz rxnav-db 3306
#cd test
#2>&1 Rscript --verbose rxnav_test_nodock.R
Rscript --verbose /test/rxnav_test.R
