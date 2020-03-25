library(httr)
library(jsonlite)
library(config)

# try instantiating med maping RESULTS  with rdflib::as_rdf

####

my.config <- config::get(file = "bioportal_mapping.yaml")

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
  print(value.added)
  
  value.added <-
    paste0(my.config$my.base, '/ontologies/', value.added)
  
  
  
  # current.source.ontology <- 'DRON'
  
  while (more.pages) {
    # current.page <- 1
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
        my.config$my.base,
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
    inner.res <- inner.res[inner.res$source.method == 'LOOM' , ]
    inner.res <-
      inner.res[as.character(inner.res$source.term) != as.character(inner.res$mapped.term),]
    inner.res <-
      inner.res[inner.res$mapped.ontology %in% value.added ,]
    inner.res <-
      unique(inner.res[, c("source.term", "source.ontology", "mapped.term")])
    
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
  lapply(my.config$my.source.ontolgies, function(current.outer) {
    temp <- bp.mappings.to.minimal.df(current.outer)
    return(temp)
  })

per.source.results <- do.call(rbind.data.frame, per.source.results)
per.source.results$inverse <- FALSE

inverse.results <- per.source.results[, c(3, 2, 1, 4)]
colnames(inverse.results) <- colnames(per.source.results)
inverse.results$inverse <- TRUE

per.source.results <-
  rbind.data.frame(per.source.results, inverse.results)

per.source.results <- unique(per.source.results[,c(1,3)])
