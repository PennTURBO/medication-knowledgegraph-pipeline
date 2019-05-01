options(java.parameters = "-Xmx32g")
library(rrdf)
library(tibble)
library(readr)
library(dplyr)
library(data.table)

# change mydata:Row to something more meaningful and update documentation
# make sure documentation is already updated for...
# instantiate order counts WITH PKs
# get metrics for r_medication usage by orders and vice versa
# review selah's options for mapping chop and uphs medications

PK_ORDER_MED_ID_per_PK_MEDICATION <-
  read_csv(
    "/terabyte/distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051.csv"
  )
names(PK_ORDER_MED_ID_per_PK_MEDICATION) <-
  c("PK_MEDICATION_ID", "PK_ORDER_MED_ID.count")

hexdigs <- c(0:9, letters[1:6])
my.repo <- "med_map_support_20180403"
sparql.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo)

from.pds <- lapply(hexdigs, function(current.dig) {
  print(current.dig)
  my.query <- paste0(
    "
PREFIX mydata: <http://example.com/resource/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
?R_MEDICATION_URI ?PK_MEDICATION_ID ?rmuchunk ?FULL_NAME ?SOURCE_CODE ?pds_rxn_val ?RXNORM_CODE_URI_active
# ?solrMatchTerm ?rxnifavailable  ?rxnlab ?rfres ?rf_predicted_proximity ?max_useful_prob_by_row ?max_useful_prob_by_med ?relative_prob ?boosted ?max_boosted ?relative_boosted
where {
graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
?R_MEDICATION_URI a mydata:Row ;
mydata:FULL_NAME ?FULL_NAME ;
mydata:SOURCE_CODE ?SOURCE_CODE ;
mydata:PK_MEDICATION_ID ?PK_MEDICATION_ID .
optional {
?R_MEDICATION_URI mydata:RXNORM ?pds_rxn_val .
}
bind(substr(str(?R_MEDICATION_URI), 45, 1) as ?rmuchunk)
filter(substr(str(?R_MEDICATION_URI), 45, 1) = '",
  current.dig,
  "')
}
optional {
graph mydata:pds_rxn_casts {
?R_MEDICATION_URI  mydata:RXNORM_CODE_URI ?RXNORM_CODE_URI_active
}
}
}
")
  time.start <-  Sys.time()
  print(time.start)
  my.result <-
    sparql.remote(endpoint = sparql.endpoint,
                  sparql = my.query,
                  jena = TRUE)
  time.stop <-  Sys.time()
  time.duration <- time.stop - time.start
  print(time.duration)
  print(nrow(my.result))
  return(as_tibble(my.result))
})
from.pds <- do.call(rbind.data.frame, from.pds)
nrow(from.pds)
# about 40 seconds * 15
#
# 942089 rows on 29 april 2019

from.pds$PK_MEDICATION_ID <- as.numeric(from.pds$PK_MEDICATION_ID)

###   ###   ###

from.pds <- left_join(from.pds,
                      PK_ORDER_MED_ID_per_PK_MEDICATION,
                      by = "PK_MEDICATION_ID")

###   ###   ###

pds.to.rfpred <- lapply(hexdigs, function(current.dig) {
  print(current.dig)
  my.query <- paste0(
    "
PREFIX mydata: <http://example.com/resource/>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
?R_MEDICATION_URI ?rfres
where {
  graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
    ?R_MEDICATION_URI a mydata:Row ;
    bind(substr(str(?R_MEDICATION_URI), 45, 1) as ?rmuchunk)
    filter(substr(str(?R_MEDICATION_URI), 45, 1) = '",
    current.dig,
    "')
  }
  graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
    ?rfres a mydata:rfres ;
    mydata:R_MEDICATION_URI ?R_MEDICATION_URI ;
  }
}
")
  time.start <-  Sys.time()
  print(time.start)
  my.result <-
    sparql.remote(endpoint = sparql.endpoint,
                  sparql = my.query,
                  jena = TRUE)
  time.stop <-  Sys.time()
  time.duration <- time.stop - time.start
  print(time.duration)
  print(nrow(my.result))
  return(as_tibble(my.result))
})
pds.to.rfpred <- do.call(rbind.data.frame, pds.to.rfpred)
nrow(pds.to.rfpred)

print(length(unique(pds.to.rfpred$R_MEDICATION_URI)))

print(length(unique(pds.to.rfpred$rfres)))

###   ###   ###

rfpred.rxns <- lapply(hexdigs, function(current.dig) {
  print(current.dig)
  my.query <- paste0(
    "
PREFIX mydata: <http://example.com/resource/>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
?rfres ?rmuchunk ?rxnifavailable ?relative_boosted
where {
  graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
    ?rfres a mydata:rfres ;
    mydata:rxnifavailable ?rxnifavailable ;
    mydata:relative_boosted ?relative_boosted .
    bind(substr(str(?rfres), 45, 1) as ?rmuchunk)
    filter(substr(str(?rfres), 45, 1) = '",
    current.dig,
    "')
  }
}
")
  time.start <-  Sys.time()
  print(time.start)
  my.result <-
    sparql.remote(endpoint = sparql.endpoint,
                  sparql = my.query,
                  jena = TRUE)
  time.stop <-  Sys.time()
  time.duration <- time.stop - time.start
  print(time.duration)
  print(nrow(my.result))
  return(as_tibble(my.result))
})
rfpred.rxns <- do.call(rbind.data.frame, rfpred.rxns)
nrow(rfpred.rxns)

print(length(unique(rfpred.rxns$rfres)))

###   ###   ###

turbo.rxns.aggregation <- left_join(from.pds, pds.to.rfpred)
turbo.rxns.aggregation <-
  turbo.rxns.aggregation[, setdiff(colnames(turbo.rxns.aggregation), "rmuchunk")]
turbo.rxns.aggregation <-
  left_join(turbo.rxns.aggregation, rfpred.rxns)
turbo.rxns.aggregation <-
  turbo.rxns.aggregation[, setdiff(colnames(turbo.rxns.aggregation), "rmuchunk")]
turbo.rxns.aggregation <-
  turbo.rxns.aggregation[, c("R_MEDICATION_URI", "rxnifavailable")]
setDT(turbo.rxns.aggregation)
turbo.rxns.aggregation <-
  turbo.rxns.aggregation[, .(rxnifavailable = paste(rxnifavailable, collapse = ";")), by = R_MEDICATION_URI]

system.time(tidied.col <-
              sapply(turbo.rxns.aggregation$rxnifavailable, function(current.rxns) {
                temp <- unlist(strsplit(current.rxns, ";")[1])
                temp <-
                  gsub(pattern = "rxnorm:", replacement = "", temp)
                temp <- sort(as.numeric(setdiff(temp, "NA")))
                if (length(temp) > 0) {
                  return(paste0(temp, collapse = ";"))
                }
              }))
tidied.col <- as.character(tidied.col)

turbo.rxns.aggregation$rxnifavailable <- tidied.col

turbo.rxns.aggregation$rxnifavailable[turbo.rxns.aggregation$rxnifavailable == "NULL"] <-
  NA

dim(turbo.rxns.aggregation)
print(length(unique(
  turbo.rxns.aggregation$R_MEDICATION_URI
)))

# 3 minutes /  1 million

###   ###   ###

best.terms <- lapply(hexdigs, function(current.dig) {
  print(current.dig)
  my.query <- paste0(
    "
PREFIX mydata: <http://example.com/resource/>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
#PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
?rfres ?rmuchunk ?solrMatchTerm ?rxnifavailable ?rxnlab
where {
  graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
    ?rfres a mydata:rfres ;
    mydata:relative_boosted '1'^^xsd:float ;
    mydata:solrMatchTerm ?solrMatchTerm .
    bind(substr(str(?rfres), 45, 1) as ?rmuchunk)
    filter(substr(str(?rfres), 45, 1) = '",
    current.dig,
    "')
  }
  optional {
    graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
      ?rfres mydata:rxnifavailable ?rxnifavailable .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
      ?rxnifavailable skos:prefLabel ?rxnlab
    }
  }
}
")
  time.start <-  Sys.time()
  print(time.start)
  my.result <-
    sparql.remote(endpoint = sparql.endpoint,
                  sparql = my.query,
                  jena = TRUE)
  time.stop <-  Sys.time()
  time.duration <- time.stop - time.start
  print(time.duration)
  print(nrow(my.result))
  return(as_tibble(my.result))
})

best.terms <- do.call(rbind.data.frame, best.terms)

nrow(best.terms)

print(length(unique(best.terms$R_MEDICATION_URI)))

best.terms <- unique(best.terms)

nrow(best.terms)

print(length(unique(best.terms$R_MEDICATION_URI)))

setDT(best.terms)

best.terms.term.aggregation <-
  best.terms[, .(solrMatchTerm = paste(solrMatchTerm, collapse = ";")), by = R_MEDICATION_URI]

best.terms.rxn.aggregation <-
  best.terms[, .(turbo_best_rxn = paste(turbo_best_rxn, collapse = ";")), by = R_MEDICATION_URI]

best.terms.rxnlab.aggregation <-
  best.terms[, .(rxnlab = paste(rxnlab, collapse = ";")), by = R_MEDICATION_URI]

best.terms.aggregation <-
  cbind.data.frame(
    best.terms.term.aggregation$R_MEDICATION_URI,
    best.terms.term.aggregation$solrMatchTerm,
    best.terms.rxn.aggregation$turbo_best_rxn,
    best.terms.rxnlab.aggregation$rxnlab,
    stringsAsFactors = FALSE
  )

names(best.terms.aggregation) <-
  c("R_MEDICATION_URI",
    "solrMatchTerm",
    "turbo_best_rxn",
    "rxnlab")

nrow(best.terms.aggregation)

print(length(unique(
  best.terms.aggregation$R_MEDICATION_URI
)))

# still need to remove NAs, rxnorm URIs base portion?
# keep linkage between terms

# system.time(tidied.col <-
#               sapply(best.terms.aggregation$turbo_best_rxn, function(current.rxns) {
#                 temp <- unlist(strsplit(current.rxns, ";")[1])
#                 temp <-
#                   gsub(pattern = "http://purl.bioontology.org/ontology/RXNORM/", replacement = "", temp)
#                 temp <- setdiff(temp, "NA")
#                 if (length(temp) > 0) {
#                   return(paste0(temp, collapse = ";"))
#                 }
#               }))
#
# best.terms.aggregation$turbo_best_rxn <- as.character(tidied.col)

###   ###   ###

terms.aggregation <-
  full_join(turbo.rxns.aggregation, best.terms.aggregation)
dim(terms.aggregation)
print(length(unique(terms.aggregation$R_MEDICATION_URI)))

stopping.point <- left_join(from.pds, terms.aggregation)

dim(stopping.point)
print(length(unique(stopping.point$R_MEDICATION_URI)))

PK_MEDICATION_ID
FULL_NAME.mdm
SOURCE_CODE
RXNORM_CODEs_pds
rxnvals_turbo
bestterm_turbo
bestrxn_turbo
bestrxn_lab_turbo

stopping.point <-
  stopping.point[, c(
    "PK_MEDICATION_ID" ,
    "R_MEDICATION_URI",
    "FULL_NAME",
    "SOURCE_CODE",
    "pds_rxn_val",
    "RXNORM_CODE_URI_active",
    "rxnifavailable",
    "solrMatchTerm",
    "turbo_best_rxn",
    "rxnlab"
  )]

colnames(stopping.point) <-
  c(
    "PK_MEDICATION_ID" ,
    "R_MEDICATION_URI",
    "FULL_NAME",
    "SOURCE_CODE",
    "RXNORM_CODEs_pds",
    "RXNORM_CODEs_pds_active",
    "rxnvals_turbo",
    "bestterm_turbo",
    "bestrxn_turbo",
    "bestrxn_lab_turbo"
  )


write_csv(stopping.point, path = "/terabyte/med_map_general_report_20190501.csv")
