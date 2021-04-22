#!/bin/bash

#Debugging output
#set -x

#TODO test

#TODO put Rscript command in a variable or function, change with a debugging flag
#TODO print how long each step should take

#TODO R scripts that fail still return exit 0, could add in code to return error code on failure

#nc host.docker.internal 7799

#nc localhost 7799

#Rscript --verbose -e 'installed.packages()'
#Rscript --verbose -e 'install.packages("rdflib")'
#Rscript --verbose -e 'library(rdflib)'



#STEP0
DATA_FOLDER=data

STEP0_IN_FOLDER=resources
STEP0_IN1=ojdbc8.jar
STEP0_IN1_LINK=https://www.oracle.com/database/technologies/jdbc-ucp-122-downloads.html
STEP0_IN2=mysql-connector-java-8.0.23.jar
STEP0_IN2_LINK=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.23.zip
STEP0_IN2_LINK_ZIP=mysql-connector-java-8.0.23.zip
STEP0_IN2_MANUAL_LINK=https://dev.mysql.com/downloads/connector/j/?os=26
STEP0_IN3=robot.jar
STEP0_IN3_LINK=https://github.com/ontodev/robot/releases/download/v1.8.1/robot.jar
STEP0_IN3_MANUAL_LINK=https://github.com/ontodev/robot/releases
STEP0_IN4=robot
STEP0_IN4_LINK=https://raw.githubusercontent.com/ontodev/robot/master/bin/robot

#STEP0_IN4=robot
if [ ! -f "/$STEP0_IN_FOLDER/$STEP0_IN1" ]; then
    echo "$STEP0_IN1 does not exist."
    echo "Please download $STEP0_IN1 from $STEP0_IN1_LINK and place it in the $STEP0_IN_FOLDER folder."
    exit 1
else
    echo "Prerequisite file $STEP0_IN1 exists."
fi
if [ ! -f "/$STEP0_IN_FOLDER/$STEP0_IN2" ]; then
    echo "$STEP0_IN2 does not exist."

    echo "Attempting to download from $STEP0_IN2_LINK."
    curl -L $STEP0_IN2_LINK -o /$STEP0_IN_FOLDER/$STEP0_IN2_LINK_ZIP
    if [ ! $? -eq 0 ]; then
        echo "Download failed. Stopping pipeline."
        echo "Please download the zip from $STEP0_IN2_MANUAL_LINK."
        echo "Select OS as Platform Independent. Unzip and place $STEP0_IN2 in the $STEP0_IN_FOLDER folder."
        exit 1
    fi

    unzip -j /$STEP0_IN_FOLDER/$STEP0_IN2_LINK_ZIP mysql-connector-java-8.0.23/$STEP0_IN2 -d /$STEP0_IN_FOLDER
    if [ ! $? -eq 0 ]; then
        echo "Download failed. Stopping pipeline."
        echo "Please download the zip from STEP0_IN2_MANUAL_LINK."
        echo "Select OS as Platform Independent. Unzip and place $STEP0_IN2 in the $STEP0_IN_FOLDER folder."
        exit 1
    fi  
    rm $STEP0_IN_FOLDER/$STEP0_IN2_LINK_ZIP
else
    echo "Prerequisite file $STEP0_IN2 exists."
fi
if [ ! -f "/$STEP0_IN_FOLDER/$STEP0_IN3" ]; then
    echo "$STEP0_IN3 does not exist."
    echo "Attempting to download from $STEP0_IN3_LINK."
    curl -L $STEP0_IN2_LINK -o /$STEP0_IN_FOLDER/$STEP0_IN3
    if [ ! $? -eq 0 ]; then
        echo "Download failed. Stopping pipeline."
        echo "Please download the file from $STEP0_IN3_MANUAL_LINK and place in the $STEP0_IN_FOLDER folder."
        exit 1
    fi
else
    echo "Prerequisite file $STEP0_IN3 exists."
fi
if [ ! -f "/$STEP0_IN_FOLDER/$STEP0_IN4" ]; then
    echo "$STEP0_IN4 runner script does not exist."
    echo "Attempting to download from $STEP0_IN4_LINK."
    curl $STEP0_IN4_LINK -o /$STEP0_IN_FOLDER/$STEP0_IN4
    if [ ! $? -eq 0 ]; then
        echo "Download failed. Stopping pipeline."
        exit 1
    fi
    echo "Attempting to make $STEP0_IN4 script executable."
    chmod +x /$STEP0_IN_FOLDER/$STEP0_IN4
    if [ ! $? -eq 0 ]; then
        echo "Changing permissions failed. Stopping pipeline."
        exit 1
    fi
else
    echo "Prerequisite file $STEP0_IN4 exists."
fi

STEP1_OUT=/data/source_medications.Rdata
STEP1_SCRIPT=/pipeline/pds.R
if [ -f "$STEP1_OUT" ]; then
    echo "Output file $STEP1_OUT already exists. Skipping $STEP1_SCRIPT."
else
    Rscript --verbose -e 'source("/pipeline/pds.R", echo=TRUE, verbose=TRUE, max.deparse.length=Inf)'
    if [ ! $? -eq 0 ]; then
        echo "$STEP1_SCRIPT failed. Stopping pipeline."
        exit 1
    fi
fi

STEP2_OUT=/data/rxnav_med_mapping_rf_model.all.pds.Rdata
STEP2_SCRIPT=/pipeline/rxnav_med_mapping_proximity_training_no_tuning.R
if [ -f "$STEP2_OUT" ]; then
    echo "Output file $STEP2_OUT already exists. Skipping $STEP2_SCRIPT."
else
    Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_training_no_tuning.R", echo=TRUE, max.deparse.length=Inf)'
    if [ ! $? -eq 0 ]; then
        echo "$STEP2_SCRIPT failed. Stopping pipeline."
        exit 1
    fi
fi

STEP3_IN=/data/RXNORM.ttl.gz
STEP3_IN_DOWNLOAD_FILE=RXNORM.ttl
STEP3_IN_LINK=https://data.bioontology.org/ontologies/RXNORM/submissions/20/download?apikey=8b5b7825-538d-40e0-9e9e-5ab9274a9aeb
STEP3_IN_MANUAL_LINK=https://bioportal.bioontology.org/ontologies/RXNORM
STEP3_OUT=/data/med_mapping_bioportal_mapping.ttl
STEP3_SCRIPT=/pipeline/get_bioportal_mappings.R

if [ ! -f "$STEP3_IN" ]; then
    echo "$STEP3_IN does not exist."
    echo "Checking for $STEP3_IN_DOWNLOAD_FILE."

    if [ ! -f "/$DATA_FOLDER/$STEP3_IN_DOWNLOAD_FILE" ]; then
        echo "$STEP3_IN_DOWNLOAD_FILE does not exist."
        echo "Attempting to download from $STEP3_IN_LINK."
        curl $STEP3_IN_LINK -o /$DATA_FOLDER/$STEP3_IN_DOWNLOAD_FILE
        if [ ! $? -eq 0 ]; then
            echo "Download failed. Stopping pipeline."
            echo "Please download $STEP3_IN_DOWNLOAD_FILE from $STEP3_IN_MANUAL_LINK and place in the $DATA_FOLDER folder."
            exit 1
        fi
    fi

    echo "Compressing $STEP3_IN_DOWNLOAD_FILE"
    #gzip -c /$DATA_FOLDER/$STEP3_IN_DOWNLOAD_FILE > $STEP3_IN
    gzip -k /$DATA_FOLDER/$STEP3_IN_DOWNLOAD_FILE
    if [ ! $? -eq 0 ]; then
        echo "Compressing $STEP3_IN_DOWNLOAD_FILE failed. Stopping pipeline."
        echo "Please download the zip from STEP0_IN2_MANUAL_LINK."
        echo "Select OS as Platform Independent. Unzip and place $STEP0_IN2 in the $STEP0_IN_FOLDER folder."
        exit 1
    fi  
else
    echo "Input file $STEP3_IN for $STEP3_SCRIPT exists."
fi
if [ -f "$STEP3_OUT" ]; then
    echo "Output file $STEP3_OUT already exists. Skipping $STEP3_SCRIPT."
else
    Rscript --verbose -e 'source("/pipeline/get_bioportal_mappings.R", echo=TRUE, max.deparse.length=Inf)'
    if [ ! $? -eq 0 ]; then
        echo "$STEP3_SCRIPT failed. Stopping pipeline."
        exit 1
    fi
fi

STEP4_IN1=/data/med_mapping_bioportal_mapping.ttl
STEP4_IN2=/data/med_name_normalization.csv
STEP4_IN3=/data/RXNORM.ttl
#Note: clears GraphDB repo specified in config$my.selected.repo = 'medication-mapping-dev'
#Produces
#reference_medications_for_robot.tsv
#reference_medications_ontology_annotations.ttl
#reference_medications_from_robot.ttl
#reference_medications_from_robot.ttl.zip
#classified_search_results_for_robot.tsv
#classified_search_results_ontology_annotations.ttl
#classified_search_results_from_robot.ttl
#classified_search_results_from_robot.ttl.zip
STEP4_OUT=/data/reference_medications_from_robot.ttl.zip
STEP4_OUT=/data/classified_search_results_from_robot.ttl.zip
STEP4_SCRIPT=/pipeline/rxnav_med_mapping_proximity_classifier.R
if [ ! -f "$STEP4_IN1" ]; then
    echo "$STEP4_IN1 does not exist. Stopping before running $STEP4_SCRIPT."
    exit 1
else
    echo "Input file $STEP4_IN1 for $STEP4_SCRIPT exists."
fi
if [ ! -f "$STEP4_IN2" ]; then
    echo "$STEP4_IN2 does not exist. Stopping before running $STEP4_SCRIPT."
    exit 1
else
    echo "Input file $STEP4_IN2 for $STEP4_SCRIPT exists."
fi
if [ ! -f "$STEP4_IN3" ]; then
    echo "$STEP4_IN3 does not exist. Stopping before running $STEP4_SCRIPT."
    exit 1
else
    echo "Input file $STEP4_IN3 for $STEP4_SCRIPT exists."
fi
if [ -f "$STEP4_OUT1" -a -f "$STEP4_OUT2"]; then
    echo "Output files $STEP4_OUT1 and $STEP4_OUT2 already exist. Skipping $STEP4_SCRIPT."
else
    Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf, error=traceback)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf, local=TRUE, options(error=function()traceback(2)))'

#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=TRUE, max.deparse.length=Inf)'
#Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_proximity_classifier.R", echo=FALSE, max.deparse.length=Inf)'
    if [ ! $? -eq 0 ]; then
        echo "$STEP4_SCRIPT failed. Stopping pipeline."
        exit 1
    fi
fi

STEP5_IN1=/data/reference_medications_from_robot.ttl.zip
STEP5_IN2=/data/classified_search_results_from_robot.ttl.zip
STEP5_IN3=/data/chebi.owl.gz
STEP5_IN3_DOWNLOAD_FILE=chebi.owl
STEP5_IN3_LINK=http://purl.obolibrary.org/obo/chebi.owl
STEP5_OUT1=/data/rxcui_ttys.ttl
STEP5_OUT2=/data/medlabels_for_chebi_for_solr.json
STEP5_SCRIPT=/pipeline/rxnav_med_mapping_load_materialize.R
if [ ! -f "$STEP5_IN1" ]; then
    echo "$STEP5_IN1 does not exist. Stopping before running $STEP5_SCRIPT."
    exit 1
else
    echo "Input file $STEP5_IN1 for $STEP5_SCRIPT exists."
fi
if [ ! -f "$STEP5_IN2" ]; then
    echo "$STEP5_IN2 does not exist. Stopping before running $STEP5_SCRIPT."
    exit 1
else
    echo "Input file $STEP5_IN2 for $STEP5_SCRIPT exists."
fi
if [ ! -f "$STEP5_IN3" ]; then
    echo "$STEP5_IN3 does not exist."
    
    echo "Checking for $STEP5_IN3_DOWNLOAD_FILE."
    if [ ! -f "/$DATA_FOLDER/$STEP5_IN3_DOWNLOAD_FILE" ]; then
        echo "$STEP5_IN3_DOWNLOAD_FILE does not exist."
        echo "Attempting to download from $STEP5_IN3_LINK."
        curl $STEP5_IN3_LINK -o /$DATA_FOLDER/$STEP5_IN3_DOWNLOAD_FILE
        if [ ! $? -eq 0 ]; then
            echo "Download failed. Stopping pipeline."
            echo "Please download $STEP5_IN3_DOWNLOAD_FILE from $STEP5_IN3_LINK and place in the $DATA_FOLDER folder."
            exit 1
        fi
    fi

    echo "Compressing $STEP5_IN3_DOWNLOAD_FILE"
    gzip /$DATA_FOLDER/$STEP3_IN_DOWNLOAD_FILE
    if [ ! $? -eq 0 ]; then
        echo "Compressing $STEP5_IN3_DOWNLOAD_FILE failed. Stopping pipeline."
        exit 1
    fi  
else
    echo "Input file $STEP5_IN3 for $STEP5_SCRIPT exists."
fi

if [ -f "$STEP5_OUT1" -a -f "$STEP5_OUT2"]; then
    echo "Output files $STEP5_OUT1 and $STEP5_OUT2 already exist. Skipping $STEP5_SCRIPT."
else
    Rscript --verbose -e 'source("/pipeline/rxnav_med_mapping_load_materialize.R", echo=TRUE, max.deparse.length=Inf)'
    if [ ! $? -eq 0 ]; then
        echo "$STEP5_SCRIPT failed. Stopping pipeline."
        exit 1
    fi
fi

echo "Successfully completed build pipeline"
exit 0