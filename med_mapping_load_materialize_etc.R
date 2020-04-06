library(config)
library(jsonlite)
library(httr)

source("rxnav_med_mapping_setup.R")

med.mapping.general.config <-
  config::get(file = 'rxnav_med_mapping.yaml')

# load public ontologies & RDF data sets
# inspired by disease_diagnosis_dev.R
# more refactoring (even pacage writing) opportunities

####

### upload from file if upload from uri might fail
# the name of the destination graph is part of the "endpoint URL"

####

# # probably don't really need dron_chebi or dron_pro?

import.urls <- med.mapping.general.config$my.import.urls
import.names <- names(import.urls)
context.report <- get.context.report()
import.names <- setdiff(import.names, context.report)

placeholder <-
  lapply(import.names, function(some.graph.name) {
    some.ontology.url <- import.urls[[some.graph.name]]$url
    some.rdf.format <- import.urls[[some.graph.name]]$format
    import.from.url(some.graph.name,
                    some.ontology.url,
                    some.rdf.format)
  })

import.files <- med.mapping.general.config$my.import.files
import.names <- names(import.files)
context.report <- get.context.report()
import.names <- setdiff(import.names, context.report)

placeholder <-
  lapply(import.names, function(some.graph.name) {
    # some.graph.name <- import.names[[1]]
    some.ontology.file <- import.files[[some.graph.name]]$local.file
    some.rdf.format <- import.files[[some.graph.name]]$format
    import.from.local.file(some.graph.name,
                           some.ontology.file,
                           some.rdf.format)
  })

# need to wait for imports to finish

# dput(sort(context.report))
# c("http://example.com/resource/bioportal_mappings", "http://example.com/resource/classified_search_results",
#   "http://example.com/resource/reference_medications", "http://purl.bioontology.org/ontology/ATC/",
#   "http://purl.bioontology.org/ontology/RXNORM/", "http://purl.bioontology.org/ontology/VANDF/",
#   "http://purl.obolibrary.org/obo/chebi.owl", "http://purl.obolibrary.org/obo/dron-rxnorm.owl",
#   "http://purl.obolibrary.org/obo/dron.owl", "http://purl.obolibrary.org/obo/dron/dron-hand.owl",
#   "http://purl.obolibrary.org/obo/dron/dron-ingredient.owl", "http://purl.obolibrary.org/obo/dron/dron-upper.owl",
#   "https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl"
# )

last.post.status <-
  'Multiple OBO and BioPortal/UMLS uploads from URLs '
last.post.time <- Sys.time()

expectation <- import.names

monitor.named.graphs()

# when to associate BioPortal-mapped ChEBI, DrOn and RxNorm terms
# before any kind of propagation, right

sparql.list <-
  med.mapping.general.config$materializastion.projection.sparqls

placeholder <-
  lapply(names(sparql.list), function(current.sparql.name) {
    print(current.sparql.name)
    innner.sparql <- sparql.list[[current.sparql.name]]
    cat(innner.sparql)
    cat('\n\n')
    
    post.res <- POST(update.endpoint,
                     body = list(update = innner.sparql),
                     saved.authentication)
  })

####

my.query <- "
SELECT
RXCUI, TTY
from
rxnorm_current.RXNCONSO r
where
SAB = 'RXNORM'"

print(Sys.time())
timed.system <- system.time(rxcui_ttys <-
                              dbGetQuery(rxnCon, my.query))
print(Sys.time())
print(timed.system)

# Close connection
dbDisconnect(rxnCon)

rxcui_ttys$placeholder <- 1

rxcui.tab <- table(rxcui_ttys$RXCUI)
rxcui.tab <-
  cbind.data.frame(names(rxcui.tab), as.numeric(rxcui.tab))
names(rxcui.tab) <- c("RXCUI", "TTY.entries")

tty.tab <- table(rxcui_ttys$TTY)
tty.tab <-
  cbind.data.frame(names(tty.tab), as.numeric(tty.tab))
names(tty.tab) <- c("TTY", "RXCUI.entries")

write.csv(x = tty.tab,
          file = 'rxn_tty_table.csv',
          row.names = FALSE)

# BN
# BPCK
# GPCK
# IN
# MIN
# PIN
# SBD
# SBDC
# SBDF
# SBDG
# SCD
# SCDC
# SCDF
# SCDG


# DF
# DFG
# ET
# PSN
# SY
# TMSY

# SAB = 'RXNORM' and RXCUI  = '1119573'

one.per <-
  rxcui_ttys[rxcui_ttys$TTY %in% c(
    'BN',
    'BPCK',
    'GPCK',
    'IN',
    'MIN',
    'PIN',
    'SBD',
    'SBDC',
    'SBDF',
    'SBDG',
    'SCD',
    'SCDC',
    'SCDF',
    'SCDG'
  ), c('RXCUI', 'TTY')]

one.per.tab <- table(one.per$RXCUI)
one.per.tab <-
  cbind.data.frame(names(one.per.tab), as.numeric(one.per.tab))
names(one.per.tab) <- c("RXCUI", "TTY.entries")

print(table(one.per.tab$TTY.entries))

# http://purl.bioontology.org/ontology/RXNORM/
# http://example.com/resource/
# http://www.w3.org/1999/02/22-rdf-syntax-ns#type

one.per$RXCUI <-
  paste0('http://purl.bioontology.org/ontology/RXNORM/',
         one.per$RXCUI)

one.per$TTY <-
  paste0('http://example.com/resource/rxn_tty/', one.per$TTY)

as.rdf <- as_rdf(x = one.per)
rdf_serialize(rdf = as.rdf, doc = 'rxcui_ttys.ttl', format = 'turtle')


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp/>'),
  saved.authentication
)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty/>'),
  saved.authentication
)


placeholder <-
  import.from.local.file('http://example.com/resource/rxn_tty_temp/',
                         'rxcui_ttys.ttl',
                         'text/turtle')

rxn.tty.update <- 'insert {
graph <http://example.com/resource/rxn_tty/> {
?ruri a ?turi .
}
}
where {
graph <http://example.com/resource/rxn_tty_temp/> {
?s <df:RXCUI> ?r ;
<df:TTY> ?t .
bind(iri(?r) as ?ruri)
bind(iri(?t) as ?turi)
}
}'

# Added 203754 statements. Update took 16s, moments ago.

post.res <- POST(update.endpoint,
                 body = list(update = rxn.tty.update),
                 saved.authentication)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp/>'),
  saved.authentication
)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/classified_search_results>'),
  saved.authentication
)


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/materialized_rxcui>'),
  saved.authentication
)


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/cui>'),
  saved.authentication
)


####

# ### Solr prerequisities
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



