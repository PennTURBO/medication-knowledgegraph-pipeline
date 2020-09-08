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

# try instantiating med maping RESULTS  with rdflib::as_rdf instead of robot?

####

# I've been using this with a same-host
# bioportal virtual appliance
# there's no error checking in place
# might want to give other users the option for skipping the graphdb upload,
# like jsut saving the triples and or the dataframe

# # uploading/posting options
# POST /rest/data/import/server/{repositoryID}
# Import a server FILE into the repository
#
# POST /rest/data/import/upload/{repositoryID}/url
# Import from data URL into the repository

### using this, and puting a file in the body
# POST /repositories/{repositoryID}/rdf-graphs/{graph}
# Add STATEMENTS to a directly referenced named graph

####

# config <- config::get(file = "rxnav_med_mapping.yaml")

more.pages <- NA
current.page <- NA
next.page <- NA
my.page.count <- NA
aggregated.mapping <- data.frame()

bp.mappings.to.minimal.df <- function(current.source.ontology) {
  # initialize global variables for while loop
  
  more.pages <<- TRUE
  aggregated.mapping <<- data.frame()
  
  # current.source.ontology <- "CHEBI"
  # current.source.ontology <- "DRON"
  
  # current.source.ontology <- "RXNORM"
  
  current.page <<- 1
  next.page <<- 0
  my.page.count <<- 0
  
  # current.page <<- 
  # next.page <<- 
  # my.page.count <<- 
  
  value.added <-
    setdiff(config$relevant.ontologies, current.source.ontology)
  
  print(paste0('Searching ', current.source.ontology, ' against: '))
  print(sort(value.added))
  
  value.added <-
    paste0(config$my.bioportal.api.base,
           '/ontologies/',
           value.added)
  
  while (more.pages) {
    print(
      paste0(
        current.source.ontology,
        ': page ',
        current.page,
        ' of ',
        my.page.count,
        ' pages'
      )
    )
    
    source.class.uri <-
      paste0(
        config$my.bioportal.api.base,
        '/ontologies/',
        current.source.ontology,
        '/mappings?apikey=',
        config$my.apikey,
        '&pagesize=',
        config$my.pagesize,
        '&page=',
        current.page
      )
    mappings.result <- httr::GET(source.class.uri)
    mappings.result <- rawToChar(mappings.result$content)
    whole.prep.parse <- mappings.result
    
    mappings.result <- jsonlite::fromJSON(mappings.result)
    
    current.page <<- mappings.result$page
    next.page <<- mappings.result$nextPage
    my.page.count <<- mappings.result$pageCount
    
    mappings.result <- mappings.result$collection
    
    if (length(mappings.result) > 0) {
      mappings.result.source.methods <- mappings.result$source
      
      mappings.result <- mappings.result$classes
      
      inner.res <-
        lapply(mappings.result, function(current.result) {
          current.ids <- current.result$`@id`
          # print(current.ids)
          current.ontologies <- current.result$links$ontology
          # print(current.ontologies)
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
      inner.res$source.method <- mappings.result.source.methods
      inner.res <- inner.res[inner.res$source.method == 'LOOM' ,]
      inner.res <-
        inner.res[as.character(inner.res$source.term) != as.character(inner.res$mapped.term), ]
      inner.res <-
        inner.res[inner.res$mapped.ontology %in% value.added , ]
      inner.res <-
        unique(inner.res[, c("source.term", "source.ontology", "mapped.term")])
      
      if (current.page == my.page.count) {
        more.pages <- FALSE
      } else {
        current.page <- next.page
      }
      
      aggregated.mapping <<-
        rbind.data.frame(aggregated.mapping, inner.res)
    } else {
      print(paste0("no rows in collection from page ", current.page))
      print(whole.prep.parse)
      current.page <<- current.page + 1
      next.page <<- next.page + 1
    }
    
  }
  
  return(aggregated.mapping)
}

no.dron.temp <- setdiff(config$my.source.ontolgies, "DRON")

per.source.results <-
  lapply(sort(no.dron.temp), function(current.outer) {
    temp <- bp.mappings.to.minimal.df(current.outer)
    return(temp)
  })

####

bound.source.results <-
  do.call(rbind.data.frame, per.source.results)
bound.source.results$inversed <- FALSE

inverse.results <- bound.source.results[, c(3, 2, 1, 4)]
colnames(inverse.results) <- colnames(bound.source.results)
inverse.results$inversed <- TRUE

bound.source.results <-
  rbind.data.frame(bound.source.results, inverse.results)

# bound.source.results$source.term <-
#   paste0('<', bound.source.results$source.term , '>')
# bound.source.results$source.ontology <-
#   paste0('<', bound.source.results$source.ontology , '>')
# bound.source.results$mapped.term <-
#   paste0('<', bound.source.results$mapped.term , '>')

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
        predicate = "http://example.com/resource/bioportal_mapping",
        object = current.row[['mapped_term']]
      )
    }
  )
print(Sys.time())

####

rdf_serialize(rdf = direct.rdf,
              doc = config$bioportal.triples.destination)


####

# erroring out of searches from DRON
# only doing 10 pages from the others
# results ~ 0.1 x previous


####

post.dest <-
  paste0(
    config$my.graphdb.base,
    '/repositories/',
    config$my.selected.repo,
    '/rdf-graphs/service?graph=',
    URLencode(
      paste0('http://example.com/resource/',
             config$my.selected.graph),
      reserved = TRUE
    )
  )

print(post.dest)

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
