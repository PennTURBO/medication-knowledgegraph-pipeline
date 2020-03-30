options(java.parameters = "-Xmx6g")
library(RJDBC)
library(config)
library(ggplot2)
library(readr)
library(stringr)
library(stringdist)
library(randomForest)
library(dplyr)
library(httr)

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

print(getwd())

config <- config::get(file = "rxnav_med_mapping.yaml")

chunk.vec <- function(vec, chunk.count) {
  split(vec, cut(seq_along(vec), chunk.count, labels = FALSE))
}

approximateTerm <- function(med.string) {
  # med.string <- "500 mg acetaminophen oral tablet"
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

### MIGHT WANT TO CHANGE TO ALL.X TRUE MERGES
### WITH PDS TABULAR IMPUT, THERE WILL BE SOME ROWS WITH NAs after merges
### COULD ALSO FILTER OUT SEARCH RESULTS WITH BAD TTYs
### COULD SET ASIDE ROWS WITH A SCORE OF 100 FROM TRAINING

# for now, using complete.cases filter on all training and prediction data

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

rxnDriver <-
  JDBC(driverClass = "com.mysql.cj.jdbc.Driver",
       classPath = config$mysql.jdbc.path)

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

