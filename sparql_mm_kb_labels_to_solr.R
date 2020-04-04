source("rxnav_med_mapping_setup.R")

#### prerequisities
# $ ~/solr-8.4.1/bin/solr start
# *** [WARN] *** Your open file limit is currently 2560.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# *** [WARN] ***  Your Max Processes Limit is currently 5568.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# Waiting up to 180 seconds to see Solr running on port 8983 [-]
# Started Solr server on port 8983 (pid=33449). Happy searching!
#
# $ ~/solr-8.4.1/bin/solr create_core -c <config$med.map.kb.solr.host>

# create Solr client object
mm.kb.solr.client <-
  SolrClient$new(
    host = config$med.map.kb.solr.host,
    path = "search",
    port = config$med.map.kb.solr.port
  )

# could also ping it
print(mm.kb.solr.client)

# clear the core!
mm.kb.solr.client$delete_by_query(name = config$med.map.kb.solr.core, query = "*:*")

#### additional solr notes
# add synony resolution? or just trust that between the primary and alternative lables
# in dron chebi rxnorm atc and ndfrt, all the bases are covered?

#  give the different authorities different weights?

# delet core from command line:
# bin/solr delete -c med_mapping_labels
# Deleting core 'med_mapping_labels' using command:
#   http://localhost:8983/solr/admin/cores?action=UNLOAD&core=med_mapping_labels&deleteIndex=true&deleteDataDir=true&deleteInstanceDir=true

# ~ fuzzy operator in place... also consider edgengrams (in query and index parsers)

# mlt, facets, highlighting (prob not useful)
# cli$facet("med_mapping_labels", params = list(q="*:*", facet.field='temp_normlab_value'),
#           callopts = list(verbose = TRUE))


# many of the next steps take several minutes each

# refactor
# query medmapping repo for selected labels from selected graphs
med_labels <- httr::GET(
  url = paste0(
    config$my.graphdb.base,
    "/repositories/",
    config$my.selected.repo
  ),
  query = list(query = config$med.map.kb.solr.population.sparql),
  saved.authentication
)

# convert binary JSON SPARQL results to a minimal dataframe
med_labels <- jsonlite::fromJSON(rawToChar(med_labels$content))
med_labels <- med_labels$results$bindings
med_labels <-
  cbind.data.frame(med_labels$mediri$value,
                   med_labels$labelpred$value,
                   med_labels$medlabel$value,
                   med_labels$prefLabel$value)

# beautify column labels
temp <-
  gsub(pattern = '\\$value$',
       replacement = '',
       x = colnames(med_labels))
temp <- gsub(pattern = '^.*\\$',
             replacement = '',
             x = temp)
colnames(med_labels) <- temp

# post data frame from sparql label query to Solr core
mm.kb.solr.client$add(med_labels, config$med.map.kb.solr.core)


#

med_labels <- httr::GET(
  url = paste0(
    config$my.graphdb.base,
    "/repositories/",
    config$my.selected.repo
  ),
  query = list(query = config$chebi.synonym.solr.population.sparql),
  saved.authentication
)

# convert binary JSON SPARQL results to a minimal dataframe
med_labels <- jsonlite::fromJSON(rawToChar(med_labels$content))
med_labels <- med_labels$results$bindings

# keepers <- grepl(pattern = "value", x = )
med_labels <-
  cbind.data.frame(med_labels$mediri$value,
                   med_labels$labelpred$value,
                   med_labels$medlabel$value,
                   med_labels$prefLabel$value,
                   med_labels$source$value)

# beautify column labels
temp <-
  gsub(pattern = '\\$value$',
       replacement = '',
       x = colnames(med_labels))
temp <- gsub(pattern = '^.*\\$',
             replacement = '',
             x = temp)
colnames(med_labels) <- temp

# post data frame from sparql label query to Solr core
mm.kb.solr.client$add(med_labels, config$med.map.kb.solr.core)


