options(java.parameters = "-Xmx32g")
library(rrdf)
library(tibble)
library(readr)
library(dplyr)
# change mydata:Row to something more meaningful and update documentation
# make sure documentation is already updated for...
# instantiate order counts WITH PKs
# get metrics for r_medication usage by orders and vice versa
# review selah's options for mapping chop and uphs medications

distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051 <-
  read_csv(
    "/terabyte/distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051.csv"
  )
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

from.pds <- left_join(
  from.pds,
  distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051,
  by = "PK_MEDICATION_ID"
)

# no MDM.R_MEDICATION has more than 1 rxnorm
#
# SELECT
# PK_MEDICATION_ID,
# COUNT(RXNORM)
# FROM
# MDM.R_MEDICATION
# GROUP BY
# PK_MEDICATION_ID
# ORDER BY
# COUNT(RXNORM) DESC
#    optional {
#        graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
#            ?rfres a mydata:rfres ;
#                   mydata:R_MEDICATION_URI ?R_MEDICATION_URI ;
#                   mydata:solrMatchTerm ?solrMatchTerm ;
#                   mydata:rf_predicted_proximity ?rf_predicted_proximity ;
#                   mydata:max_useful_prob_by_med ?max_useful_prob_by_med ;
#                   mydata:max_useful_prob_by_row ?max_useful_prob_by_row ;
#                   mydata:relative_prob ?relative_prob ;
#                   mydata:boosted ?boosted ;
#                   mydata:max_boosted ?max_boosted ;
#                   mydata:relative_boosted ?relative_boosted .
#        }
#        optional {
#            graph mydata:rf_predictions_boosted_ordercounts_no_ffff_201904251619 {
#                ?rfres  mydata:rxnifavailable ?rxnifavailable
#            }
#            optional {
#                graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
#                    ?rxnifavailable skos:prefLabel ?rxnlab
#                }
#            }
#        }
#    }
