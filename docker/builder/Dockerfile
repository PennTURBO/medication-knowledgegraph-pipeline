FROM r-base:3.6.2

RUN apt-get update && \
  apt-get -y install \
    libssh-dev \
    libcurl4-openssl-dev \
    default-jdk \
    libxml2-dev \
    libv8-dev \
    ncat \
    dos2unix \
    openssh-client && \

  apt-get install -y \
    r-cran-rjava \
    r-cran-devtools \
    r-cran-dplyr r-cran-e1071 \
    r-cran-ggplot2 \
    r-cran-httr \
    r-cran-igraph \
    r-cran-jsonlite \
    r-cran-randomforest \
    r-cran-rdflib \
    r-cran-readr \
    r-cran-readxl \
    r-cran-reshape2 \
    r-cran-solrium \
    r-cran-stringdist \
    r-cran-stringr \
    r-cran-tm \
    r-cran-uuid \
    r-cran-rocr \
    r-cran-caret \
    r-cran-zip \
    r-cran-gtools \

    && apt-get -y autoremove \
    && apt-get clean

RUN Rscript -e 'install.packages("config")' && \
    Rscript -e 'install.packages("RJDBC")' && \
    Rscript -e 'install.packages("ssh")' && \
    Rscript -e 'install.packages("splitstackshape")' && \
    Rscript -e 'library(devtools); \
                install_github("egonw/rrdf", subdir="rrdflibs"); \
                install_github("egonw/rrdf", subdir="rrdf", build_vignettes = FALSE)'

# load R packages
#RUN Rscript -e 'install.packages(c("config", "httr", "igraph", "SPARQL", "rdflib", "tibble", "uuid", "config"))'
#RUN Rscript -e 'install.packages(c("rJava", "devtools", "config", "dplyr", "e1071", "ggplot2", "httr", "igraph", "jsonlite", "randomForest", "rdflib", "readr", "readxl", "reshape2", "RJDBC", "solrium", "ssh", "stringdist", "stringr", "tm", "uuid", "splitstackshape", "ROCR", "caret", "xgboost", "zip", "gtools"))'

#RUN Rscript -e 'install.packages("devtools")'
#RUN Rscript -e 'install.packages("rJava")'
#RUN Rscript -e 'install.packages("config")'
#RUN Rscript -e 'install.packages("dplyr")'
#RUN Rscript -e 'install.packages("e1071")'
#RUN Rscript -e 'install.packages("ggplot2")'
#RUN Rscript -e 'install.packages("httr")'
#RUN Rscript -e 'install.packages("igraph")'
#RUN Rscript -e 'install.packages("jsonlite")'
#RUN Rscript -e 'install.packages("randomForest")'
#RUN Rscript -e 'install.packages("rdflib")'
#RUN Rscript -e 'install.packages("readr")'
#RUN Rscript -e 'install.packages("readxl")'
#RUN Rscript -e 'install.packages("reshape2")'
#RUN Rscript -e 'install.packages("RJDBC")'
#RUN Rscript -e 'install.packages("solrium")'
#RUN Rscript -e 'install.packages("ssh")'
#RUN Rscript -e 'install.packages("stringdist")'
#RUN Rscript -e 'install.packages("tm")'
#RUN Rscript -e 'install.packages("uuid")'
#RUN Rscript -e 'install.packages("splitstackshape")'
#RUN Rscript -e 'install.packages("ROCR")'
#RUN Rscript -e 'install.packages("caret")'
#RUN Rscript -e 'install.packages("xgboost")'
#RUN Rscript -e 'install.packages("zip")'
#RUN Rscript -e 'install.packages("gtools")'

#RUN Rscript -e '\
#library(rJava); \
#library(devtools); \
#library(config); \
#library(dplyr); \
#library(e1071); \
#library(ggplot2); \
#library(httr); \
#library(igraph); \
#library(jsonlite); \
#library(randomForest); \
#library(rdflib); \
#library(readr); \
#library(readxl); \
#library(reshape2); \
#library(RJDBC); \
#library(solrium); \
#library(ssh); \
#library(stringdist); \
#library(stringr); \
#library(tm); \
#library(uuid); \
#library(splitstackshape); \
#library(ROCR); \
#library(caret); \
#library(zip); \
#library(gtools); \
#'

#COPY /home/user/medication-knowledgegraph-pipeline/ojdbc8.jar /ojdbc8.jar.2
#COPY ojdbc8.jar /ojdbc8.jar
#COPY mysql-connector-java-8.0.23.jar /mysql-connector-java-8.0.23.jar
