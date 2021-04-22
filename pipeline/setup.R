options(java.parameters = "-Xmx6g")

# CHECK FOR SILENT USE OF GLOBAL VARIABLES
# including config$

# # trickier
## would any of this require the Rtools system package in Windows?

# install.packages("rJava")  
# install.packages("devtools")  
# library(devtools)  
# install_github("egonw/rrdf", subdir="rrdflibs")  
# install_github("egonw/rrdf", subdir="rrdf", build_vignettes = FALSE) 
library(rJava)
library(devtools)
library(rrdf)

# see also https://jangorecki.gitlab.io/data.cube/library/data.table/html/dcast.data.table.html
library(config)
library(dplyr)
library(e1071)
library(ggplot2)
library(httr)
library(igraph)
library(jsonlite)
library(randomForest)
library(rdflib)
library(readr)
library(readxl)
library(reshape2)
library(RJDBC)
library(solrium)
library(ssh)
library(stringdist)
library(stringr)
library(tm)
library(uuid)

# train
library(splitstackshape)

### validation
library(ROCR)
library(caret)

# library(xgboost)
# # also try party or xgboot for random forest modeling?

# still more
# classification
library(zip)

# get bioportal mappings
library(gtools)

# ensure that large integers aren't casted to scientific notation
#  for example when being inserted into a SQL database
options(scipen = 999)

# make sure this is being read from the intended folder
# user's home?
# current working directory?

#print("Default file path set to:")
#print(getwd())

# pre_commit_tags = readLines("../release_tag.txt")
# pre_commit_status = readLines("../release_status.txt")

execution.timestamp <-
  as.POSIXlt(Sys.time(), "UTC", "%Y-%m-%dT%H:%M:%S")
execution.timestamp <-
  strftime(execution.timestamp , "%Y-%m-%dT%H:%M:%S%z")

# release_tag.fp <- "../release_tag.txt"
# temp <- read_lines(release_tag.fp)

temp <- yaml::read_yaml("/config/app.yaml")
temp <- temp$version

version.list <-
  list(versioninfo = temp,
       created = execution.timestamp)

config.file <- "/config/setup.yaml"

config <- config::get(file = config.file)

#print(config$oracle.jdbc.path)

####

url.post.endpoint <-
  paste0(
    config$my.graphdb.base,
    "/rest/data/import/upload/",
    config$my.selected.repo,
    "/url"
  )

update.endpoint <-
  paste0(config$my.graphdb.base,
         "/repositories/",
         config$my.selected.repo,
         "/statements")

select.endpoint <-
  paste0(config$my.graphdb.base,
         "/repositories/",
         config$my.selected.repo)

saved.authentication <-
  authenticate(config$my.graphdb.username,
               config$my.graphdb.pw,
               type = "basic")

#print("pipeline/setup.R")
#print("config$mysql.jdbc.path")
#print(config$mysql.jdbc.path)

rxnDriver <-
  JDBC(driverClass = "com.mysql.cj.jdbc.Driver",
       classPath = config$mysql.jdbc.path)

#rxnCon <- NULL

#print("pipeline/setup.R")
#print("Attempting rxnCon <- dbConnect()")

#print("rxnDriver")
#print(rxnDriver)

#print("config$rxnav.mysql.address")
#print(config$rxnav.mysql.address)

#print("config$rxnav.mysql.port")
#print(config$rxnav.mysql.port)

#print("config$rxnav.mysql.user")
#print(config$rxnav.mysql.user)

#Default pass different from config pass?
#print("Default pass different from config pass?")
#print("config$rxnav.mysql.pw")
#print(config$rxnav.mysql.pw)


# # i keep re-doing this thorugh other scripts
# rxnCon <-
#   dbConnect(
#     rxnDriver,
#     paste0(
#       "jdbc:mysql://",
#       config$rxnav.mysql.address,
#       ":",
#       config$rxnav.mysql.port
#     ),
#     config$rxnav.mysql.user,
#     config$rxnav.mysql.pw
#   )

####

# these are functioning like globals so they don't have to be passed to bp.map.retreive.and.parse()
api.base.uri <- "http://data.bioontology.org/ontologies"
api.ontology.name <- "LOINC"
term.ontology.name <- "LNC"
term.base.uri <-
  paste0("http://purl.bioontology.org/ontology",
         "/",
         term.ontology.name)
api.family <- "classes"
# source.term <- "http://purl.bioontology.org/ontology/LNC/LP17698-9"
api.method <- "mappings"
# what are the chances that a mapping query will return 0 mappings, or that it will return multiple pages?

#### remainder of script = functions, grouped by pipeline specificity

#### ???
label.table <- function() {
  temp <- table(term.label)
  temp <-
    cbind.data.frame(names(temp), as.numeric(temp))
  colnames(temp) <- c("label", "count")
  table(temp$count)
}

# general purpose
chunk.vec <- function(vec, chunk.count) {
  split(vec, cut(seq_along(vec), chunk.count, labels = FALSE))
}

# general purpose
make.table.frame <- function(my.vector) {
  temp <- table(my.vector)
  temp <- cbind.data.frame(names(temp), as.numeric(temp))
  colnames(temp) <- c('value', 'count')
  temp$value <- as.character(temp$value)
  return(temp)
}

# general
get.string.dist.mat <- function(two.string.cols) {
  two.string.cols <- as.data.frame(two.string.cols)
  unique.string.combos <- unique(two.string.cols)
  distance.cols = sort(c("lv", "lcs", "qgram", "cosine", "jaccard", "jw"))
  distances <- lapply(distance.cols, function(one.meth) {
    print(one.meth)
    temp <-
      stringdist(
        a = two.string.cols[, 1],
        b = two.string.cols[, 2],
        method = one.meth,
        nthread = 4
      )
    return(temp)
  })
  distances <- do.call(cbind.data.frame, distances)
  colnames(distances) <- distance.cols
  two.string.cols <-
    cbind.data.frame(two.string.cols, distances)
  return(two.string.cols)
}

# general
import.from.local.file <-
  function(some.graph.name,
           some.local.file,
           some.rdf.format) {
    print(some.graph.name)
    print(some.local.file)
    print(some.rdf.format)
    post.dest <-
      paste0(
        config$my.graphdb.base,
        '/repositories/',
        config$my.selected.repo,
        '/rdf-graphs/service?graph=',
        some.graph.name
      )
    
    print(post.dest)
    
    post.resp <-
      httr::POST(
        url = post.dest,
        body = upload_file(some.local.file),
        content_type(some.rdf.format),
        authenticate(config$my.graphdb.username,
                     config$my.graphdb.pw,
                     type = 'basic')
      )
    
    print('Errors will be listed below:')
    print(rawToChar(post.resp$content))
  }

# general
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

# general
get.context.report <- function() {
  context.report <- GET(
    url = paste0(
      config$my.graphdb.base,
      "/repositories/",
      config$my.selected.repo,
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

# general
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
    
    print(paste0("Next check in ",
                 config$monitor.pause.seconds,
                 " seconds."))
 
    Sys.sleep(config$monitor.pause.seconds)
    
  }
}

# general
q2j2df <- function(query,
                   endpoint = config$my.graphdb.base,
                   repo = config$my.selected.repo,
                   auth = saved.authentication) {
  minquery <- gsub(pattern = " +",
                   replacement = " ",
                   x = query)
  
  rdfres <- httr::GET(
    url = paste0(endpoint,
                 "/repositories/",
                 repo),
    query = list(query = minquery),
    auth
  )
  
  # convert binary JSON SPARQL results to a minimal dataframe
  rdfres <-
    jsonlite::fromJSON(rawToChar(rdfres$content))
  rdfres <- rdfres$results$bindings
  rdfres <-
    do.call(what = cbind.data.frame, args = rdfres)
  keepers <- colnames(rdfres)
  keepers <- keepers[grepl(pattern = "value$", x = keepers)]
  rdfres <- rdfres[, keepers]
  
  if (is.data.frame(rdfres)) {
    # beautify column labels
    temp <-
      gsub(pattern = '\\.value$',
           replacement = '',
           x = colnames(rdfres))
    
    colnames(rdfres) <- temp
    
    return(rdfres)
  }
  
}

# general
# but has only been used in deprecated LOINC-based assay modeling for far?
# bad use of implicit globals
bp.map.retreive.and.parse <- function(term.list) {
  outer <- lapply(term.list, function(current.term) {
    # current.term <- "LP102314-4"
    # current.term <-"LP40488-6"
    # current.term <-"LP417915-8"
    
    print(current.term)
    current.uri <- paste0(term.base.uri, "/", current.term)
    encoded.term <- URLencode(current.uri, reserved = TRUE)
    prepared.get <-
      paste(api.base.uri,
            api.ontology.name,
            api.family,
            encoded.term,
            api.method,
            sep = "/")
    mapping.res.list <-
      httr::GET(url = prepared.get,
                add_headers(
                  Authorization = paste0("apikey token=", config$public.bioportal.api.key)
                ))
    
    print(mapping.res.list$status_code)
    
    if (mapping.res.list$status_code == 200) {
      mapping.res.list <- rawToChar(mapping.res.list$content)
      
      mapping.res.list <- jsonlite::fromJSON(mapping.res.list)
      
      # print(head(mapping.res.list))
      
      if (length(mapping.res.list) > 0) {
        # CUI, LOOM, "same URI", etc. Probably only LOOM will be useful
        mapping.methods <- mapping.res.list$source
        
        source.target.details <-
          lapply(mapping.res.list$classes, function(current.mapping) {
            source.target.terms <- current.mapping$`@id`
            source.target.ontologies <-
              current.mapping$links$ontology
            return(c(
              rbind(source.target.terms, source.target.ontologies)
            ))
          })
        
        source.target.details <-
          do.call(rbind.data.frame, source.target.details)
        colnames(source.target.details) <-
          c("source.term",
            "source.ontology",
            "target.term",
            "target.ontology")
        
        source.target.details <-
          cbind.data.frame(source.target.details, mapping.methods)
        return(source.target.details)
      }
    }
  })
}

# general
bioportal.string.search <- function(current.string) {
  # current.string <- 'asthma'
  print(current.string)
  prepared.get <-
    paste0(
      'http://data.bioontology.org/search?q=',
      current.string  ,
      '&include=prefLabel,synonym',
      '&pagesize=999'
    )
  prepared.get <- URLencode(prepared.get, reserved = FALSE)
  search.res.list <-
    httr::GET(url = prepared.get,
              add_headers(
                Authorization = paste0("apikey token=", config$public.bioportal.api.key)
              ))
  
  search.res.list <- rawToChar(search.res.list$content)
  search.res.list <- jsonlite::fromJSON(search.res.list)
  search.res.list <- search.res.list$collection
  
  # print(search.res.list$links$ontology)
  
  if (is.data.frame(search.res.list)) {
    if (nrow(search.res.list) > 0) {
      ontology <- search.res.list$links$ontology
      #  , 'ontologyType'
      search.res.list <- search.res.list[, c('prefLabel', '@id')]
      colnames(search.res.list) <- c('prefLabel', 'iri')
      search.res.list <-
        cbind.data.frame(search.res.list, 'ontology' = ontology)
      search.res.list$rank <- 1:nrow(search.res.list)
      return(search.res.list)
    }
  }
}

# general
# but has only been used for deprecated LOINC based assay modeling so far
# see https://www.ebi.ac.uk/ols/docs/api
ols.serch.term.labels.universal <-
  function(current.string,
           current.id,
           strip.final.s = FALSE,
           ontology.filter,
           kept.row.count = 9,
           req.exact = 'false') {
    if (strip.final.s) {
      current.string <-
        sub(pattern = "s$",
            replacement = "",
            x = current.string)
    }
    
    # singular.lc <- current.string
    
    # or just try url encoding?
    
    # substitute 'spp$' or 'sp$' with ''  for genus-level NCBI taxon entities
    # that porabialy isn't desirable in general
    # and should be really clear to users fo thsi function
    
    current.string <-
      gsub(pattern = " sp$",
           replacement = "",
           x = current.string)
    
    current.string <-
      gsub(pattern = " spp$",
           replacement = "",
           x = current.string)
    
    singular.lc <- current.string
    print(singular.lc)
    
    current.string <-
      gsub(pattern = "[[:punct:] ]",
           replacement = ",",
           x = current.string)
    
    
    print(current.string)
    
    prepared.query <- paste0(
      "https://www.ebi.ac.uk/ols/api/search?q={",
      current.string,
      "}&type=class&local=true",
      ontology.filter ,
      "&rows=",
      kept.row.count,
      '&exact=',
      req.exact,
      "&fieldList=iri,short_form,obo_id,ontology_name,ontology_prefix,label,synonym,annotations,annotations_trimmed",
      "&query_fields=label,synonym,annotations,annotations_trimmed"
    )
    
    # print(prepared.query)
    
    ols.attempt <-
      httr::GET(prepared.query)
    
    ols.attempt <- ols.attempt$content
    ols.attempt <- rawToChar(ols.attempt)
    ols.attempt <- jsonlite::fromJSON(ols.attempt)
    ols.attempt <- ols.attempt$response$docs
    if (is.data.frame(ols.attempt)) {
      if (nrow(ols.attempt) > 0) {
        ols.attempt$query <- singular.lc
        ols.attempt$loinc.part <- current.id
        
        ols.attempt$rank <- 1:nrow(ols.attempt)
        ols.attempt$label <- tolower(ols.attempt$label)
        ols.attempt$query <- tolower(ols.attempt$query)
        
        return(ols.attempt)
      }
    }
  }



# general
# see also method for keeping PDS connection presh
# todo paramterize connection and query string
# how to user connection paramaterizastion LHS or assignment?
rxnav.test.and.refresh <- function() {
  local.q <- "select RSAB from rxnorm_current.RXNSAB r"
  tryCatch({
    dbGetQuery(rxnCon, local.q)
  }, warning = function(w) {
    
  }, error = function(e) {
    print(e)
    print("trying to reconnect")
    rxnCon <<- dbConnect(
      rxnDriver,
      paste0(
        "jdbc:mysql://",
        config$rxnav.mysql.address,
        ":",
        config$rxnav.mysql.port
      ),
      config$rxnav.mysql.user,
      config$rxnav.mysql.pw
    )
    dbGetQuery(rxnCon, local.q)
  }, finally = {
    
  })
}


# general
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
        inner.res[as.character(inner.res$source.term) != as.character(inner.res$mapped.term), ]
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

# working with medications in general
approximateTerm <- function(med.string) {
  params <- list(term = med.string, maxEntries = 50)
  r <-
    httr::GET(
      paste0("http://",
             rxnav.api.address,
             ":",
             rxnav.api.port,
             "/"),
      path = "REST/approximateTerm.json",
      query = params
    )
  r <- rawToChar(r$content)
  r <- jsonlite::fromJSON(r)
  r <- r$approximateGroup$candidate
  if (is.data.frame(r)) {
    r$query <- med.string
    Sys.sleep(0.1)
    return(r)
  }
}

# working with medications in general
bulk.approximateTerm <-
  function(strs = c("tylenol", "cisplatin", "benadryl", "rogaine")) {
    temp <- lapply(strs, function(current.query) {
      print(current.query)
      params <- list(term = current.query, maxEntries = 50)
      r <-
        httr::GET(
          paste0(
            "http://",
            config$rxnav.api.address,
            ":",
            config$rxnav.api.port,
            "/"
          ),
          path = "REST/approximateTerm.json",
          query = params
        )
      r <- rawToChar(r$content)
      r <- jsonlite::fromJSON(r)
      r <- r$approximateGroup$candidate
      if (is.data.frame(r)) {
        r$query <- current.query
        return(r)
      }
    })
    temp <-
      do.call(rbind.data.frame, temp)
    
    temp$rank <-
      as.numeric(as.character(temp$rank))
    temp$score <-
      as.numeric(as.character(temp$score))
    temp$rxcui <-
      as.numeric(as.character(temp$rxcui))
    temp$rxaui <-
      as.numeric(as.character(temp$rxaui))
    
    approximate.rxcui.tab <- table(temp$rxcui)
    approximate.rxcui.tab <-
      cbind.data.frame(names(approximate.rxcui.tab),
                       as.numeric(approximate.rxcui.tab))
    names(approximate.rxcui.tab) <- c("rxcui", "rxcui.count")
    approximate.rxcui.tab$rxcui <-
      as.numeric(as.character(approximate.rxcui.tab$rxcui))
    approximate.rxcui.tab$rxcui.freq <-
      approximate.rxcui.tab$rxcui.count / (sum(approximate.rxcui.tab$rxcui.count))
    
    
    approximate.rxaui.tab <- table(temp$rxaui)
    approximate.rxaui.tab <-
      cbind.data.frame(names(approximate.rxaui.tab),
                       as.numeric(approximate.rxaui.tab))
    names(approximate.rxaui.tab) <- c("rxaui", "rxaui.count")
    approximate.rxaui.tab$rxaui <-
      as.numeric(as.character(approximate.rxaui.tab$rxaui))
    approximate.rxaui.tab$rxaui.freq <-
      approximate.rxaui.tab$rxaui.count / (sum(approximate.rxaui.tab$rxaui.count))
    
    temp <-
      base::merge(x = temp, y = approximate.rxcui.tab)
    
    temp <-
      base::merge(x = temp, y = approximate.rxaui.tab)
    
    return(temp)
  }

# working with medications in general
bulk.rxaui.asserted.strings <-
  function(rxauis, chunk.count = rxaui.asserted.strings.chunk.count) {
    rxn.chunks <-
      chunk.vec(sort(unique(rxauis)), chunk.count)
    
    rxaui.asserted.strings <-
      lapply(names(rxn.chunks), function(current.index) {
        current.chunk <- rxn.chunks[[current.index]]
        tidied.chunk <-
          paste0("'", current.chunk, "'", collapse = ", ")
        
        rxnav.rxaui.strings.query <-
          paste0(
            "SELECT RXCUI as rxcui,
            RXAUI as rxaui,
            SAB ,
            SUPPRESS ,
            TTY ,
            STR
            from
            rxnorm_current.RXNCONSO r where RXAUI in ( ",
            tidied.chunk,
            ")"
          )
        
        temp <- dbGetQuery(rxnCon, rxnav.rxaui.strings.query)
        return(temp)
      })
    
    rxaui.asserted.strings <-
      do.call(rbind.data.frame, rxaui.asserted.strings)
    
    rxaui.asserted.strings[, c("rxcui", "rxaui")] <-
      lapply(rxaui.asserted.strings[, c("rxcui", "rxaui")],  as.numeric)
    
    rxaui.asserted.strings$STR.lc <-
      tolower(rxaui.asserted.strings$STR)
    
    return(rxaui.asserted.strings)
  }



#### specifically medication mapping

build.source.med.classifications.annotations <-
  function(version.list,
           onto.iri,
           onto.file,
           onto.file.format) {
    # cat(config$source.med.classifications.onto.comment)
#print("setup.R:build.source.med.classifications.annotations()")
    annotation.model <- rdf()
    rdflib::rdf_add(
      rdf = annotation.model,
      subject = onto.iri,
      predicate = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
      object = "http://www.w3.org/2002/07/owl#Ontology"
    )
    rdflib::rdf_add(
      rdf = annotation.model,
      subject = onto.iri,
      predicate = "http://purl.org/dc/terms/created",
      object = version.list$created
    ) 
    rdflib::rdf_add(
      rdf = annotation.model,
      subject = onto.iri,
      predicate = "http://www.w3.org/2002/07/owl#versionInfo",
      object = version.list$versioninfo
    )
    rdflib::rdf_add(
      rdf = annotation.model,
      subject = onto.iri,
      predicate = "http://www.w3.org/2000/01/rdf-schema#comment",
      object = config$source.med.classifications.onto.comment
    )
    rdf_serialize(rdf = annotation.model,
                  doc = onto.file,
                  format = onto.file.format)
  }

# specifically for medication mapping ?
instantiate.and.upload <- function(current.task) {
  print(current.task)
  
  # more.specific <-
  #   config::get(file = "rxnav_med_mapping.yaml", config = current.task)
  
  more.specific <-
    config::get(file = config.file, config = current.task)
  
  predlist <- colnames(body[2:ncol(body)])
  print(predlist)
  
  current.model.rdf <- rdflib::rdf()
  
  placeholder <-
    apply(
      X = body,
      MARGIN = 1,
      FUN = function(current_row) {
        innerph <- lapply(predlist, function(current.pred) {
          rdflib::rdf_add(
            rdf = current.model.rdf,
            subject = current_row[[1]],
            predicate = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
            object = more.specific$my.class
          )
          temp <- current_row[[current.pred]]
          if (nchar(temp) > 0) {
            # print(paste0(current.pred, ':', temp))
            if (current.pred %in% more.specific$my.numericals) {
              temp <- as.numeric(temp)
            }
            rdflib::rdf_add(
              rdf = current.model.rdf,
              subject = current_row[[1]],
              predicate = paste0('http://example.com/resource/', current.pred),
              object = temp
            )
          }
        })
      }
    )
  
  rdf.file <- paste0(current.task, '.ttl')
  
  rdflib::rdf_serialize(rdf = current.model.rdf,
                        doc = rdf.file,
                        format = "turtle")
  
  post.dest <-
    paste0(
      more.specific$my.graphdb.base,
      '/repositories/',
      more.specific$my.selected.repo,
      '/rdf-graphs/service?graph=',
      URLencode(
        paste0('http://example.com/resource/',
               current.task),
        reserved = TRUE
      )
    )
  
  print(post.dest)
  
  post.resp <-
    httr::POST(
      url = post.dest,
      body = upload_file(rdf.file),
      content_type(more.specific$my.mappings.format),
      authenticate(
        more.specific$my.graphdb.username,
        more.specific$my.graphdb.pw,
        type = 'basic'
      )
    )
  
  print('Errors will be listed below:')
  print(rawToChar(post.resp$content))
  
}
