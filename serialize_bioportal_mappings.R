# I've been using this with a same-host
# bioportal virtual appliance
# there's no error checking in place

source("rxnav_med_mapping_setup.R")

my.config <- config::get(file = "rxnav_med_mapping.yaml")

more.pages <- NA
current.page <- NA
next.page <- NA
my.page.count <- NA
aggregated.mapping <- data.frame()


bp.mappings.to.minimal.df <- function(current.source.ontology) {
  # initialize global varaibles for while loop
  
  more.pages <<- TRUE
  current.page <<- 1
  next.page <<- 0
  my.page.count <<- 0
  aggregated.mapping <<- data.frame()
  
  value.added <-
    setdiff(my.config$relevant.ontologies, current.source.ontology)
  
  print(paste0('Searching ', current.source.ontology, ' against: '))
  print(sort(value.added))
  
  value.added <-
    paste0(my.config$my.bioportal.api.base,
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
        my.config$my.bioportal.api.base,
        '/ontologies/',
        current.source.ontology,
        '/mappings?apikey=',
        my.config$my.apikey,
        '&pagesize=',
        my.config$my.pagesize,
        '&page=',
        current.page
      )
    mappings.result <- httr::GET(source.class.uri)
    mappings.result <- rawToChar(mappings.result$content)
    mappings.result <- jsonlite::fromJSON(mappings.result)
    
    current.page <<- mappings.result$page
    next.page <<- mappings.result$nextPage
    my.page.count <<- mappings.result$pageCount
    
    mappings.result <- mappings.result$collection
    
    mappings.result.source.methods <- mappings.result$source
    
    mappings.result <- mappings.result$classes
    
    inner.res <- lapply(mappings.result, function(current.result) {
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
    inner.res <-
      inner.res[inner.res$source.method %in% my.config$aceepted.mapping.sources ,]
    inner.res <-
      inner.res[as.character(inner.res$source.term) != as.character(inner.res$mapped.term), ]
    inner.res <-
      inner.res[inner.res$mapped.ontology %in% value.added , ]
    inner.res <-
      unique(inner.res[, c("source.term",
                           "source.ontology",
                           "mapped.term",
                           "source.method")])
    
    if (current.page == my.page.count) {
      more.pages <- FALSE
    } else {
      current.page <- next.page
    }
    
    aggregated.mapping <<-
      rbind.data.frame(aggregated.mapping, inner.res)
    
  }
  
  return(aggregated.mapping)
}

per.source.results <-
  lapply(sort(my.config$my.source.ontolgies), function(current.outer) {
    temp <- bp.mappings.to.minimal.df(current.outer)
    return(temp)
  })

####

bound.source.results <-
  do.call(rbind.data.frame, per.source.results)
bound.source.results$inversed <- FALSE

inverse.results <- bound.source.results[, c(3, 2, 1, 4, 5)]
colnames(inverse.results) <- colnames(bound.source.results)
inverse.results$inversed <- TRUE

bound.source.results <-
  rbind.data.frame(bound.source.results, inverse.results)

# # some tools like ROBOT need IRIs that are already wrapped in angle backets
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

# # OOPS the efficient "rdflib::as_rdf" doesn’t consistently recognize IRIs
# # https://stackoverflow.com/questions/60853395/rdflibas-rdf-only-recognizes-some-iris
# # otherwise it's pretty fast
# # it creates reified datastructures (mappings)
# # that could be simplified after loading into GraphDB
# # we really only care that X is mapped to Y, right?
# # otherwise, we should probably assert a type for these things
#
# per.source.results.rdf <-
#   rdflib::as_rdf(x = bound.source.results[1:2,c(1,2,4,5)],
#                  prefix = my.config$my.prefix,
#                  key = 'uuid')
# rdf_serialize(rdf = per.source.results.rdf, doc = my.config$my.triples.destination)


####

# could save bound.source.results, including source methods, to csv here

succinct <-
  unique(bound.source.results[, c("source_term", "mapped_term")])

succinct$source_term <- as.character(succinct$source_term)
succinct$mapped_term <- as.character(succinct$mapped_term)

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

rdf_serialize(rdf = direct.rdf,
              doc = my.config$bioportal.triples.destination)
