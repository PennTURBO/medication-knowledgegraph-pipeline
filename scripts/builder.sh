#!/bin/bash
#cd pipeline
#TODO correct where pds.R output goes
#TODO skip running pds.R if output is present
#Rscript --verbose /pipeline/pds.R
#Rscript --verbose -e 'source("/pipeline/pds.R", echo=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/pds.R", echo=TRUE, verbose=TRUE, max.deparse.length=Inf)'


#TODO? better way of implementing dependencies between services
#      ie wait until mariadb is up to run scripts
#      low priority, just get it working for now

#TODO
#Log files opened/read/written by each script
#strace -f -e open foo.R arg
#-f is follow, subprocesses
#https://jvns.ca/strace-zine-v3.pdf

#After rxnav is up, to rerun this script, currently running:
#docker-compose restart builder

#nc -vz localhost 3306
#Rscript --verbose /pipeline/rxnav_med_mapping_proximity_training_no_tuning.R
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_training_no_tuning.R", echo=TRUE, max.deparse.length=Inf)'

#nc -vz localhost 3306
#Rscript --verbose /pipeline/rxnav_med_mapping_proximity_classifier.R
#Rscript --verbose -e 'source("/pipeline/get_bioportal_mappings.R", echo=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/get_bioportal_mappings.R", echo=TRUE, max.deparse.length=Inf, verbose=TRUE)'

#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf, error=traceback)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf, local=TRUE, options(error=function()traceback(2)))'

#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=FALSE, max.deparse.length=Inf)'

#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_load_materialize_etc.R", echo=TRUE, verbose=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_load_materialize_etc.R", echo=TRUE, max.deparse.length=Inf)'

#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_solr_upload_post_test.R", echo=TRUE, verbose=TRUE, max.deparse.length=Inf)'

Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_solr_upload_post_test.R", echo=TRUE, verbose=TRUE, max.deparse.length=Inf)'

#ls -al /resources
#cd /resources
#alien --verbose --scripts --to-deb /resources/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
#apt install /resources/oracle-instantclient-basic_21.1.0.0.0-2_amd64.deb
#alien --to-deb /resources/oracle-instantclient-odbc-21.1.0.0.0-1.x86_64.rpm

#ls -al /usr/lib/oracle

#alien --verbose --scripts --to-deb /resources/oracle-instantclient-odbc-21.1.0.0.0-1.x86_64.rpm
#apt install /resources/oracle-instantclient-odbc_21.1.0.0.0-2_amd64.deb

#Rscript --verbose -e 'source("/pipeline/pds2.R", echo=TRUE, max.deparse.length=Inf)'

#export CLIENT_HOME=/usr/lib/oracle/21/client64
#export LD_LIBRARY_PATH=$CLIENT_HOME/lib
#export PATH=$PATH:$CLIENT_HOME/bin

#export LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib:$LD_LIBRARY_PATH

#echo $PATH

#echo $LD_LIBRARY_PATH

#Rscript --verbose -e 'install.packages("ROracle")'

#cd /resources
#alien --verbose --scripts --to-deb /resources/oracle-instantclient-devel-21.1.0.0.0-1.x86_64.rpm
#apt install /resources/oracle-instantclient-devel_21.1.0.0.0-2_amd64.deb
#apt-get -y install libaio1

#R CMD INSTALL --configure-args='--with-oci-lib=/usr/lib/oracle/21/client64/lib --with-oci-inc=/usr/include/oracle/21/client64' /resources/ROracle_1.3-1.tar.gz
