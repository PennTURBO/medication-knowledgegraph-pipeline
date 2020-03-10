# review the code comments in previous versions and in this scripts current prediction counterpart

# run this with 100% of everything, but save the predictor so that it only processes a small portion
#  the Solr search phase for all FULL_NAMES takes > 8 hours

# save the scripts so that they don't write or save anything 
#  EXCEPT the Solr "pairs" RDF, which goes into the graphdb-import folder
#  that, and the loading of RF results into the graph are still areas for improvement

# still haven't excluded alt labels from NDDF (or chebi... chemical names)

# use faster merge (join) and cast (dcast) functions

# still need to do role inheritance

# back to:
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

uphs.subset.frac <- 1.0

solr.submission.fraction <- 1.0

solr.row.req <- 30

next.scaling <- 1.0

save.for.coverage.frac <- 0.1

train.frac <- 0.9

my.target <- "pastedProx"

my.form <-
  as.formula(paste0("as.factor(", my.target, ") ~ . "))

get.importance.Q <- FALSE
my.mtry <- 5
my.ntree <- 300
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
  # remove, so that a predicition-phase solr hit against a devices ontology can still be classified
  # "ontology",
  "T200",
  "ontology.count",
  "rxnMatchMeth",
  "http...www.w3.org.2004.02.skos.core.altLabel",
  "labelType",
  # add to make up for removing "ontology"
  "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM"
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

update.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo,
         "/statements")

post.dest <-
  paste0("http://localhost:7200/rest/data/import/server/",
         my.repo)


###  load and print reviously determined feature importance here

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
    {
        select 
        ?MedicationName
        (count(distinct ?pRXNORM_CODE_URI) as ?count)
        where {
            graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
                ?s rdf:type mydata:Row ;
                   #           mydata:SOURCE_CODE ?psource ;
                   mydata:FULL_NAME ?MedicationName .
            }
            graph mydata:pds_rxn_casts {
                ?s mydata:RXNORM_CODE_URI  ?pRXNORM_CODE_URI .
            }
        }
        group by
        ?MedicationName
        having (count(distinct ?pRXNORM_CODE_URI) = 1)
    }
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?s rdf:type mydata:Row ;
           #           mydata:SOURCE_CODE ?source ;
           mydata:FULL_NAME ?MedicationName .
        graph mydata:pds_rxn_casts {
            ?s mydata:RXNORM_CODE_URI  ?RXNORM_CODE_URI .
        }
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?RXNORM_CODE_URI a owl:Class ;
                         skos:prefLabel ?rxnlab .
    }
    graph <http://example.com/resource/mdm_ods_meds_source_supplement> {
        ?s mydata:SOURCE_CODE ?source .
    }
}
  '
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


###   ###   ###

uphs.with.current.rxnorm.frac <-
  complete.uphs.with.current.rxnorm[sample(
    nrow(complete.uphs.with.current.rxnorm),
    nrow(complete.uphs.with.current.rxnorm) * uphs.subset.frac
  ),]

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
                    solr.result$order <- current.query
                    solr.result$rank <- 1:nrow(solr.result)
                    return(solr.result)
                  }
                  
                }))


result.frame <- do.call(rbind.fill, via.solr)
print(dim(result.frame))

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
solr.dropouts <- setdiff(unique.queries, result.frame$order)
print(length(solr.dropouts))
print(sort(sample(solr.dropouts, 10)))
# writeLines(solr.dropouts, "training_solr_dropuouts.txt")


###   ###   ###

result.frame <-
  merge(
    x = result.frame,
    y = uphs.plus.expanded,
    by.x = "order",
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

result.frame.rxnavailable <-
  result.frame[(!is.na(result.frame$rxnifavailable)) &
                 (result.frame$combo_likely == FALSE),]


###   ###   ###

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
  nchar(as.character(result.frame.rxnavailable$order))

result.frame.rxnavailable$hchars <-
  nchar(as.character(result.frame.rxnavailable$labelContent))

result.frame.rxnavailable$qwords <-
  lengths(regmatches(
    result.frame.rxnavailable$order,
    gregexpr("\\W", result.frame.rxnavailable$order)
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

order.word.freqs <- get.word.freqs(result.frame.rxnavailable$order)

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
  yframe = order.word.freqs,
  xsuff = ".uphs",
  ysuff = ".expanded"
)

expanded.vs.solr.hit <- head.to.head(
  xframe = order.word.freqs,
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
      a = result.frame.rxnavailable$order,
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

# took some steps to dramatically reduce this recently, but still not down to 0

yucky.sty <-
  grepl(pattern = "http://purl.bioontology.org/ontology/STY", x = result.frame.rxnavailable$rxnifavailable)

table(yucky.sty)

result.frame.rxnavailable <-
  result.frame.rxnavailable[!yucky.sty,]

###   ###   ###

pairs.for.graph <-
  unique(result.frame.rxnavailable[, c("rxnifavailable", "RXNORM_CODE_URI")])

temp.rdf <- rrdf::new.rdf()

start.time <- Sys.time()
print(start.time)
placeholder <- apply(
  pairs.for.graph,
  MARGIN = 1,
  FUN = function(current.row) {
    uuid.temp <- UUIDgenerate()
    uuid.temp <- gsub(pattern = "-", replacement = "", uuid.temp)
    uuid.uri.temp <-
      paste0("http://example.com/resource/", uuid.temp)
    add.triple(
      store = temp.rdf,
      subject = uuid.uri.temp,
      predicate = "http://example.com/resource/rxnifavailable",
      object = current.row[["rxnifavailable"]]
    )
    add.triple(
      store = temp.rdf,
      subject = uuid.uri.temp,
      predicate = "http://example.com/resource/RXNORM_CODE_URI",
      object = current.row[["RXNORM_CODE_URI"]]
    )
    add.triple(
      store = temp.rdf,
      subject = uuid.uri.temp,
      predicate = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
      object = "http://example.com/resource/uphs_vs_solr_result"
    )
  }
)

stop.time <- Sys.time()
local.insert.time <- stop.time - start.time
print(local.insert.time)

tripleCount(temp.rdf)

###   ###   ###

# give file and graph the same name
# search term/result pairs, linkable to an active rxnrom term only, for non-combination drugs

saved.wd <- getwd()
setwd("/home/ubuntu/graphdb-import/")
file.remove("observed_uphs_solr_rxn_pairs.rdf")
Sys.sleep(time = 3)
save.rdf(store = temp.rdf, filename = "observed_uphs_solr_rxn_pairs.rdf")
setwd(saved.wd)

observed.pairs.clear.10 = "clear graph <http://example.com/resource/uphs_nonobsolete_rxn_vs_solr>"

print(Sys.time())
insert.result <-
  POST(update.endpoint, body = list(update = observed.pairs.clear.10))
print(insert.result$status_code)
print(insert.result$times)


bod4post <- '{
"fileNames": [
"observed_uphs_solr_rxn_pairs.rdf"
],
"importSettings": {
"baseURI": "file:/home/ubuntu/graphdb-import/observed_uphs_solr_rxn_pairs.rdf",
"context": "http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf",
"data": null,
"forceSerial": false,
"format": null,
"message": "Imported successfully",
"name": "observed_uphs_solr_rxn_pairs.rdf",
"parserSettings": {
"preserveBNodeIds": false,
"failOnUnknownDataTypes": false,
"verifyDataTypeValues": false,
"normalizeDataTypeValues": false,
"failOnUnknownLanguageTags": false,
"verifyLanguageTags": true,
"normalizeLanguageTags": false,
"verifyURISyntax": true,
"verifyRelativeURIs": true,
"stopOnError": true
},
"replaceGraphs": [],
"status": "DONE",
"type": "file"
}
}'

placeholder <- POST(post.dest,
                    body = bod4post,
                    content_type("application/json"),
                    accept("application/json"))

# 20 sec enough for 10% epic with non obsolete rxnorms, accepting all rxnorm levels
# if you're reading this now, we’re probably not doing exactly that anymore
# sleep.dur <- (epic.subset.frac * 200) + 40 ???

sleep.dur <- 100

print(sleep.dur)
print(Sys.time())
Sys.sleep(sleep.dur)

###   ###   ###

# is acceptible link really the best term here?  hop? relationship
# then change veracity below to proximity

assessment.inserts <- list(
  assessment.clear.10 = "clear graph <http://example.com/resource/solr_uphs_assessments>",
  assess.identical.insert.10 = "
PREFIX mydata: <http://example.com/resource/>
insert {
    graph mydata:solr_uphs_assessments {
        ?myRowId mydata:solr_uphs_same_term true
    }
}
where {
    graph <http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf> {
        ?myRowId a mydata:uphs_vs_solr_result ;
                 mydata:rxnifavailable ?shared ;
                 mydata:RXNORM_CODE_URI ?shared .
    }
}  ",
shared.parent.insert.20 = "
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
insert {
    graph mydata:solr_uphs_assessments {
        ?myRowId mydata:solr_uphs_shared_type ?parent
    }
}
where {
    graph <http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf> {
        ?myRowId a mydata:uphs_vs_solr_result ;
                 mydata:rxnifavailable ?rxnifavailable ;
                 mydata:RXNORM_CODE_URI ?RXNORM_CODE_URI .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxnifavailable rxnorm:isa ?parent .
        ?RXNORM_CODE_URI rxnorm:isa ?parent .
    }
}
  ",
one.acceptable.link.X = "
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX mydata: <http://example.com/resource/>
insert {
    graph mydata:solr_uphs_assessments {
        ?myRowId mydata:solr_uphs_acceptable_onehop true
    }
}
where {
    values ?p {
        rxnorm:has_tradename
        rxnorm:isa
        rxnorm:consists_of
        rxnorm:contains
        rxnorm:has_ingredient
        rxnorm:tradename_of
        rxnorm:contained_in
        rxnorm:has_quantified_form
        rxnorm:quantified_form_of
    }
    graph <http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf> {
        ?myRowId a <http://example.com/resource/uphs_vs_solr_result>;
                 <http://example.com/resource/RXNORM_CODE_URI> ?RXNORM_CODE_URI ;
                 <http://example.com/resource/rxnifavailable> ?rxnifavailable .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?RXNORM_CODE_URI skos:prefLabel ?el ;
                         ?p ?rxnifavailable .
        ?rxnifavailable skos:prefLabel ?sl .
    }
}  ",
two.acceptable.link.10s = "
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX mydata: <http://example.com/resource/>
insert {
    graph mydata:solr_uphs_assessments {
        ?myRowId mydata:solr_uphs_acceptable_twohop true
    }
}
where {
    values (?p1 ?p2) {
        ( <http://purl.bioontology.org/ontology/RXNORM/isa> <http://purl.bioontology.org/ontology/RXNORM/has_tradename> )
        ( <http://purl.bioontology.org/ontology/RXNORM/has_tradename> <http://purl.bioontology.org/ontology/RXNORM/consists_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/has_tradename> <http://purl.bioontology.org/ontology/RXNORM/isa> )
        ( <http://purl.bioontology.org/ontology/RXNORM/consists_of> <http://purl.bioontology.org/ontology/RXNORM/has_tradename> )
        ( <http://purl.bioontology.org/ontology/RXNORM/consists_of> <http://purl.bioontology.org/ontology/RXNORM/has_ingredient> )
        ( <http://purl.bioontology.org/ontology/RXNORM/isa> <http://purl.bioontology.org/ontology/RXNORM/has_ingredient> )
        ( <http://purl.bioontology.org/ontology/RXNORM/isa> <http://purl.bioontology.org/ontology/RXNORM/isa> )
        ( <http://purl.bioontology.org/ontology/RXNORM/has_tradename> <http://purl.bioontology.org/ontology/RXNORM/has_ingredient> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contains> <http://purl.bioontology.org/ontology/RXNORM/has_tradename> )
        ( <http://purl.bioontology.org/ontology/RXNORM/has_tradename> <http://purl.bioontology.org/ontology/RXNORM/contains> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contains> <http://purl.bioontology.org/ontology/RXNORM/consists_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/consists_of> <http://purl.bioontology.org/ontology/RXNORM/has_precise_ingredient> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contains> <http://purl.bioontology.org/ontology/RXNORM/isa> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contained_in> <http://purl.bioontology.org/ontology/RXNORM/has_tradename> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contained_in> <http://purl.bioontology.org/ontology/RXNORM/tradename_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/has_tradename> <http://purl.bioontology.org/ontology/RXNORM/contained_in> )
        ( <http://purl.bioontology.org/ontology/RXNORM/contains> <http://purl.bioontology.org/ontology/RXNORM/has_ingredient> )
        ( <http://purl.bioontology.org/ontology/RXNORM/consists_of> <http://purl.bioontology.org/ontology/RXNORM/tradename_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/isa> <http://purl.bioontology.org/ontology/RXNORM/tradename_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/quantified_form_of> <http://purl.bioontology.org/ontology/RXNORM/has_tradename> )
        ( <http://purl.bioontology.org/ontology/RXNORM/tradename_of> <http://purl.bioontology.org/ontology/RXNORM/consists_of> )
        ( <http://purl.bioontology.org/ontology/RXNORM/tradename_of> <http://purl.bioontology.org/ontology/RXNORM/contains> )
        ( <http://purl.bioontology.org/ontology/RXNORM/tradename_of> <http://purl.bioontology.org/ontology/RXNORM/isa> )
    }
    graph <http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf> {
        ?myRowId a <http://example.com/resource/uphs_vs_solr_result>;
                 <http://example.com/resource/RXNORM_CODE_URI> ?RXNORM_CODE_URI ;
                 <http://example.com/resource/rxnifavailable> ?rxnifavailable .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?RXNORM_CODE_URI skos:prefLabel ?el ;
                         ?p1  ?intermediate .
        ?intermediate skos:prefLabel ?il ;
                      ?p2  ?rxnifavailable .
        ?rxnifavailable skos:prefLabel ?sl .
    }
    filter(?RXNORM_CODE_URI != ?rxnifavailable)
}  "
)

placeholder <-
  lapply(names(assessment.inserts), function(current.update) {
    print(current.update)
    print(Sys.time())
    current.statement <- assessment.inserts[[current.update]]
    # cat(current.statement)
    insert.result <-
      POST(update.endpoint, body = list(update = current.statement))
    
    print(insert.result$status_code)
    print(insert.result$times)
    
  })

###   ###   ###

proximity.query <- "
PREFIX mydata: <http://example.com/resource/>
#PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
distinct ?RXNORM_CODE_URI ?rxnifavailable ?sameTerm ?sharedParent ?oneLink ?twoLinks
where {
    graph <http://example.com/resource/observed_uphs_solr_rxn_pairs.rdf> {
        ?myRowId a mydata:uphs_vs_solr_result ;
                 mydata:rxnifavailable ?rxnifavailable ;
                 mydata:RXNORM_CODE_URI ?RXNORM_CODE_URI .
    }
    graph mydata:solr_uphs_assessments {
        optional {
            ?myRowId mydata:solr_uphs_acceptable_twohop ?thr
        }
        optional {
            ?myRowId mydata:solr_uphs_acceptable_onehop ?ohr
        }
        optional {
            ?myRowId mydata:solr_uphs_shared_type ?parent
        }
        optional {
            ?myRowId mydata:solr_uphs_same_term ?sameraw
        }
        bind(bound(?thr) as ?twoLinks)
        bind(bound(?ohr) as ?oneLink)
        bind(bound(?parent) as ?sharedParent)
        bind(bound(?sameraw) as ?sameTerm)
    }
}
"

# 5 minutes for 10% of epic with non-obsolete rxnomrs of any level

time.start <-  Sys.time()
print(time.start)
proximity_measures <-
  sparql.remote(endpoint = sparql.endpoint,
                sparql = proximity.query,
                jena = TRUE)
time.stop <-  Sys.time()
time.duration <- time.stop - time.start
print(time.duration)

proximity_measures <- as.data.frame(proximity_measures)

# I used to struggle to keep the term URIs all succinct
# then I gave up
# proximity_measures[, "RXNORM_CODE_URI"] <-
#   sub(pattern = "^rxnorm:",
#       replacement = "http://purl.bioontology.org/ontology/RXNORM/",
#       x = proximity_measures[, "RXNORM_CODE_URI"])
#
# proximity_measures[, "rxnifavailable"] <-
#   sub(pattern = "^rxnorm:",
#       replacement = "http://purl.bioontology.org/ontology/RXNORM/",
#       x = proximity_measures[, "rxnifavailable"])

table(proximity_measures$sameTerm, useNA = 'always')

table(proximity_measures$sharedParent, useNA = 'always')

table(proximity_measures$oneLink, useNA = 'always')

table(proximity_measures$twoLinks, useNA = 'always')

pm.uris <-
  proximity_measures[, c("RXNORM_CODE_URI", "rxnifavailable")]
pm.states <-
  as.data.frame(proximity_measures[, c("sameTerm", "sharedParent", "oneLink", "twoLinks")])

pm.states[] <- lapply(pm.states[], as.logical)

pm.states.temp <- lapply(pm.states[], as.character)
pm.states.temp <-
  cbind.data.frame(pm.states.temp, stringsAsFactors = FALSE)

cols <- colnames(pm.states.temp)

# create a new column "pastedProx" with the three columns collapsed together
# -> becomes a multi-class problem instead of a multi-label problem
pm.states.temp$pastedProx <-
  apply(pm.states.temp[, cols] , 1 , paste , collapse = "-")

proximity_measures <-
  cbind.data.frame(pm.uris, pm.states, pastedProx = pm.states.temp$pastedProx)
pm.cols <- colnames(pm.states.temp)

###   ###   ###

backmerge <- merge(
  x = result.frame.rxnavailable,
  y = proximity_measures,
  by.x = c("rxnifavailable",  "RXNORM_CODE_URI"),
  by.y = c("rxnifavailable",  "RXNORM_CODE_URI"),
  all  = TRUE
)

backmerge <- unique(backmerge)

# save.image("up_to_backmerge_201904091600.Rdata")

###   ###   ###

# complete cases takes care of all NA removal!
backmerge <- backmerge[complete.cases(backmerge),]


# apply MRB's feedback in advance of training
# is this relevant for ChEBI alternative labels?
#oboInOwl:hasRelatedSynonym	
#oboInOwl:hasExactSynonym	
# haven't been including those in the Solr... 
# tends to include structural/empirical formulae in addition to pharmaceutical/clinical names

backmerge <-
  backmerge[!(backmerge$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
                backmerge$labelType == "http...www.w3.org.2004.02.skos.core.altLabel") , ]

# sneaky.sty <-
#   grepl(pattern = "http://purl.bioontology.org/ontology/STY/", x = backmerge$rxnifavailable)
#
# table(sneaky.sty, useNA = 'always')
#
# backmerge <- backmerge[!sneaky.sty,]
#
# na.tracking <- apply(backmerge, 2, anyNA)
# na.tracking <-
#   cbind.data.frame(names(na.tracking), as.logical(na.tracking))
#
# # where are these nas coming from?  looks like rxnorm paiings that didn't merege with any serach results
#
#
# backmerge <- backmerge[complete.cases(backmerge),]
# na.tracking <-
#   na.tracking$`names(na.tracking)`[na.tracking$`as.logical(na.tracking)`]
# na.tracking <- as.character(na.tracking)
#
#
# lapply(na.tracking, function(current.col) {
#   print(current.col)
#   print(table(backmerge[, current.col], useNA = 'always'))
#   temp <- backmerge[, current.col]
#   print(table(temp, useNA = 'always'))
#   if (current.col == "gctui") {
#     print("textual gctui")
#     temp[is.na(temp)] <- ""
#   } else {
#     print("other boolean")
#     temp[is.na(temp)] <- 0
#   }
#   print(table(temp, useNA = 'always'))
#   backmerge[, current.col] <<- temp
#   return("placeholder")
# })


###

# should also look for constant columns

###

col.name.list <- names(backmerge)
placeholder <- lapply(col.name.list, function(current.col) {
  print(current.col)
  temp <- length(unique(backmerge[, current.col]))
  return(list(current.col, temp))
})
unique.count.frame <- do.call(rbind.data.frame, placeholder)

# will have to reassess after searching all 100% of orders
# only did 30% so far
# looks like rxnorm graph didn't include the trailing /
# go back to just most significant portion?
#   ie substitute out "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current." ?

print(table(backmerge$ontology, useNA = 'always'))

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
    )
  )

# dput(levels(backmerge$ontology))

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

# dput(levels(backmerge$labelType))

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

# dput(levels(backmerge$rxnMatchMeth))
sort(table(backmerge$rxnMatchMeth, useNA = 'always'))

###   ###   ###

factvars <- c("ontology", "rxnMatchMeth", "labelType")

numericals <-
  c(
    "score",
    "hit.count",
    "rank",
    "qchars",
    "hchars",
    "qwords",
    "hwords",
    "ontology.count",
    "term.count",
    as.character(common.ontology.cols),
    as.character(common.tui.cols),
    as.character(distance.cols),
    as.character(rxnMatchMeth.colnames),
    setdiff(as.character(SolrlabelType.cast.colnames), "NA")
  )

###   ###   ###

# last chance to subset before doing the rf training!
next.scaling <- 0.99

all.med.names <- unique(as.character(backmerge$MedicationName))

coverage.meds <-
  sample(x = all.med.names, length(all.med.names) * save.for.coverage.frac)

coverage.frame <-
  backmerge[backmerge$MedicationName %in% coverage.meds ,]

coverage.frame <- coverage.frame[complete.cases(coverage.frame), ]

train.val.frame <-
  backmerge[!backmerge$MedicationName %in% coverage.meds ,]

train.val.frame <-
  train.val.frame[complete.cases(train.val.frame), ]

train.val.frame <-
  train.val.frame[sample(nrow(train.val.frame), (nrow(train.val.frame) * next.scaling)) , ]

train.count <- nrow(train.val.frame) * train.frac

all.rownames <- rownames(train.val.frame)

train.rownums <-
  sample(x = all.rownames,
         size = train.count,
         replace = FALSE)

train.rows.pre <-
  train.val.frame[train.rownums , ]

val.rows.pre <-
  train.val.frame[setdiff(all.rownames, train.rownums), ]

trainframe <-
  train.rows.pre[complete.cases(train.rows.pre), ]

# important features may not be defined yet
# important.features <- c(sort(factvars), sort(numericals))
# important.features <- empirically.important

numericals <-
  intersect(as.character(numericals), as.character(important.features))

# dont.forget.cols <- setdiff(colnames(backmerge), important.features)
#
# dont.forget.frame <-  trainframe[, dont.forget.cols]

# sort(names(trainframe))
# sort(important.features)

trainframe <-
  trainframe[, c(my.target, as.character(important.features))]

###   ###   ###

tf.numericals <- trainframe[, numericals]

# must elimiate columns wth sd of 0
# and also columns witha  single constanat value... already doing this soemhwere else?
# this might have soethig to do with the hard coded factors lists above

constant.check <- lapply(tf.numericals[], sd)
constant.check <-
  cbind.data.frame(names(constant.check), as.numeric(constant.check))
constant.check <-
  constant.check$`names(constant.check)`[constant.check$`as.numeric(constant.check)` == 0]

numericals <- setdiff(numericals, constant.check)
trainframe <-
  trainframe[, setdiff(names(trainframe), constant.check)]

tf.numericals <- trainframe[, numericals]

tfn.cor <- cor(tf.numericals)

print(sd(tfn.cor) * 2)

hist(tfn.cor, breaks = 99)

tfn.cor.abs <- abs(tfn.cor)

hist(tfn.cor.abs, breaks = 99)

tfn.excessive <-
  findCorrelation(tfn.cor.abs,
                  cutoff = 0.4,
                  verbose = TRUE,
                  names = TRUE)

# print(names(tf.numericals)[tfn.excessive])

tfn.cor.succinct <- tfn.cor
succinct.names <- rownames(tfn.cor.succinct)
succinct.names <-
  sub(pattern = "\\.$", replacement = "", succinct.names)
succinct.names <-
  sub(pattern = "^http.*\\.", replacement = "", succinct.names)
succinct.names <-
  sub(pattern = "^ftp.*\\.", replacement = "", succinct.names)
rownames(tfn.cor.succinct) <- succinct.names
colnames(tfn.cor.succinct) <- succinct.names

# could also do this before discarding unimportant factors (see documentation)

heatmap(
  tfn.cor.succinct,
  col = brewer.pal(11, "RdBu"),
  scale = "none",
  # trace = "none",
  margins = c(11, 11)
)

###   ###   ###

print(Sys.time())
timed.system <- system.time(
  rf_classifier <- randomForest(
    my.form ,
    data = trainframe,
    ntree = my.ntree,
    mtry = my.mtry,
    get.importance = FALSE
  )
)

###   ###   ###

# validation and coverage calculations

rf_predictions <- predict(rf_classifier, val.rows.pre)
confusionMatrix(rf_predictions, val.rows.pre$pasted)

coverage_predictions <- predict(rf_classifier, coverage.frame)

print(table(coverage_predictions))

covered.meds <-
  unique(coverage.frame$MedicationName[coverage_predictions != "FALSE-FALSE-FALSE-FALSE"])
uncovered.meds <- setdiff(coverage.meds, covered.meds)

coverage.for.pre.rxned <-
  length(covered.meds) / length(coverage.meds)

print(coverage.for.pre.rxned)

###   ###   ###

# save(rf_classifier,file = "turbo_med_mapping_rf_classifier_no_nddf_alt.Rdata")
