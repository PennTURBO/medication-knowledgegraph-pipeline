library(config)
library(jsonlite)
library(httr)

med.mapping.general.config <-
  config::get(file = 'rxnav_med_mapping.yaml')

# load public ontologies & RDF data sets
# inspired by disease_diagnosis_dev.R
# more refactoring (even pacage writing) opportunities

####

### upload from file if upload from uri might fail
# the name of the destination graph is part of the "endpoint URL"

import.from.local.file <-
  function(some.graph.name,
           some.local.file,
           some.rdf.format) {
    print(some.graph.name)
    print(some.local.file)
    print(some.rdf.format)
    post.dest <-
      paste0(
        med.mapping.general.config$my.graphdb.base,
        '/repositories/',
        med.mapping.general.config$my.selected.repo,
        '/rdf-graphs/service?graph=',
        some.graph.name
      )
    
    print(post.dest)
    
    post.resp <-
      httr::POST(
        url = post.dest,
        body = upload_file(some.local.file),
        content_type(some.rdf.format),
        authenticate(
          med.mapping.general.config$my.graphdb.username,
          med.mapping.general.config$my.graphdb.pw,
          type = 'basic'
        )
      )
    
    print('Errors will be listed below:')
    print(rawToChar(post.resp$content))
  }

import.from.url <-   function(some.graph.name,
                              some.ontology.url,
                              some.rdf.format) {
  print(some.graph.name)
  print(some.ontology.url)
  print(some.rdf.format)
  
  if (nchar(some.rdf.format) > 0) {
    update.body <- paste0(
      '{
      "context": "',
      some.graph.name,
      '",
      "data": "',
      some.ontology.url,
      '",
      "format": "',
      some.rdf.format,
      '"
  }'
    )
  } else {
    update.body <- paste0('{
                          "context": "',
                          some.graph.name,
                          '",
                          "data": "',
                          some.ontology.url,
                          '"
  }')
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
  
    }

get.context.report <- function() {
  context.report <- GET(
    url = paste0(
      med.mapping.general.config$my.graphdb.base,
      "/repositories/",
      med.mapping.general.config$my.selected.repo,
      "/contexts"
    ),
    saved.authentication
  )
  context.report <-
    jsonlite::fromJSON(rawToChar(context.report$content))
  context.report <-
    context.report$results$bindings$contextID$value
  return(context.report)
}

monitor.named.graphs <- function() {
  while (TRUE) {
    print(paste0(
      Sys.time(),
      ": '",
      last.post.status,
      "' submitted at ",
      last.post.time
    ))
    
    context.report <- get.context.report()
    
    pending.graphs <- sort(setdiff(expectation, context.report))
    
    # will this properly handle the case when the report is empty (NULL)?
    if (length(pending.graphs) == 0) {
      print("Update complete")
      break()
    }
    
    print(paste0("still waiting for: ", pending.graphs))
    
    print(
      paste0(
        "Next check in ",
        med.mapping.general.config$monitor.pause.seconds,
        " seconds."
      )
    )
    
    Sys.sleep(med.mapping.general.config$monitor.pause.seconds)
    
  }
}

####

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


###


saved.authentication <-
  authenticate(
    med.mapping.general.config$my.graphdb.username,
    med.mapping.general.config$my.graphdb.pw,
    type = "basic"
  )

####

# # probably don't really need dron_chebi
# # or dron_pro?

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

dput(sort(context.report))
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
# expectation <- c("http://purl.bioontology.org/ontology/RXNORM/","http://purl.bioontology.org/ontology/NDFRT/")

expectation <- import.names

monitor.named.graphs()

# when to weed out classifications that point to an undefined RxCUI?

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

#  http://purl.obolibrary.org/obo/dron-rxnorm.owl not explicitly identified as an ontology

# "transitive_massless_rolebearer"  could probably be refined... see http://purl.obolibrary.org/obo/CHEBI_10003

# what about salt forms, isomers, etc.?
# conjugate acids/bases and has-part relations may be useful

# Mesh has some good relations but may be too large
# my.import.urls: {"http://purl.bioontology.org/ontology/MESH/":{"url":["http://data.bioontology.org/ontologies/MESH/submissions/19/download?apikey=9cf735c3-a44a-404f-8b2f-c49d48b2b8b2"],
#   "format":["text/turtle"]}}

# National Drug File - Reference Terminology (NDFRT)
# National Drug File - Reference Terminology Public Inferred Edition, 2008_03_11
# Uploaded: 7/6/18
# classes
# 36,202
# Lots of useful object properties
# No BioPortal download… haven't had luck extracting with umls2rdf… same with med-rt

# Also in rxclass: https://rxnav.nlm.nih.gov/RxClassIntro.html

# Add locally generated snomed and/or old ndfrt?
