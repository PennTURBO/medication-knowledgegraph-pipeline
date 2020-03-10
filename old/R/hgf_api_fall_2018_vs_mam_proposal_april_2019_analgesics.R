library(solrium)
library(rrdf)
library(jsonlite)


###
user.input <- "analgesic"
###

# apply "expansions"?
# search actual R_MEDICATION fullnames?
# action for UMLS matches with no path to RxNorm or ChEBI?
# punctuation will be scrubbed out
# give use option to add ~ fuzzy operator?
# show Solr results in graph context, colored by number of R_MEDICATIONS?
# log unsuccessful queries!


solr.row.req <- 30

solr.endpoint <-
  SolrClient$new(host = "localhost")

solr.coll <- "guaranteed"

solr.endpoint$ping(solr.coll)

q.pre <- "labelContent:("
q.post <- ")"

my.repo <- "med_map_support_20180403"

sparql.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo)


### escaping or removal of charters with special meanings in HTTP or Solr
### removal of excessive whitespace... probably doesn't really help anything

tidied.query <-
  gsub(pattern = "^\\W+",
       replacement = "",
       x = user.input)

tidied.query <-
  gsub(pattern = "\\W+$",
       replacement = "",
       x = tidied.query)

tidied.query <-
  gsub(
    pattern = '\\',
    replacement = ' ',
    fixed = TRUE,
    x = tidied.query
  )

tidied.query <-
  gsub(pattern = "([/\\+\\&\\|\\!\\^\\~\\*\\?\\:\\(\\)\\{\\}])",
       replacement = "\\\\\\1",
       x = tidied.query)

tidied.query <-
  gsub(
    pattern = '"',
    replacement = '\\"',
    fixed = TRUE,
    x = tidied.query
  )


tidied.query <-
  gsub(
    pattern = '-',
    replacement = '\\-',
    fixed = TRUE,
    x = tidied.query
  )


tidied.query <-
  gsub(
    pattern = ']',
    replacement = '\\]',
    fixed = TRUE,
    x = tidied.query
  )

tidied.query <-
  gsub(
    pattern = '[',
    replacement = '\\[',
    fixed = TRUE,
    x = tidied.query
  )

tidied.query <- gsub(pattern = " +",
                     replacement = " ",
                     x = tidied.query)

tidied.query <-
  gsub(pattern = "\\s+",
       replacement = " ",
       x = tidied.query)

tidied.query <-
  gsub(
    pattern = "[)(:\\]\\[]",
    perl = TRUE,
    replacement = " ",
    x = tidied.query
  )

tidied.query <-
  gsub(
    pattern = "/",
    perl = TRUE,
    replacement = " ",
    x = tidied.query
  )

tidied.query <-
  gsub(pattern = "\\s+",
       replacement = " ",
       x = tidied.query)

built.query <-
  paste0(q.pre , tidied.query , q.post)

print(built.query)

solr.result <-
  solr.endpoint$search(
    solr.coll,
    params = list(q = built.query,
                  fl = "term,ontology,rxn,rxnMatchMeth,labelType,labelContent,score,gctui,combo_likely",
                  rows = solr.row.req)
  )

# allow user to select any term?
# but only search graph for RxNorm and ChEBI terms?
# what about UMLS terms that don't have a path to RxNorm or CHeBI
# also remember, not traversing ChEBI relations like has form, only RxNomr relations
# only using highest scoring proximity predication
# see graph idea above

### this R script requires manual intervention here
solr.selection <- "http://purl.obolibrary.org/obo/CHEBI_35480"
###

my.query <- paste0(
  "
PREFIX mydata: <http://example.com/resource/>
select distinct ?g ?FULL_NAME ?s 
where {
    # consolidate all of these relevant names graphs
    graph ?g {
        ?s mydata:inherits_from <",
  solr.selection,
  "> .
    }
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?s mydata:FULL_NAME ?FULL_NAME .
    }
}
order by (lcase( ?FULL_NAME ))
")

cat(my.query)

R_MEDICATiONS.for.term <-
  sparql.remote(endpoint = sparql.endpoint,
                sparql = my.query,
                jena = TRUE)

R_MEDICATiONS.for.term <- as.data.frame(R_MEDICATiONS.for.term)

###

hgf_api_analgesics <- fromJSON("/terabyte/hgf_api_analgesic_fullnames.json")
hgf_api_analgesics <- hgf_api_analgesics$resultsList

###

hgf_api_only <- setdiff(hgf_api_analgesics, R_MEDICATiONS.for.term$FULL_NAME)
# 23124
mam_proposal_only  <- setdiff(R_MEDICATiONS.for.term$FULL_NAME, hgf_api_analgesics)
# 7625
both <- intersect(R_MEDICATiONS.for.term$FULL_NAME, hgf_api_analgesics)
# 51396

hgf_api_only_frame <- for.graphdb[for.graphdb$MedicationName %in% hgf_api_only , ]

temp <- unique(hgf_api_only_frame[,c("R_MEDICATION_URI","ORDER_MED_count")])

hist(log10(temp$ORDER_MED_count), breaks = 99)

library(ggplot2)

ggplot(temp, aes(x=ORDER_MED_count)) + geom_histogram() + scale_x_log10()

temp <- table(temp$ORDER_MED_count)
temp <- cbind.data.frame(as.numeric(names(temp)), as.numeric(temp))
