# set the working directory to medication-knowledgegraph-pipeline/pipeline
# for example,
# setwd("~/GitHub/medication-knowledgegraph-pipeline/pipeline")

# get global settings, functions, etc. from https://raw.githubusercontent.com/PennTURBO/turbo-globals

# some people (https://www.r-bloggers.com/reading-an-r-file-from-github/)
# say it’s necessary to load the devtools package before sourcing from GitHub?
# but the raw page is just a http-accessible page of text, right?

# requires a properly formatted "turbo_R_setup.yaml" in medication-knowledgegraph-pipeline/config
# or better yet, a symbolic link to a centrally loated "turbo_R_setup.yaml", which could be used by multiple pipelines
# see https://github.com/PennTURBO/turbo-globals/blob/master/turbo_R_setup.template.yaml

source(
  "https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup.R"
)

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

####

library(gtools)

more.pages <- NA
current.page <- NA
next.page <- NA
my.page.count <- NA
aggregated.mapping <- data.frame()

bp.mappings.pair.to.minimal.df <- function(from.ont, to.ont) {
  # initialize global variables for while loop
  
  more.pages <<- TRUE
  aggregated.mapping <<- data.frame()
  
  # from.ont <- 'CHEBI'
  # to.ont <- 'DRON'
  
  current.page <<- 1
  next.page <<- 0
  my.page.count <<- NA
  
  while (more.pages) {
    print(paste0('Searching ', from.ont, ' against ', to.ont))
    
    print(paste0('page ',
                 current.page,
                 ' of ',
                 my.page.count,
                 ' pages'))
    
    pair.uri <-
      paste0(
        config$my.bioportal.api.base,
        '/mappings?ontologies=',
        from.ont,
        ',',
        to.ont,
        '&apikey=',
        config$my.apikey,
        '&pagesize=',
        config$my.pagesize,
        '&page=',
        current.page
      )
    mappings.result <- httr::GET(pair.uri)
    mappings.result <- rawToChar(mappings.result$content)
    whole.prep.parse <- mappings.result
    
    mappings.result <- jsonlite::fromJSON(mappings.result)
    
    current.page <<- mappings.result$page
    next.page <<- mappings.result$nextPage
    my.page.count <<- mappings.result$pageCount
    
    mappings.result <- mappings.result$collection
    
    if (length(mappings.result) > 0) {
      mappings.result <-
        mappings.result$classes[mappings.result$source == 'LOOM']
      inner.res <-
        lapply(mappings.result, function(current.result) {
          # current.result <- mappings.result[[1]]
          current.ids <- current.result$`@id`
          current.ontologies <- current.result$links$ontology
          return(
            list(
              'source.term' = current.ids[[1]],
              'source.ontology' = current.ontologies[[1]],
              'mapped.term' = current.ids[[2]],
              'mapped.ontology' = current.ontologies[[2]]
            )
          )
        })
      
      inner.res <- do.call(rbind.data.frame, inner.res)
      inner.res <-
        inner.res[as.character(inner.res$source.term) != as.character(inner.res$mapped.term),]
      inner.res <-
        unique(inner.res[, c("source.term", "source.ontology", "mapped.term")])
      
      if (current.page >= my.page.count) {
        more.pages <- FALSE
      } else {
        current.page <- next.page
      }
      
      aggregated.mapping <<-
        rbind.data.frame(aggregated.mapping, inner.res)
    } else {
      print(paste0("no rows in collection from page ", current.page))
      print(whole.prep.parse)
      if (current.page >= my.page.count) {
        more.pages <- FALSE
      } else {
        current.page <- next.page
      }
    }
    
  }
  
  return(aggregated.mapping)
}

onto.combos <- combinations(
  n = length(config$my.source.ontolgies),
  r = 2,
  v = config$my.source.ontolgies,
  repeats.allowed = F
)

pair.results <-
  apply(
    X = onto.combos,
    MARGIN = 1,
    FUN = function(current_row) {
      print(current_row)
      inner.results <-
        bp.mappings.pair.to.minimal.df(current_row[[1]], current_row[[2]])
      return(inner.results)
    }
  )

bound.source.results <-
  do.call(rbind.data.frame, pair.results)
bound.source.results$inversed <- FALSE

inverse.results <- bound.source.results[, c(3, 2, 1, 4)]
colnames(inverse.results) <- colnames(bound.source.results)
inverse.results$inversed <- TRUE

bound.source.results <-
  unique(rbind.data.frame(bound.source.results, inverse.results))

bound.source.results$uuid <-
  uuid::UUIDgenerate(n = nrow(bound.source.results))

colnames(bound.source.results) <-
  gsub(
    pattern = ".",
    replacement = "_",
    x = colnames(bound.source.results),
    fixed = TRUE
  )

# # OOPS... doesn't consistently recognize IRIs
# # https://stackoverflow.com/questions/60853395/rdflibas-rdf-only-recognizes-some-iris
# # otherwise...
# # pretty fast
# # simplify after loading into graphdb?
# # really only care that X is mapped to Y, right?
# # otherwise, we should probablya ssert a type for these things
#
# per.source.results.rdf <-
#   rdflib::as_rdf(x = bound.source.results[1:2,c(1,2,4,5)],
#                  prefix = config$my.prefix,
#                  key = 'uuid')
# rdf_serialize(rdf = per.source.results.rdf, doc = config$bioportal.triples.destination)
#
# # http://pennturbo.org:7200
# # med_mapping
# # grep... see hayden's notes. for now use something like <>
# # bioportal_mappings

####

succinct <-
  unique(bound.source.results[, c("source_term", "mapped_term")])

direct.rdf <- rdf()

# only one minute for 83286 rows of 2 columns
print(Sys.time())
placeholder <-
  apply(
    X = succinct,
    MARGIN = 1,
    FUN = function(current.row) {
      # print(current.row[['source_term']])
      rdf_add(
        rdf = direct.rdf,
        subject = current.row[['source_term']],
        predicate = paste0('http://example.com/resource/',
                           config$bioportal.mapping.graph.name),
        object = current.row[['mapped_term']]
      )
    }
  )
print(Sys.time())

# really want to know the release dates/verions of tee included component
# in the mean time, could add the IP address of the BioPortal server that was queried?

tm <- as.POSIXlt(Sys.time(), "UTC", "%Y-%m-%dT%H:%M:%S")
tm <- strftime(tm , "%Y-%m-%dT%H:%M:%S%z")

rdf_add(
  rdf = direct.rdf,
  subject = paste0('http://example.com/resource/',
                   config$bioportal.mapping.graph.name),
  predicate = "http://www.w3.org/2002/07/versionInfo",
  object = tm
)

lapply(config$my.source.ontolgies, function(current.source) {
  # current.source <- "RXNORM"
  print(current.source)
  temp <-
    paste0(
      "http://data.bioontology.org/ontologies/",
      current.source,
      "/latest_submission?apikey=",
      config$my.apikey
    )
  temp <- httr::GET(temp)
  temp <- rawToChar(temp$content)
  temp <- fromJSON(temp)
  
  
  rdf_add(
    rdf = direct.rdf,
    subject = paste0(
      'http://example.com/resource/',
      config$bioportal.mapping.graph.name
    ),
    predicate = "http://purl.org/dc/terms/source",
    object = temp[['@id']]
  )
  
  print(temp[['@id']])
  
})

####

rdf_serialize(rdf = direct.rdf,
              doc = config$bioportal.triples.destination)

####

post.dest <-
  paste0(
    config$my.graphdb.base,
    '/repositories/',
    config$my.selected.repo,
    '/rdf-graphs/service?graph=',
    URLencode(
      paste0('http://example.com/resource/',
             config$bioportal.mapping.graph.name),
      reserved = TRUE
    )
  )

print(post.dest)

print(Sys.time())

post.resp <-
  httr::POST(
    url = post.dest,
    body = upload_file(config$bioportal.triples.destination),
    content_type(config$my.mappings.format),
    authenticate(
      config$my.graphdb.username,
      config$my.graphdb.pw,
      type = 'basic'
    )
  )

print('Errors will be listed below:')
print(rawToChar(post.resp$content))

