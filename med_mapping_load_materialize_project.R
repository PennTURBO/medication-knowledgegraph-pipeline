library(config)

med.mapping.general.config <-
  config::get(file = 'rxnav_med_mapping.yaml')
# bioportal.mapping.graphdb.config <-
#   config::get(file = 'get_bioportal_mappings.yaml')

# load public ontologies & RDF data sets
# use this stuff (inspired by disease_diagnosis_dev.R)

url.post.endpoint <-
  paste0(
    med.mapping.general.config$my.graphdb.base,
    "/rest/data/import/upload/",
    med.mapping.general.config$my.selected.repo,
    "/url"
  )

update.endpoint <-
  paste0(
    med.mapping.general.config$my.graphdb.base,
    "/repositories/",
    med.mapping.general.config$my.selected.repo,
    "/statements"
  )

saved.authentication <-
  authenticate(
    med.mapping.general.config$my.graphdb.username,
    med.mapping.general.config$my.graphdb.pw,
    type = "basic"
  )

# # probably don't really need dron_chebi
# # or dron_pro?

import.urls <- med.mapping.general.config$my.import.urls
import.names <- names(import.urls)

placeholder <-
  lapply(import.names, function(current.ontology.name) {
    current.ontology.url <- import.urls[[current.ontology.name]]$url
    
    current.ontology.format <-
      import.urls[[current.ontology.name]]$format
    
    print(current.ontology.name)
    print(current.ontology.url)
    print(current.ontology.format)
    
    if (nchar(current.ontology.format) > 0) {
      update.body <- paste0(
        '{
        "context": "',
        current.ontology.name,
        '",
        "data": "',
        current.ontology.url,
        '",
        "format": "',
        current.ontology.format,
        '"
    }'
      )
    } else {
      update.body <- paste0(
        '{
        "context": "',
        current.ontology.name,
        '",
        "data": "',
        current.ontology.url,
        '"
    }'
      )
    }
    
    cat("\n")
    cat(update.body)
    cat("\n\n")
    
    post.res <- POST(
      url.post.endpoint,
      body = update.body,
      content_type("application/json"),
      accept("application/json"),
      saved.authentication
    )
    
    cat(rawToChar(post.res$content))
    
        })

# need to wait for imports to finish
# last.post.time <- Sys.time()
# last.post.status <- ''
#
# expectation <- NULL
#
# monitor.named.graphs()

# when to weed out classiifcatiosn that point to an undefined rxcui?

# when to associate bioportal-mapped chebi, dron and rxnorm terms
# before any kind of propigation, right


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

#  http://purl.obolibrary.org/obo/dron-rxnorm.owl not explicitly identified as an ontology

# will probabaly need materialized cuis for ndf-rt (as a placeho,der for med-rt, etc.)

# "transitive_massless_rolebearer"  could probably be refined... see http://purl.obolibrary.org/obo/CHEBI_10003

# what about salt forms, isomers, etc?
# conjugate acids/bases and has-part relatons may be useful

# my.import.urls: {"http://purl.bioontology.org/ontology/MESH/":{"url":["http://data.bioontology.org/ontologies/MESH/submissions/19/download?apikey=9cf735c3-a44a-404f-8b2f-c49d48b2b8b2"],
#   "format":["text/turtle"]}}