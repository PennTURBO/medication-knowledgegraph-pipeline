library(dplyr)
library(tidyr)
library(tibble)
library(readr)

# rrdf
# sparql
# rdflib
# other libraries?

# robot
# ontorefine
# other tools...

# just write

files.listed <- list.files(
  path = '/Users/markampa/RxNorm_full_05042020/rrf',
  pattern = 'RRF',
  all.files = TRUE ,
  full.names = TRUE,
  recursive = FALSE ,
  ignore.case = TRUE ,
  include.dirs = FALSE
)
informed.files <- file.info(files.listed)
informed.files$fn <- rownames(informed.files)
informed.files <- informed.files[order(informed.files$size), ]

# "/Users/markampa/Downloads/RxNorm_full_05042020/rrf/RXNATOMARCHIVE.RRF"

# RXNCONSO
# RXNDOC
# RXNSAT

# temp <- c(
#   "/Users/markampa/Downloads/RxNorm_full_05042020/rrf/RXNCONSO.RRF",
#   "/Users/markampa/Downloads/RxNorm_full_05042020/rrf/RXNDOC.RRF",
#   "/Users/markampa/Downloads/RxNorm_full_05042020/rrf/RXNSAT.RRF"
# )
# 
# # informed.files$fn

# > dput(rownames(informed.files))
# c("/Users/markampa/RxNorm_full_05042020/rrf/RXNSAB.RRF", "/Users/markampa/RxNorm_full_05042020/rrf/RXNCUICHANGES.RRF", 
#   "/Users/markampa/RxNorm_full_05042020/rrf/RXNDOC.RRF", "/Users/markampa/RxNorm_full_05042020/rrf/RXNCUI.RRF", 
#   "/Users/markampa/RxNorm_full_05042020/rrf/RXNSTY.RRF", "/Users/markampa/RxNorm_full_05042020/rrf/RXNATOMARCHIVE.RRF", 
#   "/Users/markampa/RxNorm_full_05042020/rrf/RXNCONSO.RRF", "/Users/markampa/RxNorm_full_05042020/rrf/RXNREL.RRF", 
#   "/Users/markampa/RxNorm_full_05042020/rrf/RXNSAT.RRF")

lapply(temp, function(current.fn) {
  # current.fn <- "/Users/markampa/RxNorm_full_05042020/rrf/RXNREL.RRF"
  print(current.fn)
  base.plus.ext <- basename(current.fn)
  base.plus.ext <-
    sub(pattern = "\\.RRF",
        replacement = ".csv",
        x = base.plus.ext)
  
  data.dict <-
    read.csv(file = paste0("~/cleanroom/med_mapping/", base.plus.ext))
  
  # read_delim is faster, show progress and is more flexible, 
  #   but I can'tfigure out it's rules for column types
  current.frame <-
    read.delim(
      file = current.fn,
      header = FALSE,
      sep = "|",
      as.is =  TRUE,
      colClasses = "character",
      strip.white = TRUE,
      stringsAsFactors = FALSE
    )
  
  colnames(current.frame) <- data.dict$Column
  
  current.frame <- current.frame[, as.character(data.dict$Column)]
  
  # current.frame$counter <- 1
  
  rownames(current.frame) <-
    uuid::UUIDgenerate(n = nrow(current.frame))
  
  current.triples <- as.data.frame(
    current.frame %>%
      rownames_to_column("uuid") %>% mutate(subject = paste0(
        "<http://example.com/resource/", uuid, '>'
      )) %>%
      gather(key = predicate, value = object, -subject, uuid) %>%
      mutate(predicate = paste0(
        "<http://example.com/resource/", predicate, '>'
      ))
  )
  
  current.triples <-
    current.triples[complete.cases(current.triples),]
  current.triples <-
    current.triples[current.triples$object != "" ,]
  
  # or trust write.table to do the quoting?
  # or use robot?
  current.triples$object <-
    gsub(pattern = '"',
         replacement = "'",
         x = current.triples$object)
  
  current.triples$object <-
    paste0('"', current.triples$object, '"')
  
  current.triples <-
    current.triples[current.triples$predicate != '<http://example.com/resource/uuid>',]
  
  current.triples$graph <-
    paste0("<http://example.com/", basename(current.fn), ">")
  
  current.triples$period <- '.'
  
  semantic.file <-
    sub(pattern = "\\.RRF",
        replacement = ".nq",
        x = basename(current.fn))
  
  write.table(
    x = current.triples,
    file = semantic.file,
    quote = FALSE,
    sep = " ",
    row.names = FALSE,
    col.names = FALSE
  )
  
  my.zipfile <- paste0(semantic.file, ".zip")
  
  zip::zipr(zipfile = my.zipfile, files = semantic.file)
  
})
