#!/bin/bash
#cd pipeline
#TODO correct where pds.R output goes
#TODO skip running pds.R if output is present
Rscript --verbose /pipeline/pds.R

#TODO? better way of implementing dependencies between services
#      ie wait until mariadb is up to run scripts
#      low priority, just get it working for now

#After rxnav is up, to rerun this script, currently running:
#docker-compose restart builder
Rscript --verbose /pipeline/rxnav_med_mapping_proximity_training_no_tuning.R

