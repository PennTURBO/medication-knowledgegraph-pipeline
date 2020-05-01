options(java.parameters = "-Xmx6g")
library(config)
library(dplyr)
library(ggplot2)
library(httr)
library(jsonlite)
library(randomForest)
library(rdflib)
library(readr)
library(RJDBC)
library(solrium)
library(stringdist)
library(stringr)
library(uuid)

# train
library(splitstackshape)

### validation
library(ROCR)
library(caret)

# library(xgboost)
# # also try party and xgboot

# ensure that large integers aren't casted to scientific notation
#  for example when being posted into a SQL query
options(scipen = 999)

# make sure this is being read from the intended folder
# user's home?
# current working directory?

print("Default file path set to:")
print(getwd())

config <- config::get(file = "rxnav_med_mapping.yaml")
# 
# med.mapping.general.config <-
#   config::get(file = 'rxnav_med_mapping.yaml')

chunk.vec <- function(vec, chunk.count) {
  split(vec, cut(seq_along(vec), chunk.count, labels = FALSE))
}

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
    return(r)
  }
}

bulk.approximateTerm <-
  function(strs = c("tylenol", "cisplatin", "benadryl", "rogaine")) {
    temp <- lapply(strs, function(current.query) {
      print(current.query)
      params <- list(term = current.query, maxEntries = 50)
      r <-
        httr::GET("http://localhost:4000/",
                  path = "REST/approximateTerm.json",
                  query = params)
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

get.string.dist.mat <- function(two.string.cols) {
  two.string.cols <- as.data.frame(two.string.cols)
  unique.string.combos <- unique(two.string.cols)
  distance.cols = c("lv", "lcs", "qgram", "cosine", "jaccard", "jw")
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

instantiate.and.upload <- function(current.task) {
  print(current.task)
  
  more.specific <-
    config::get(file = "rxnav_med_mapping.yaml", config = current.task)
  
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

q2j2df <-
  function(query,
           endpoint = config$my.graphdb.base,
           repo = config$my.selected.repo,
           auth = saved.authentication) {
    # query <- config$main.solr.query
    
    rdfres <- httr::GET(
      url = paste0(endpoint,
                   "/repositories/",
                   repo),
      query = list(query = query),
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
    
    # beautify column labels
    temp <-
      gsub(pattern = '\\.value$',
           replacement = '',
           x = colnames(rdfres))
    # temp <- gsub(pattern = '^.*\\$',
    #              replacement = '',
    #              x = temp)
    colnames(rdfres) <- temp
    
    return(rdfres)
    
  }

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


####


saved.authentication <-
  authenticate(config$my.graphdb.username,
               config$my.graphdb.pw,
               type = "basic")

####


rxnDriver <-
  JDBC(driverClass = "com.mysql.cj.jdbc.Driver",
       classPath = config$mysql.jdbc.path)

# i keep re-doing this thorugh other scripts
rxnCon <-
  dbConnect(
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
