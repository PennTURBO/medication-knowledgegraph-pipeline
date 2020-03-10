options(java.parameters = "-Xmx32g")
# options(java.parameters = "-Xmx8g")
library(rrdf)

my.repo <- "med_map_support_20180403"

sparql.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo)

# my.q <- '
# PREFIX mydata: <http://example.com/resource/>
# PREFIX j.0: <http://example.com/resource/>
# PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
# PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
# select ?R_MEDICATION ?RF_PRED ?prob_of_prediction
# where {
#     graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
#         ?R_MEDICATION rdf:type	j.0:Row ;
#                       j.0:FULL_NAME ?FULL_NAME ;
#                       optional {
#             ?R_MEDICATION mydata:RXNORM ?PDS_RXNORM
#         }
#     }
#     graph <http://example.com/resource/mdm_ods_meds_source_supplement> {
#         ?R_MEDICATION  j.0:SOURCE_CODE ?SOURCE_CODE
#     }
#     optional {
#         graph <http://example.com/resource/med_map_rf_pred_with_pds_rxn> {
#             ?RF_PRED mydata:R_MEDICATION_URI ?R_MEDICATION ;
#                      mydata:solrMatchTerm ?solrMatchTerm ;
#                      mydata:max_useful_prob	?prob_of_prediction ;
#                      j.0:FALSE_FALSE_FALSE_TRUE ?FALSE_FALSE_FALSE_TRUE  .
#             bind(xsd:string(?solrMatchTerm) as ?solrMatchString)
#         }
#         graph mydata:underscored_mydata_proximities {
#             ?RF_PRED j.0:rf_predicted_proximity  ?rf_predicted_proximity ;
#                      }
#         optional {
#             graph <http://example.com/resource/med_map_rf_pred_with_pds_rxn> {
#                 ?RF_PRED mydata:rxnifavailable ?rxnifavailable
#                 bind(replace(xsd:string(?rxnifavailable),"http://purl.bioontology.org/ontology/RXNORM/", "") as  ?rxnifavailableString)
#             }
#         }
#     }
# }'

my.q <- '
PREFIX mydata: <http://example.com/resource/>
select ?R_MEDICATION_URI (max(?max_useful_prob) as ?max) where {
        graph <http://example.com/resource/med_map_rf_pred_with_pds_rxn> {
        ?s mydata:R_MEDICATION_URI ?R_MEDICATION_URI ;
           mydata:max_useful_prob ?max_useful_prob .
    }
}
group by ?R_MEDICATION_URI
'

my.res <-
  as.data.frame(sparql.remote(
    endpoint = sparql.endpoint,
    sparql = my.q,
    jena = TRUE
  ))

my.res$max <- as.numeric(as.character(my.res$max))

head(my.res$max)


hist(as.numeric(as.character(my.res$max)), breaks = 99)
