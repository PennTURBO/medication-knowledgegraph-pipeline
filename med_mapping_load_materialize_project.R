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

