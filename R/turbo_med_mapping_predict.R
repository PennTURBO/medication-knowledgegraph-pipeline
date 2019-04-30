# add source-specific accounting (theradoc, emtrac, epic, sunrise...)

# for hard-to classify drugs... how often were they actually ordered?  maybe only epic and sunrise show up in orders table?

# instead of winner takes all (keep the one highest probability prediction, as long as it isn't FALSE-FALSE-FALSE-FALSE)
#  use the multiple predictions to find the most likely neighborhood in the graph?

# try solr ~ fuzzy operator 

# don't train on ontology factor?, because training data won't have anything that doesn't have an rxnorm, like devices?

# make sure that any train code posted to github uses 1.0 for graphdb, solr and rf submission fractions
# make sure that any prediction code posted to github uses 1.0 for solr and rf submission fractions
#   but something small for the iniital graphdb search
# leave all writes and saves commented out

# OK, DONE ... still haven't excluded alt labels from NDDF (or chebi... chemical names) BEFORE TRAINING

# for training, make sure we're really filtering on rxnorm count == 1 (SPARQL),
#   non combination drug (solr but could be done in more complex SPARQL)
# for predicting, exclude medication that already have an rxnorm assignment in PDS but keep combination drugs

# also include pk med id?

# lots of redundant code between train and predict

# use faster merge (join) and cast (dcast) functions
# unique steps slowest now?
# save all for later?

# still need to do role inheritance (MRB cares less about this?)
# save csv, get into graphdb via StarDog virtual graph... need to get better at that, like no coering URIs to strings

# make sure creation of <http://example.com/resource/mdm_ods_meds_source_supplement> is documented

# have gone back to:
#   pm.states <- as.data.frame(proximity_measures[, c("sameTerm", "sharedParent", "oneLink", "twoLinks")])

options(java.parameters = "-Xmx32g")
# options(java.parameters = "-Xmx8g")

# new, make sure installed system wide


# document system dependencies like xml, openssl...
# i thought the joins came from here!
# library(data.table)
# not here
library(plyr)
library(dplyr)
# does the order l=of laoding plyr and dplyr matter?
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
# library(plyr)
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

my.target <- "pastedProx"

###  load and print reviously determined feature importance here
# load("turbo_med_mapping_rf_classifier.Rdata")
load("/terabyte/turbo_med_mapping_rf_classifier_no_nddf_alt.Rdata")

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
?s ?PK_MEDICATION_ID ?MedicationName ?RXNORM_CODE_URI ?source ?rxnlab
where
{
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?s rdf:type mydata:Row ;
           mydata:FULL_NAME ?MedicationName ;
           mydata:PK_MEDICATION_ID ?PK_MEDICATION_ID .
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

# Time difference of 2.962501 mins
#
#   > nrow(complete.uphs.with.current.rxnorm)
# [1] 937954
#
#   > table(complete.uphs.with.current.rxnorm[, "source"])
# EMTRAC     EPIC      SCM THERADOC
# 424637   181930   245922    85465


###   ###   ###

complete.uphs.with.current.rxnorm <-
  complete.uphs.with.current.rxnorm[sample(
    nrow(complete.uphs.with.current.rxnorm),
    nrow(complete.uphs.with.current.rxnorm) * uphs.subset.frac
  ),]


# hgf_flag <- complete.uphs.with.current.rxnorm[,3] %in% hgf_api_only
# table(hgf_flag)
# 
# complete.uphs.with.current.rxnorm <- complete.uphs.with.current.rxnorm[hgf_flag,]
# 
# dim(complete.uphs.with.current.rxnorm)
# # [1] 37939     6

temp <- is.na(complete.uphs.with.current.rxnorm[, "RXNORM_CODE_URI"])
table(temp)
 
# complete.uphs.with.current.rxnorm <-
#   complete.uphs.with.current.rxnorm[temp,]

###   ###   ###

queries <-
  as.character(complete.uphs.with.current.rxnorm[, "MedicationName"])

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

complete.uphs.with.current.rxnorm <-
  unique(as.data.frame(complete.uphs.with.current.rxnorm))

queries <-
  unique(queries)

uphs.plus.expanded <-
  merge(
    x = complete.uphs.with.current.rxnorm,
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

# pre.result.frame <- do.call(rbind.fill, via.solr)

# 
# ###   ###   ###
# 
# load("/terabyte/result_frame_201904200910.Rdata")
# 
# gc()
# 
# prfl <- nrow(pre.result.frame)
# prf.probs <- runif(prfl)
# 
# solr.result.retention <- 1.0
# 
# result.frame <- pre.result.frame[prf.probs > (1 - rf.portion) ,]

print(dim(result.frame))
length(unique(result.frame$solrsubmission))

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

# append  ~ onto each "word" in search ?

# this won't work as expected for partial searches (solr.submission.fraction < 1)?
# or maybe it's OK since the LHS of the setdiff is the subset of actually submitted queries
# so change to unique queries retained?
solr.dropouts <-
  setdiff(unique.queries, result.frame$solrsubmission)
print(length(solr.dropouts))
print(sort(sample(solr.dropouts, 10)))
# writeLines(solr.dropouts, "prediction_solr_dropuouts_201904200752.txt")

###   ###   ###

start.time <-  Sys.time()
print(start.time)
result.frame <-
  left_join(x = result.frame,
            y = uphs.plus.expanded,
            by = c("solrsubmission" = "expanded"))
end.time <-  Sys.time()
print(end.time - start.time)

# result.frame <- unique(result.frame)

###   ###   ###

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

# result.frame.rxnavailable <- result.frame

###   ###   ###

## decided to not convert full URIs to prefixed style
## ie keep them all consistently full

# #slow and inefficient
# start.time <- Sys.time()
#
# result.frame$ontology <-
#   make.names(result.frame$ontology)
#
# end.time <- Sys.time()
# print(end.time  - start.time)

# 0.01 fraction:
# Time difference of 3.611061 secs

# 0.10 fraction:
# Time difference of 35.84793 secs

###

start.time <- Sys.time()
result.frame$ontology <-
  factor(
    x = result.frame$ontology,
    levels = c(
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/CVX/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/DRUGBANK/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/GS/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MDDB/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MED-RT/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMSL/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMX/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MTH/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_FDA/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_NCPDP/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDFRT/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/SPN/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/ATC/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/UMD/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USP/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USPMG/",
      "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/VANDF/",
      "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz",
      "https://bitbucket.org/uamsdbmi/dron/raw/master/dron-full.owl"
    ),
    labels = c(
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.CVX.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.DRUGBANK.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.GS.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MDDB.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MED.RT.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMSL.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMX.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MTH.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_FDA.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_NCPDP.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDFRT.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.SPN.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.ATC.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.UMD.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USP.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USPMG.",
      "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.VANDF.",
      "ftp...ftp.ebi.ac.uk.pub.databases.chebi.ontology.chebi.owl.gz",
      "https...bitbucket.org.uamsdbmi.dron.raw.master.dron.full.owl"
    )
  )

end.time <- Sys.time()
print(end.time  - start.time)

# Time difference of 0.9170771 secs @ 0.01

###

# result.frame$labelType <-
#   sub(pattern = "^.*:.*#",
#       replacement = "",
#       x = result.frame$labelType)
#
# result.frame$labelType <-
#   sub(pattern = "^skos:",
#       replacement = "",
#       x = result.frame$labelType)
#
# result.frame$labelType <-
#   sub(pattern = "^rdfs:",
#       replacement = "",
#       x = result.frame$labelType)

result.frame$noproduct <-
  gsub(
    pattern = "@",
    replacement = " " ,
    x = result.frame$labelContent,
    ignore.case = TRUE
  )

result.frame$noproduct <-
  gsub(
    pattern = "product",
    replacement = "" ,
    x = result.frame$noproduct,
    ignore.case = TRUE
  )

result.frame$noproduct <-
  gsub(
    pattern = "containing",
    replacement = "" ,
    x = result.frame$noproduct,
    ignore.case = TRUE
  )


###   ###   ###

result.frame$qchars <-
  nchar(as.character(result.frame$solrsubmission))

result.frame$hchars <-
  nchar(as.character(result.frame$labelContent))

#  much slower than charcters

result.frame$qwords <-
  lengths(regmatches(
    result.frame$solrsubmission,
    gregexpr("\\W", result.frame$solrsubmission)
  ))

# could be calculated on unique hit terms and then merged out?

result.frame$hwords <-
  lengths(regmatches(
    result.frame$labelContent,
    gregexpr("\\W", result.frame$labelContent)
  ))

###   ###   ###

ontology.freq <- table(result.frame$ontology)

ontology.freq <-
  cbind.data.frame(names(ontology.freq), as.numeric(ontology.freq))

names(ontology.freq) <- c("ontology", "ontology.count")

# this is the only scaled feature.  leave it out or scale all of them
ontology.freq$relfreq <-
  ontology.freq$ontology.count / max(ontology.freq$ontology.count)

result.frame <-
  left_join(x = result.frame, y = ontology.freq, by = "ontology")

###   ###   ###

term.freq <- table(result.frame$term)
term.freq <-
  cbind.data.frame(names(term.freq), as.numeric(term.freq))

names(term.freq) <- c("term", "term.count")

result.frame <-
  left_join(x = result.frame, y = term.freq, by = "term")


###   ###   ###

# this isn't really in the most logical location

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
  get.word.freqs(result.frame$MedicationName)

solrsubmission.word.freqs <-
  get.word.freqs(result.frame$solrsubmission)

solr.hit.word.freqs <-
  get.word.freqs(result.frame$noproduct)

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
result.frame$rownum <-
  1:nrow(result.frame)

rxnMatchMeth.frame <-
  result.frame[, c("rownum", "rxnMatchMeth")]
rxnMatchMeth.frame$placeholder <- 1


###   ###   ###

start.time <- Sys.time()
rxnMatchMeth.cast <- dcast(
  data = rxnMatchMeth.frame,
  formula = rownum ~ rxnMatchMeth,
  fun.aggregate = max,
  value.var = "placeholder"
)
stop.time <- Sys.time()
cast.time <- stop.time - start.time
print(cast.time)

# Warning message:
#   In .fun(.value[0], ...) : no non-missing arguments to max; returning -Inf

rxnMatchMeth.cast.rownames <- rxnMatchMeth.cast$rownum
rxnMatchMeth.cast.data <-
  as.matrix.data.frame(rxnMatchMeth.cast[, setdiff(names(rxnMatchMeth.cast), "rownum")])
rxnMatchMeth.cast.data[rxnMatchMeth.cast.data == -Inf] <- 0

# re-factoring faster
rxnMatchMeth.colnames <-
  make.names(colnames(rxnMatchMeth.cast.data))

colnames(rxnMatchMeth.cast.data) <- rxnMatchMeth.colnames

rxnMatchMeth.cast <-
  cbind.data.frame(id = rxnMatchMeth.cast.rownames, rxnMatchMeth.cast.data)

###   ###   ###

result.frame <-
  left_join(x = result.frame,
            y = rxnMatchMeth.cast,
            by = c("rownum" = "id"))

###   ###   ###

# re-factoring faster
result.frame$labelType <-
  make.names(result.frame$labelType)

table(result.frame$labelType)

## pnly do this if you think it's going to be an important  feature
# result.frame$prefLabSolrMatch <- 1
# result.frame$prefLabSolrMatch[result.frame$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"] <-
#   0
# 
# table(result.frame$labelType)
# table(result.frame$prefLabSolrMatch)

###   ###   ###

result.frame$rownum <-
  1:nrow(result.frame)

result.frame$labelType <-
  sub(pattern = "^.*:.*#",
      replacement = "",
      x = result.frame$labelType)

SolrlabelType.frame <-
  result.frame[, c("rownum", "labelType")]
SolrlabelType.frame$placeholder <- 1

start.time <- Sys.time()
SolrlabelType.cast <-
  dcast(
    data = SolrlabelType.frame,
    formula = rownum ~ labelType,
    fun.aggregate = max,
    value.var = "placeholder"
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

result.frame <-
  left_join(x = result.frame,
            y = SolrlabelType.cast,
            by = c("rownum" = "id"))

###   ###   ###

new.tui.frame <-
  unique(result.frame[, c("term", "gctui")])
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
  dcast(
    data = new.tui.frame,
    formula = term ~ tui,
    fun.aggregate = max,
    value.var = "placeholder"
  )
stop.time <- Sys.time()
tui.cast.time <- stop.time - start.time
print(tui.cast.time)

tui.cast.rownames <- tui.cast$term

tui.cast.data <- tui.cast[, 2:ncol(tui.cast)]
tui.cast.data <- as.matrix(tui.cast.data)

# as.matrix.data.frame(tui.cast[, setdiff(names(tui.cast), "term")])
tui.cast.data[tui.cast.data == -Inf] <- 0

tui.cast <-
  cbind.data.frame(term = tui.cast.rownames, tui.cast.data)

result.frame <-
  left_join(x = result.frame,
            y = tui.cast,
            by = "term")

###   ###   ###

result.frame$rownum <-
  1:nrow(result.frame)

precast <- result.frame[, c("rownum", "ontology")]
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
  dcast(
    formula = rownum ~ ontology,
    fun.aggregate = max,
    value.var = "placeholder",
    data = precast
  )
stop.time <- Sys.time()
ontfreqs.cast.time <- stop.time - start.time
print(ontfreqs.cast.time)

casted.ontfreqs[casted.ontfreqs == -Inf] <- 0

casted.ontfreqs <- as.matrix(casted.ontfreqs)
casted.ontfreqs <- as.data.frame(casted.ontfreqs)

casted.ontfreqs <- unique(casted.ontfreqs)

###   ###   ###

gc()

# # does this help, hurt or neutral
# colnames(casted.ontfreqs) <- make.names(colnames(casted.ontfreqs))

result.frame <-
  left_join(x = result.frame,
            y = casted.ontfreqs,
            by = "rownum")


temp <-
  table(
    result.frame$ontology,
    result.frame$https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM,
    useNA = 'always'
  )
temp <- as.data.frame.matrix(temp)

# temp <- as.matrix.data.frame(temp)
###   ###   ###

# that leaves NAs when the map ontolgy is rare and no casted ontofreq line gets merged back in

###   ###   ###

distance.cols = c("lv", "lcs", "qgram", "cosine", "jaccard", "jw")

distances <- lapply(distance.cols, function(one.meth) {
  print(one.meth)
  temp <-
    stringdist(
      a = result.frame$solrsubmission,
      b = result.frame$noproduct,
      method = one.meth,
      nthread = 4
    )
  return(temp)
})

distances <- do.call(cbind.data.frame, distances)
names(distances) <- distance.cols

result.frame <-
  cbind.data.frame(result.frame, distances)

### deleted yuck.sty thorugh
# pm.cols <- colnames(pm.states.temp)

###   ###   ###


# backmerge <- result.frame.rxnavailable

backmerge.keepers <-
  c(
    "MedicationName",
    "PK_MEDICATION_ID",
    "s",
    "source",
    "combo_likely",
    "solrsubmission",
    "labelContent",
    "term",
    "ontology",
    "rxnifavailable",
    important.features
  )

result.frame <- result.frame[, backmerge.keepers]

# print(length(result.frame))
# # 27 660 551
# result.frame <- unique(result.frame)
# print(nrow(result.frame))
# # 27 797 363 ?!
# # 30 minutes... not worth it

sneaky.sty <-
  grepl(pattern = "http://purl.bioontology.org/ontology/STY/", x = result.frame$rxnifavailable)

table(sneaky.sty, useNA = 'always')

# no, maybe keep them for prediction
# result.frame <- result.frame[!sneaky.sty,]

###


#  constant columns a concern for prediction?

print(table(result.frame$ontology, useNA = 'always'))

# add medrt and umd to training!
# maybe shouldn't train on ontology factor column, just the booleans

# result.frame$ontology <-
#   factor(
#     result.frame$ontology,
#     levels = c(
#       "ftp...ftp.ebi.ac.uk.pub.databases.chebi.ontology.chebi.owl.gz",
#       "https...bitbucket.org.uamsdbmi.dron.raw.master.dron.full.owl",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.ATC.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.CVX.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.DRUGBANK.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.GS.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MDDB.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMSL.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMX.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MTH.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_FDA.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_NCPDP.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDFRT.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.SPN.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USP.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USPMG.",
#       "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.VANDF."
#       # ,
#       # "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MED.RT.",
#       # "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.UMD."
#     )
#   )

print(table(result.frame$labelType, useNA = 'always'))

result.frame$labelType <-
  factor(
    result.frame$labelType,
    levels = c(
      "http...www.w3.org.2000.01.rdf.schema.label",
      "http...www.w3.org.2004.02.skos.core.altLabel" ,
      "http...www.w3.org.2004.02.skos.core.prefLabel"
    )
  )

# NA match methods shouldn't be possible for TRAINING
print(table(result.frame$rxnMatchMeth, useNA = 'always'))

table(is.na(result.frame$rxnMatchMeth))

result.frame$rxnMatchMeth[is.na(result.frame$rxnMatchMeth)] <- "unmapped"

sort(table(result.frame$rxnMatchMeth, useNA = 'always'))

result.frame$rxnMatchMeth <-
  factor(
    result.frame$rxnMatchMeth,
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

sort(table(result.frame$rxnMatchMeth, useNA = 'always'))

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

print(dim(result.frame))
# result.frame <- unique(result.frame)
# print(dim(result.frame))

na.tracking <- apply(result.frame, 2, anyNA)
na.tracking <-
  cbind.data.frame(names(na.tracking), as.logical(na.tracking))
na.tracked <-
  as.character(na.tracking$`names(na.tracking)`[na.tracking$`as.logical(na.tracking)`])

print(intersect(factvars, na.tracked))
# action?  for now, just ontology, which isn't used in trianing
# temp <- result.frame[is.na(result.frame$ontology) ,]

# all from med rt?

na.booleans <- intersect(actually.booleans, na.tracked)
print(na.booleans)

placeholder <- lapply(na.booleans, function(current.boolean) {
  print(current.boolean)
  temp <- result.frame[, current.boolean]
  temp[is.na(temp)] <- 0
  result.frame[, current.boolean] <<- temp
})

na.numericals <- intersect(true.numericals, na.tracked)
print(na.numericals)


placeholder <- lapply(na.numericals, function(current.numerical) {
  print(current.numerical)
  temp <- result.frame[, current.numerical]
  temp.mean <- mean(temp, na.rm = TRUE)
  print(temp.mean)
  temp[is.na(temp)] <- temp.mean
  result.frame[, current.numerical] <<- temp
})


# # short term fix... 2 NA cosines?
# print(intersect(true.numericals, na.tracked))
# # [1] "cosine"
# table(is.na(result.frame$cosine))
# 
# # FALSE     TRUE
# # 26564166        2
# print(mean(result.frame$cosine, na.rm = TRUE))
# # [1] 0.2085572
# 
# temp <- result.frame[is.na(result.frame$cosine) , ]
# 
# result.frame$cosine[is.na(result.frame$cosine)] <-
#   mean(result.frame$cosine, na.rm = TRUE)

###   ###   ###

# last chance to subset before doing the rf training!
# next.scaling <- 0.99

rf_predictions <-
  predict(rf_classifier, result.frame, type = "response")

result.frame$rf_predicted_proximity <- rf_predictions

rf_predictions <-
  predict(rf_classifier, result.frame, type = "prob")

pred.col.names <- colnames(rf_predictions)

result.frame <- cbind.data.frame(result.frame, rf_predictions)

table(result.frame$rf_predicted_proximity, useNA = 'always')

###   ###   ###

pred.useless <-
  result.frame[result.frame$rf_predicted_proximity == "FALSE-FALSE-FALSE-FALSE" ,]

pred.has.potential  <-
  result.frame[result.frame$rf_predicted_proximity != "FALSE-FALSE-FALSE-FALSE" ,]

uncovered.fullnames <- setdiff(pred.useless$MedicationName, pred.has.potential$MedicationName)

###   ###   ###

# pred.has.potential <- result.frame

pred.cols <- pred.has.potential[, pred.col.names]

max.useful.prob <- apply(
  pred.cols,
  1,
  FUN = function(my.current.row) {
    return(max(my.current.row))
  }
)

pred.has.potential$max.useful.prob.by.row <- max.useful.prob

###   ###   ###

pred.has.potential.without.nddf.alt <-
  pred.has.potential[!(
    pred.has.potential$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
      pred.has.potential$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"
  ) ,]

# "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/" 
# "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." 


pred.has.potential.only.nddf.alt <-
  pred.has.potential[(
    pred.has.potential$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
      pred.has.potential$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"
  ) ,]

only.nddf.alt.medications <-
  setdiff(pred.has.potential.only.nddf.alt$MedicationName,
          pred.has.potential.without.nddf.alt$MedicationName)

###   ###   ###

aggdata <-
  aggregate(
    pred.has.potential$max.useful.prob,
    by = list(pred.has.potential$MedicationName),
    FUN = max,
    na.rm = TRUE
  )
names(aggdata) <- c("MedicationName", "max.useful.prob.by.med")

pred.has.potential.max.useful.prob <-
  merge(x = pred.has.potential,
        y = aggdata,
        by = c("MedicationName"))

pred.has.potential.max.useful.prob$relative.prob <- pred.has.potential.max.useful.prob$max.useful.prob.by.row / pred.has.potential.max.useful.prob$max.useful.prob.by.med

###   ###   ###

# pred.has.potential.without.nddf.alt <- pred.has.potential.max.useful.prob

for.graphdb <- pred.has.potential.without.nddf.alt[, c( "PK_MEDICATION_ID",
                                                        "s", "solrsubmission", "labelContent", "term", "ontology", "rxnifavailable",
                                                        "jaccard", "score", "cosine", "rank", "jw", "hwords", "hchars", "qchars",
                                                        "qgram", "term.count", "qwords", "lv", "lcs", "T200", "ontology.count",
                                                        "rxnMatchMeth", "http...www.w3.org.2004.02.skos.core.altLabel", "labelType",
                                                        "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
                                                        "rf_predicted_proximity", "FALSE-FALSE-FALSE-FALSE", "FALSE-FALSE-FALSE-TRUE",
                                                        "FALSE-FALSE-TRUE-FALSE", "FALSE-FALSE-TRUE-TRUE", "FALSE-TRUE-FALSE-FALSE",
                                                        "FALSE-TRUE-TRUE-FALSE", "TRUE-FALSE-FALSE-FALSE", "TRUE-TRUE-FALSE-FALSE",
                                                        "max.useful.prob.by.row", "max.useful.prob.by.med", "relative.prob" )]

names(for.graphdb) <- c( "PK_MEDICATION_ID", "R_MEDICATION_URI",
                         "solrsubmission", "labelContent", "term", "ontology", "rxnifavailable",
                         "jaccard", "score", "cosine", "rank", "jw", "hwords", "hchars", "qchars",
                         "qgram", "term.count", "qwords", "lv", "lcs", "T200", "ontology.count",
                         "rxnMatchMeth", "altLabel", "labelType", "solr_rxnorm",
                         "rf_predicted_proximity", "FALSE-FALSE-FALSE-FALSE", "FALSE-FALSE-FALSE-TRUE",
                         "FALSE-FALSE-TRUE-FALSE", "FALSE-FALSE-TRUE-TRUE", "FALSE-TRUE-FALSE-FALSE",
                         "FALSE-TRUE-TRUE-FALSE", "TRUE-FALSE-FALSE-FALSE", "TRUE-TRUE-FALSE-FALSE",
                         "max.useful.prob.by.row", "max.useful.prob.by.med", "relative.prob" )

# recast ontolgy and labeltype columns back to real URIs
# make URIs for other categoricals, like the sematic proximity?

for.graphdb$labelType <- factor(
  x = for.graphdb$labelType,
  levels = c(
    "http...www.w3.org.2000.01.rdf.schema.label",
    "http...www.w3.org.2004.02.skos.core.altLabel",
    "http...www.w3.org.2004.02.skos.core.prefLabel"
  ),
  labels = c(
    "http://www.w3.org/2000/01/rdf-schema#label",
    "http://www.w3.org/2004/02/skos/core#altLabel",
    "http://www.w3.org/2004/02/skos/core#prefLabel"
  )
)

for.graphdb$ontology <- factor(
  x = for.graphdb$ontology,
  levels = c("https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.CVX.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.DRUGBANK.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.GS.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MDDB.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MED.RT.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMSL.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMX.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MTH.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_FDA.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_NCPDP.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDFRT.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.SPN.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.ATC.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.UMD.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USP.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USPMG.", 
             "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.VANDF.", 
             "ftp...ftp.ebi.ac.uk.pub.databases.chebi.ontology.chebi.owl.gz", 
             "https...bitbucket.org.uamsdbmi.dron.raw.master.dron.full.owl"
  ),
  labels = c("https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/CVX/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/DRUGBANK/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/GS/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MDDB/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MED-RT/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMSL/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMX/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MTH/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_FDA/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_NCPDP/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDFRT/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/SPN/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/ATC/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/UMD/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USP/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USPMG/", 
             "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/VANDF/", 
             "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz", 
             "https://bitbucket.org/uamsdbmi/dron/raw/master/dron-full.owl"
  )
)


# na.tracking <- apply(for.graphdb, 2, anyNA)
# 
# na.tracking <-
#   cbind.data.frame(names(na.tracking), as.logical(na.tracking))

trn <- 1:nrow(for.graphdb)
for.graphdb <- cbind(trn, for.graphdb)

dim(for.graphdb)

head(for.graphdb)

## write.table(for.graphdb, file = "/overflow/pred_has_potential_without_nddf_alt.tsv", sep = "\t", row.names = FALSE)

# write.csv(for.graphdb, file = "/terabyte/pred_has_potential_without_nddf_alt_rownums_201904211153.csv", row.names = FALSE)
