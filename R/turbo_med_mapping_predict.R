# instead of winner takes all (keep the one highest probability prediction, as long as it isn't FALSE-FALSE-FALSE-FALSE)
#  use the multiple predictions to find the most likely neighborhood in the graph?

# try solr ~ fuzzy operator 
# don't train on ontology factor?, because training data won't have anything that doesn't have an rxnorm, like devices?

# make sure that any train or prediction code posted to github uses 1.0 for graphdb, solr and rf submission fractions

# still haven't excluded alt labels from NDDF (or chebi... chemical names) BEFORE TRAINING

# for training, make sure we're really filtering on rxnorm count == 1 (SPARQL),
#   non combination drug (solr but could be done in more complex SPARQL)
# for predicting, exclude medication that already have an rxnorm assignment in PDS but keep combination drugs

# also include pk med id?

# lots of redundant code between train and predict

# use faster merge (join) and cast (dcast) functions

# still need to do role inheritance (MRB cares less about this?)

# make sure <http://example.com/resource/mdm_ods_meds_source_supplement> is documented

# have gone back to:
#   pm.states <- as.data.frame(proximity_measures[, c("sameTerm", "sharedParent", "oneLink", "twoLinks")])

options(java.parameters = "-Xmx32g")
# options(java.parameters = "-Xmx8g")

# document system dependencies like xml, openssl...
library(RColorBrewer)
library(e1071)
library(solrium)
library(stringdist)
library(reshape)
library(uuid)
library(data.table)
library(tidyr)
library(randomForest)
library(caret)
library(plyr)
library(tidytext)
library(tibble)
library(devtools)
library(httr)
# rrdf requires rJava and is installed from github via devtools
library(rrdf)

rm(list = ls())
gc()

uphs.subset.frac <- 0.03

solr.submission.fraction <- 1.0

solr.row.req <- 30

next.scaling <- 1.0

my.target <- "pastedProx"

###  load and print reviously determined feature importance here
# load("turbo_med_mapping_rf_classifier.Rdata")
load("turbo_med_mapping_rf_classifier_no_nddf_alt.Rdata")

# should get this from the model
important.features <- c(
  "jaccard",
  "score",
  "cosine",
  "rank",
  "jw",
  "hwords",
  "hchars",
  "qchars",
  "qgram",
  "term.count",
  "qwords",
  "lv",
  "lcs",
  "ontology",
  "T200",
  "ontology.count",
  "rxnMatchMeth",
  "http...www.w3.org.2004.02.skos.core.altLabel",
  "labelType"
)

solr.endpoint <-
  SolrClient$new(host = "localhost")

solr.coll <- "guaranteed"

solr.endpoint$ping(solr.coll)

q.pre <- "labelContent:("
q.post <- ")"

my.repo <- "med_map_support_20180403"

sparql.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo)

### for prediction/classification of search resultls:
# include combo drugs and those without rxnorms

uphs.name.to.rxn.q <- paste0(
  '
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select

  ?MedicationName ?RXNORM_CODE_URI ?source ?rxnlab
  where
  {
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
      ?s rdf:type mydata:Row ;
      mydata:FULL_NAME ?MedicationName .
      optional {
        graph mydata:pds_rxn_casts {
          ?s mydata:RXNORM_CODE_URI  ?RXNORM_CODE_URI .
        }
        graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
          ?RXNORM_CODE_URI a owl:Class ;
          skos:prefLabel ?rxnlab .
        }
      }
    }
    optional {
      graph <http://example.com/resource/mdm_ods_meds_source_supplement> {
        ?s mydata:SOURCE_CODE ?source .
      }
    }
  }  '
)

time.start <-  Sys.time()
print(time.start)

complete.uphs.with.current.rxnorm <-
  sparql.remote(endpoint = sparql.endpoint,
                sparql = uphs.name.to.rxn.q,
                jena = TRUE)
time.stop <-  Sys.time()
time.duration <- time.stop - time.start
print(time.duration)

nrow(complete.uphs.with.current.rxnorm)

table(complete.uphs.with.current.rxnorm[, "source"])

# Time difference of 2.962501 mins
#
#   > nrow(complete.uphs.with.current.rxnorm)
# [1] 937954
#
#   > table(complete.uphs.with.current.rxnorm[, "source"])
# EMTRAC     EPIC      SCM THERADOC
# 424637   181930   245922    85465


###   ###   ###

uphs.with.current.rxnorm.frac <-
  complete.uphs.with.current.rxnorm[sample(
    nrow(complete.uphs.with.current.rxnorm),
    nrow(complete.uphs.with.current.rxnorm) * uphs.subset.frac
  ),]

temp <- is.na(uphs.with.current.rxnorm.frac[, "RXNORM_CODE_URI"])

uphs.with.current.rxnorm.frac <-
  uphs.with.current.rxnorm.frac[temp,]

###   ###   ###

queries <-
  as.character(uphs.with.current.rxnorm.frac[, "MedicationName"])


queries <- cbind.data.frame(queries, tolower(queries))

names(queries) <- c("FULL_NAME", "FULL_NAME.lc")

queries$expanded <-
  gsub(pattern = "_+",
       replacement = " ",
       x = queries$FULL_NAME.lc)

###   ###   ###

expansion.rules.q <- '
PREFIX mydata: <http://example.com/resource/>
select
distinct ?pattern ?replacement
where {
    graph mydata:med_name_expansions {
        ?myRowId a mydata:med_expansion ;
                 mydata:pattern ?pattern .
        optional {
            ?myRowId mydata:replacement ?replacement .
        }
    }
}
'

time.start <-  Sys.time()
print(time.start)

expansion.rules.res <-
  sparql.remote(endpoint = sparql.endpoint,
                sparql = expansion.rules.q,
                jena = TRUE)
time.stop <-  Sys.time()
time.duration <- time.stop - time.start
print(time.duration)

nrow(expansion.rules.res)

expansion.rules.res <-
  as.data.frame(expansion.rules.res, stringsAsFactors = FALSE)
expansion.rules.res$pattern <-
  paste("\\b", expansion.rules.res$pattern, "\\b", sep = "")
expansion.rules.res$replacement[is.na(expansion.rules.res$replacement)] <-
  ""

expansion.rules <- expansion.rules.res$replacement
names(expansion.rules) <- expansion.rules.res$pattern

###   ###   ###

queries$expanded <-
  stringr::str_replace_all(queries$expanded, expansion.rules)

tidied.queries <- queries$expanded

tidied.queries <-
  gsub(pattern = "^\\W+",
       replacement = "",
       x = tidied.queries)

tidied.queries <-
  gsub(pattern = "\\W+$",
       replacement = "",
       x = tidied.queries)

tidied.queries <-
  gsub(
    pattern = '\\',
    replacement = ' ',
    fixed = TRUE,
    x = tidied.queries
  )

tidied.queries <-
  gsub(pattern = "([/\\+\\&\\|\\!\\^\\~\\*\\?\\:\\(\\)\\{\\}])",
       replacement = "\\\\\\1",
       x = tidied.queries)

tidied.queries <-
  gsub(
    pattern = '"',
    replacement = '\\"',
    fixed = TRUE,
    x = tidied.queries
  )


tidied.queries <-
  gsub(
    pattern = '-',
    replacement = '\\-',
    fixed = TRUE,
    x = tidied.queries
  )


tidied.queries <-
  gsub(
    pattern = ']',
    replacement = '\\]',
    fixed = TRUE,
    x = tidied.queries
  )

tidied.queries <-
  gsub(
    pattern = '[',
    replacement = '\\[',
    fixed = TRUE,
    x = tidied.queries
  )

tidied.queries <- gsub(pattern = " +",
                       replacement = " ",
                       x = tidied.queries)

tidied.queries <-
  gsub(pattern = "\\s+",
       replacement = " ",
       x = tidied.queries)

queries$expanded <- tidied.queries

uphs.with.current.rxnorm.frac <-
  unique(as.data.frame(uphs.with.current.rxnorm.frac))

queries <-
  unique(queries)

uphs.plus.expanded <-
  merge(
    x = uphs.with.current.rxnorm.frac,
    y = queries[, c("FULL_NAME", "expanded")],
    by.x = "MedicationName",
    by.y  = "FULL_NAME",
    all = TRUE
  )

uphs.plus.expanded <- unique(uphs.plus.expanded)

unique.queries <- sort(unique(uphs.plus.expanded$expanded))
unique.queries <- unique.queries[nchar(unique.queries) > 0]

uql <- length(unique.queries)

print(uql)

# [1] 750863

rand.temp <- runif(uql)
keep.thresh <- 1 - solr.submission.fraction

unique.queries.retained <- unique.queries[rand.temp > keep.thresh]

###   ###   ###

# add ~ after each token for fuzzy search?


print(Sys.time())
solr.duration <-
  system.time(via.solr <-
                lapply(unique.queries.retained, function(current.query) {
                  tweaked.query <-
                    gsub(
                      pattern = "[)(:\\]\\[]",
                      perl = TRUE,
                      replacement = " ",
                      x = current.query
                    )
                  
                  tweaked.query <-
                    gsub(
                      pattern = "/",
                      perl = TRUE,
                      replacement = " ",
                      x = tweaked.query
                    )
                  
                  tweaked.query <-
                    gsub(pattern = "\\s+",
                         replacement = " ",
                         x = tweaked.query)
                  
                  built.query <-
                    paste0(q.pre , tweaked.query , q.post)
                  
                  print(tweaked.query)
                  
                  
                  solr.result <-
                    solr.endpoint$search(
                      solr.coll,
                      params = list(q = built.query,
                                    fl = "ontology,term,rxnMatchMeth,labelType,labelContent,score,rxn,gctui,combo_likely",
                                    rows = solr.row.req)
                    )
                  if (nrow(solr.result) > 0) {
                    solr.result$hit.count <- nrow(solr.result)
                    solr.result$solrsubmission <- current.query
                    solr.result$rank <- 1:nrow(solr.result)
                    return(solr.result)
                  }
                  
                }))


result.frame <- do.call(rbind.fill, via.solr)
print(dim(result.frame))

# 0.01% = 7400 searches
#

table(result.frame$rxnMatchMeth, useNA = 'always')
table(result.frame$labelType, useNA = 'always')
table(result.frame$combo_likely, useNA = 'always')

result.frame$rxnMatchMeth[is.na(result.frame$rxnMatchMeth)] <-
  "unmapped"
table(result.frame$rxnMatchMeth, useNA = 'always')

table(result.frame$rxnMatchMeth, result.frame$labelType, useNA = 'always')
table(result.frame$rxnMatchMeth, result.frame$combo_likely, useNA = 'always')

# append  ~ onto each "word" in search

# this won't work as expected for partial searches (solr.submission.fraction < 1)?
# or maybe it's OK since the LHS of the setdiff is the subset of actually submitted queries
# so change to unique queries retained?
solr.dropouts <-
  setdiff(unique.queries, result.frame$solrsubmission)
print(length(solr.dropouts))
print(sort(sample(solr.dropouts, 10)))
writeLines(solr.dropouts, "training_solr_dropuouts.txt")


###   ###   ###

result.frame <-
  merge(
    x = result.frame,
    y = uphs.plus.expanded,
    by.x = "solrsubmission",
    by.y  = "expanded",
    all.x = TRUE
  )

result.frame <- unique(result.frame)


result.frame$rxnifavailable <- NA


result.frame$rxnifavailable[!is.na(result.frame$rxn)] <-
  result.frame$rxn[!is.na(result.frame$rxn)]


native.rxn <-
  grepl(pattern = "^http://purl.bioontology.org/ontology/RXNORM/", x = result.frame$id)

result.frame$rxnifavailable[native.rxn] <-
  result.frame$id[native.rxn]

table(is.na(result.frame$rxnifavailable))


table(result.frame$rxnMatchMeth, result.frame$combo_likely, useNA = 'always')
table(is.na(result.frame$rxnifavailable),
      result.frame$combo_likely,
      useNA = 'always')

###

result.frame$combo_likely <- as.logical(result.frame$combo_likely)
table(result.frame$combo_likely, useNA = 'always')
result.frame$combo_likely[is.na(result.frame$combo_likely)] <- FALSE
table(result.frame$combo_likely, useNA = 'always')

result.frame.rxnavailable <- result.frame


###   ###   ###

## decided to not convert full URIs to prefixed style
## ie keep them all consistently full

# result.frame.rxnavailable$ontology <-
#   sub(pattern = "/submissions/15/download",
#       replacement = "",
#       x = result.frame.rxnavailable$ontology)
#
# result.frame.rxnavailable$ontology <-
#   sub(pattern = "^.*:.*/",
#       replacement = "",
#       x = result.frame.rxnavailable$ontology)

result.frame.rxnavailable$ontology <-
  make.names(result.frame.rxnavailable$ontology)

# result.frame.rxnavailable$labelType <-
#   sub(pattern = "^.*:.*#",
#       replacement = "",
#       x = result.frame.rxnavailable$labelType)
#
# result.frame.rxnavailable$labelType <-
#   sub(pattern = "^skos:",
#       replacement = "",
#       x = result.frame.rxnavailable$labelType)
#
# result.frame.rxnavailable$labelType <-
#   sub(pattern = "^rdfs:",
#       replacement = "",
#       x = result.frame.rxnavailable$labelType)

result.frame.rxnavailable$noproduct <-
  gsub(
    pattern = "@",
    replacement = " " ,
    x = result.frame.rxnavailable$labelContent,
    ignore.case = TRUE
  )

result.frame.rxnavailable$noproduct <-
  gsub(
    pattern = "product",
    replacement = "" ,
    x = result.frame.rxnavailable$noproduct,
    ignore.case = TRUE
  )

result.frame.rxnavailable$noproduct <-
  gsub(
    pattern = "containing",
    replacement = "" ,
    x = result.frame.rxnavailable$noproduct,
    ignore.case = TRUE
  )


###   ###   ###

result.frame.rxnavailable$qchars <-
  nchar(as.character(result.frame.rxnavailable$solrsubmission))

result.frame.rxnavailable$hchars <-
  nchar(as.character(result.frame.rxnavailable$labelContent))

result.frame.rxnavailable$qwords <-
  lengths(regmatches(
    result.frame.rxnavailable$solrsubmission,
    gregexpr("\\W", result.frame.rxnavailable$solrsubmission)
  ))

result.frame.rxnavailable$hwords <-
  lengths(regmatches(
    result.frame.rxnavailable$labelContent,
    gregexpr("\\W", result.frame.rxnavailable$labelContent)
  ))

###   ###   ###

ontology.freq <- table(result.frame.rxnavailable$ontology)

ontology.freq <-
  cbind.data.frame(names(ontology.freq), as.numeric(ontology.freq))

names(ontology.freq) <- c("ontology", "ontology.count")

# this is the only scaled feature.  leave it out or scale all of them
ontology.freq$relfreq <-
  ontology.freq$ontology.count / max(ontology.freq$ontology.count)

result.frame.rxnavailable <-
  merge(x = result.frame.rxnavailable,
        y = ontology.freq,
        by = "ontology",
        all.x = TRUE)

###   ###   ###

term.freq <- table(result.frame.rxnavailable$term)
term.freq <-
  cbind.data.frame(names(term.freq), as.numeric(term.freq))

names(term.freq) <- c("term", "term.count")

result.frame.rxnavailable <-
  merge(x = result.frame.rxnavailable,
        y = term.freq,
        by = "term",
        all.x = TRUE)


###   ###   ###

get.word.freqs <- function(term.vector) {
  text_df <-
    data_frame(line = 1:length(term.vector),
               text = as.character(term.vector))
  token.appearances <- text_df %>%
    unnest_tokens(word, text)
  token.counts <- table(token.appearances$word)
  token.counts <-
    cbind.data.frame(names(token.counts), as.numeric(token.counts))
  names(token.counts) <- c("token", "count")
  
  digit.start <-
    grepl(pattern = "^[[:digit:]]", x = token.counts$token)
  limited.solr.tokens <-
    token.counts[!digit.start & token.counts$count > 1, ]
  
  
  limited.solr.tokens$freq <-
    limited.solr.tokens$count / sum(limited.solr.tokens$count)
  return(limited.solr.tokens)
}

MedicationName.word.freqs <-
  get.word.freqs(result.frame.rxnavailable$MedicationName)

solrsubmission.word.freqs <-
  get.word.freqs(result.frame.rxnavailable$solrsubmission)

solr.hit.word.freqs <-
  get.word.freqs(result.frame.rxnavailable$noproduct)

head.to.head <- function(xframe, yframe, xsuff, ysuff) {
  head.to.head.tokens <-
    merge(
      x = xframe,
      y = yframe,
      by = "token",
      suffixes = c(xsuff, ysuff),
      all = TRUE
    )
  
  rownames(head.to.head.tokens) <- head.to.head.tokens$token
  
  keepers <-
    grep(pattern = "freq", x = colnames(head.to.head.tokens))
  
  head.to.head.tokens <-
    head.to.head.tokens[, keepers]
  
  head.to.head.tokens <- as.matrix(head.to.head.tokens)
  
  head.to.head.tokens[is.na(head.to.head.tokens)] <- 0
  
  head.to.head.tokens <- as.data.frame(head.to.head.tokens)
  
  head.to.head.tokens$diff <-
    scale(head.to.head.tokens[, 1] - head.to.head.tokens[, 2])
  
  return(head.to.head.tokens)
  
}

uphs.vs.expanded <- head.to.head(
  xframe = MedicationName.word.freqs,
  yframe = solrsubmission.word.freqs,
  xsuff = ".uphs",
  ysuff = ".expanded"
)

expanded.vs.solr.hit <- head.to.head(
  xframe = solrsubmission.word.freqs,
  yframe = solr.hit.word.freqs,
  xsuff = ".expanded",
  ysuff = ".solr"
)

uphs.vs.solr.hit <- head.to.head(
  xframe = MedicationName.word.freqs,
  yframe = solr.hit.word.freqs,
  xsuff = ".uphs",
  ysuff = ".solr"
)

###   ###   ###

# just feature generation and modeling from here on out?
result.frame.rxnavailable$rownum <-
  1:nrow(result.frame.rxnavailable)

rxnMatchMeth.frame <-
  result.frame.rxnavailable[, c("rownum", "rxnMatchMeth")]
rxnMatchMeth.frame$placeholder <- 1

start.time <- Sys.time()
rxnMatchMeth.cast <-
  reshape::cast(
    data = rxnMatchMeth.frame,
    formula = rownum ~ rxnMatchMeth,
    fun.aggregate = max,
    value = "placeholder"
  )
stop.time <- Sys.time()
cast.time <- stop.time - start.time
print(cast.time)

rxnMatchMeth.cast.rownames <- rxnMatchMeth.cast$rownum
rxnMatchMeth.cast.data <-
  as.matrix.data.frame(rxnMatchMeth.cast[, setdiff(names(rxnMatchMeth.cast), "rownum")])
rxnMatchMeth.cast.data[rxnMatchMeth.cast.data == -Inf] <- 0

rxnMatchMeth.colnames <-
  make.names(colnames(rxnMatchMeth.cast.data))

colnames(rxnMatchMeth.cast.data) <- rxnMatchMeth.colnames

rxnMatchMeth.cast <-
  cbind.data.frame(id = rxnMatchMeth.cast.rownames, rxnMatchMeth.cast.data)


result.frame.rxnavailable <-
  merge(
    x = result.frame.rxnavailable,
    y = rxnMatchMeth.cast,
    by.x = "rownum",
    by.y = "id",
    all = TRUE
  )

###   ###   ###

result.frame.rxnavailable$labelType <-
  make.names(result.frame.rxnavailable$labelType)

table(result.frame.rxnavailable$labelType)

result.frame.rxnavailable$prefLabSolrMatch <- 1
result.frame.rxnavailable$prefLabSolrMatch[result.frame.rxnavailable$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"] <-
  0

table(result.frame.rxnavailable$labelType)
table(result.frame.rxnavailable$prefLabSolrMatch)

###   ###   ###

result.frame.rxnavailable$rownum <-
  1:nrow(result.frame.rxnavailable)

result.frame.rxnavailable$labelType <-
  sub(pattern = "^.*:.*#",
      replacement = "",
      x = result.frame.rxnavailable$labelType)

SolrlabelType.frame <-
  result.frame.rxnavailable[, c("rownum", "labelType")]
SolrlabelType.frame$placeholder <- 1

start.time <- Sys.time()
SolrlabelType.cast <-
  reshape::cast(
    data = SolrlabelType.frame,
    formula = rownum ~ labelType,
    fun.aggregate = max,
    value = "placeholder"
  )
stop.time <- Sys.time()
cast.time <- stop.time - start.time
print(cast.time)

SolrlabelType.cast.rownames <- SolrlabelType.cast$rownum
SolrlabelType.cast.data <-
  as.matrix.data.frame(SolrlabelType.cast[, setdiff(names(SolrlabelType.cast), "rownum")])
SolrlabelType.cast.data[SolrlabelType.cast.data == -Inf] <- 0

SolrlabelType.cast.colnames <- colnames(SolrlabelType.cast.data)

SolrlabelType.cast <-
  cbind.data.frame(id = SolrlabelType.cast.rownames, SolrlabelType.cast.data)

result.frame.rxnavailable <-
  merge(
    x = result.frame.rxnavailable,
    y = SolrlabelType.cast,
    by.x = "rownum",
    by.y = "id",
    all = TRUE
  )

###   ###   ###

new.tui.frame <-
  unique(result.frame.rxnavailable[, c("term", "gctui")])
new.tui.frame <- new.tui.frame[order(new.tui.frame$term), ]
new.tui.frame <-
  apply(
    X = new.tui.frame,
    MARGIN = 1,
    FUN = function(current.row) {
      current.term <- current.row[['term']]
      current.tuis <- current.row[['gctui']]
      current.tuis <-
        sub(pattern = " +",
            replacement = " ",
            x = current.tuis)
      current.tuis <-
        sub(pattern = "^ ",
            replacement = "",
            x = current.tuis)
      current.tuis <-
        sub(pattern = " $",
            replacement = "",
            x = current.tuis)
      current.tuis <-
        unique(strsplit(x = current.tuis, split = " ")[[1]])
      if (length(current.tuis) > 0) {
        temp <-
          cbind.data.frame(rep(current.term, length(current.tuis)), current.tuis)
        return(temp)
      }
      
    }
  )

new.tui.frame <- rbindlist(new.tui.frame)
names(new.tui.frame) <- c("term", "tui")

new.tui.frame$placeholder <- 1

# is this too high (ie are we losing useful factors?)]
# if we retain levels that are too rare, it becomes a pain to ensure that they don't get into the validation data but not the training data
# use a single setting here for both TUIs and ontologies?
tui.freq.factor <- 0.01

tui.tab <- table(new.tui.frame$tui)
tui.tab <- cbind.data.frame(names(tui.tab), as.numeric(tui.tab))
names(tui.tab) <- c("tui", "count")
min.count <- max(tui.tab$count * tui.freq.factor)
common.tui.cols <- tui.tab$tui[tui.tab$count >= min.count]
new.tui.frame <-
  new.tui.frame[new.tui.frame$tui %in% common.tui.cols, ]

start.time <- Sys.time()
tui.cast <-
  reshape::cast(
    data = new.tui.frame,
    formula = term ~ tui,
    fun.aggregate = max,
    value = "placeholder"
  )
stop.time <- Sys.time()
tui.cast.time <- stop.time - start.time
print(tui.cast.time)

tui.cast.rownames <- tui.cast$term
tui.cast.data <-
  as.matrix.data.frame(tui.cast[, setdiff(names(tui.cast), "term")])
tui.cast.data[tui.cast.data == -Inf] <- 0

tui.cast <-
  cbind.data.frame(term = tui.cast.rownames, tui.cast.data)

result.frame.rxnavailable <-
  merge(
    x = result.frame.rxnavailable,
    y = tui.cast,
    by.x = "term",
    by.y = "term",
    all = TRUE
  )

###   ###   ###

result.frame.rxnavailable$rownum <-
  1:nrow(result.frame.rxnavailable)

precast <- result.frame.rxnavailable[, c("rownum", "ontology")]
precast$placeholder <- 1
precast$rownum <- as.numeric(precast$rownum)
precast <- unique(precast)
precast$ontology <- as.character(precast$ontology)

# see similar TUI freq cutoff
min.rel.freq <- 0.01

common.ontology.cols <-
  ontology.freq$ontology[ontology.freq$relfreq >= min.rel.freq]

precast <- precast[precast$ontology %in% common.ontology.cols, ]

start.time <- Sys.time()
print(start.time)
casted.ontfreqs <-
  reshape::cast(
    formula = rownum ~ ontology,
    fun.aggregate = max,
    value = "placeholder",
    data = precast
  )
stop.time <- Sys.time()
ontfreqs.cast.time <- stop.time - start.time
print(ontfreqs.cast.time)

casted.ontfreqs[casted.ontfreqs == -Inf] <- 0

casted.ontfreqs <- as.matrix(casted.ontfreqs)
casted.ontfreqs <- as.data.frame(casted.ontfreqs)

casted.ontfreqs <- unique(casted.ontfreqs)

result.frame.rxnavailable <-
  merge(x = result.frame.rxnavailable,
        y = casted.ontfreqs,
        by = "rownum",
        all.x = TRUE)

###   ###   ###

# that leaves NAs when the map ontolgy is rare and no casted ontofreq line gets merged back in

###   ###   ###

distance.cols = c("lv", "lcs", "qgram", "cosine", "jaccard", "jw")

distances <- lapply(distance.cols, function(one.meth) {
  print(one.meth)
  temp <-
    stringdist(
      a = result.frame.rxnavailable$solrsubmission,
      b = result.frame.rxnavailable$noproduct,
      method = one.meth,
      nthread = 4
    )
  return(temp)
})

distances <- do.call(cbind.data.frame, distances)
names(distances) <- distance.cols

result.frame.rxnavailable <-
  cbind.data.frame(result.frame.rxnavailable, distances)

### deleted yuck.sty thorugh
# pm.cols <- colnames(pm.states.temp)

###   ###   ###



backmerge <- result.frame.rxnavailable

backmerge.keepers <-
  c(
    "MedicationName",
    "source",
    "combo_likely",
    "solrsubmission",
    "term",
    "labelContent",
    "rxnifavailable",
    important.features
  )

backmerge <- backmerge[, backmerge.keepers]

backmerge <- unique(backmerge)

sneaky.sty <-
  grepl(pattern = "http://purl.bioontology.org/ontology/STY/", x = backmerge$rxnifavailable)

table(sneaky.sty, useNA = 'always')

# no, maybe keep them for prediction
# backmerge <- backmerge[!sneaky.sty,]

###


#  constant columns a concern for prediction?

print(table(backmerge$ontology, useNA = 'always'))

# add medrt and umd to training!
# maybe shouldn't train on ontology factor column, just the booleans

backmerge$ontology <-
  factor(
    backmerge$ontology,
    levels = c(
      "ftp...ftp.ebi.ac.uk.pub.databases.chebi.ontology.chebi.owl.gz",
      "https...bitbucket.org.uamsdbmi.dron.raw.master.dron.full.owl",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.ATC.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.CVX.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.DRUGBANK.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.GS.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MDDB.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMSL.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMX.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MTH.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_FDA.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_NCPDP.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDFRT.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.SPN.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USP.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USPMG.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.VANDF."
      # ,
      # "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MED.RT.",
      # "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.UMD."
    )
  )

print(table(backmerge$labelType, useNA = 'always'))

backmerge$labelType <-
  factor(
    backmerge$labelType,
    levels = c(
      "http...www.w3.org.2000.01.rdf.schema.label",
      "http...www.w3.org.2004.02.skos.core.altLabel" ,
      "http...www.w3.org.2004.02.skos.core.prefLabel"
    )
  )

# NA match methods shouldn't be possible for TRAINING
print(table(backmerge$rxnMatchMeth, useNA = 'always'))

table(is.na(backmerge$rxnMatchMeth))

backmerge$rxnMatchMeth[is.na(backmerge$rxnMatchMeth)] <- "unmapped"

sort(table(backmerge$rxnMatchMeth, useNA = 'always'))

backmerge$rxnMatchMeth <-
  factor(
    backmerge$rxnMatchMeth,
    levels = c(
      "CUI",
      "CUI; LOOM",
      "CUI; LOOM; non-BP-CUI",
      "CUI; non-BP-CUI",
      "DrOn assertion",
      "LOOM",
      "LOOM; non-BP-CUI",
      "RxNorm direct",
      "non-BP-CUI",
      "unmapped"
    )
  )

sort(table(backmerge$rxnMatchMeth, useNA = 'always'))

###   ###   ###

factvars <- c("ontology", "rxnMatchMeth", "labelType")

true.numericals <- c(
  as.character(distance.cols),
  "score",
  "hit.count",
  "rank",
  "qchars",
  "hchars",
  "qwords",
  "hwords",
  "ontology.count",
  "term.count"
)
actually.booleans <- c(
  as.character(common.ontology.cols),
  as.character(common.tui.cols),
  as.character(rxnMatchMeth.colnames),
  setdiff(as.character(SolrlabelType.cast.colnames), "NA")
)

numericals <-
  c(true.numericals, actually.booleans)


na.tracking <- apply(backmerge, 2, anyNA)
na.tracking <-
  cbind.data.frame(names(na.tracking), as.logical(na.tracking))
na.tracked <-
  as.character(na.tracking$`names(na.tracking)`[na.tracking$`as.logical(na.tracking)`])

print(intersect(factvars, na.tracked))

na.booleans <- intersect(actually.booleans, na.tracked)
print(na.booleans)

placeholder <- lapply(na.booleans, function(current.boolean) {
  print(current.boolean)
  temp <- backmerge[, current.boolean]
  temp[is.na(temp)] <- 0
  backmerge[, current.boolean] <<- temp
})

print(intersect(true.numericals, na.tracked))


###   ###   ###

# last chance to subset before doing the rf training!
# next.scaling <- 0.99

backmerge <- backmerge[!is.na(backmerge$ontology),]

# get confidences

rf_predictions <-
  predict(rf_classifier, backmerge, type = "response")

backmerge$rf_predicted_proximity <- rf_predictions

rf_predictions <- predict(rf_classifier, backmerge, type = "prob")

pred.col.names <- colnames(rf_predictions)

backmerge <- cbind.data.frame(backmerge, rf_predictions)


# last chance to deal with nddf alt labels

pred.useless <-
  backmerge[backmerge$rf_predicted_proximity == "FALSE-FALSE-FALSE-FALSE" ,]
pred.has.potential  <-
  backmerge[backmerge$rf_predicted_proximity != "FALSE-FALSE-FALSE-FALSE" ,]


pred.cols <- pred.has.potential[, pred.col.names]

max.prob <- apply(
  pred.cols,
  1,
  FUN = function(my.current.row) {
    return(max(my.current.row))
  }
)

pred.has.potential$max.prob <- max.prob

aggdata <-
  aggregate(
    pred.has.potential$max.prob,
    by = list(pred.has.potential$MedicationName),
    FUN = max,
    na.rm = TRUE
  )
names(aggdata) <- c("MedicationName", "max.prob")

pred.has.potential.max.prob <-
  merge(x = pred.has.potential,
        y = aggdata,
        by = c("MedicationName", "max.prob"))

pred.nddf.alt <-
  pred.has.potential[pred.has.potential$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
                       pred.has.potential$labelType == "http...www.w3.org.2004.02.skos.core.altLabel" , ]

only.useless <-
  setdiff(pred.has.potential.max.prob$MedicationName,
          pred.nddf.alt$MedicationName)
