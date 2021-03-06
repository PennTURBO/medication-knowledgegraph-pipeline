# source- vs ref- vs ehr (just to get rid of both legacy terms)

# need better terms for identical and more distant
# no spaces in names like that, sincle they may become IRIs
# should be defined in the TMM ontology
# would have to go back to training to be consistent
# use http://purl.bioontology.org/ontology/RXNORM/ base for now

#   query.source	http://example.com/resource/query_source/ OK
#   SAB.sr	http://example.com/resource/RXNORM_SAB/ ???
#   TTY.sr	http://example.com/resource/RXNORM_TTY/ ???
#   rf_responses	http://example.com/resource/search_res_classification/ NO, switch to http://purl.bioontology.org/ontology/RXNORM/ as above
#   override	http://example.com/resource/search_res_classification/ NO, switch to http://purl.bioontology.org/ontology/RXNORM/ as above
#   MEDICATION_ID	http://example.com/resource/source_med_id/ OK
#   RXNORM	http://purl.bioontology.org/ontology/RXNORM/ OK
#   rxcui	http://purl.bioontology.org/ontology/RXNORM/ OK

####

# set the working directory to medication-knowledgegraph-pipeline/pipeline
# for example,
# setwd("~/GitHub/medication-knowledgegraph-pipeline/pipeline")

# get global settings, functions, etc. from https://raw.githubusercontent.com/PennTURBO/turbo-globals

# requires a properly formatted "turbo_R_setup.yaml" in medication-knowledgegraph-pipeline/config
# or better yet, a symbolic link to a centrally located "turbo_R_setup.yaml", which could be used by multiple pipelines
# see https://github.com/PennTURBO/turbo-globals/blob/master/turbo_R_setup.template.yaml

source(
  "https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup_action_versioning.R"
)

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

# many warnings saved to robot.results when templating and intern = TRUE
capture.robot.output <- FALSE

# # may also want to capture
# #   pre_commit_status.txt
# pre_commit_tags.fp <- "../release_tag.txt"
# # execution.timestamp determined fresh each time
# #   https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup.R
# #   is sourced
#
# temp <- read_lines(pre_commit_tags.fp)
# version.list <-
#   list(versioninfo = temp,
#        created = execution.timestamp)

####

# try to connect to RxNav database with a reusable and closable connection
# so first try to close that handle if it exists
# be careful...
#  over time, that kind of approach could use up more connections that a RDBMS is willing to grant

tryCatch({
  dbDisconnect(rxnCon)
},
warning = function(w) {
  
}, error = function(e) {
  print(e)
})

rxnCon <- NULL

connected.test.query <-
  "select RSAB from rxnorm_current.RXNSAB r"

# todo paramterize connection and query string
# how to user conenction parpatmeron LHS or assignment?
test.and.refresh <- function() {
  tryCatch({
    dbGetQuery(rxnCon, connected.test.query)
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
    dbGetQuery(rxnCon, connected.test.query)
  }, finally = {
    
  })
}

# load("build/source_medications.Rdata")
# currently loads source.medications
# stop using separate save, (write?) and load paths

version.lol <- list()
version.lol[['this']] <- version.list
# current.version.list <- version.list
# # modifies version list!
load(config$source.medications.Rdata.path)
# source.medications.version.list <- version.list
# version.list <- current.version.list
version.lol[['reference_medications']] <- version.list

source.medications$ehr.rxn.annotated <-
  !is.na(source.medications$RXNORM)

# source_medications.all.pds.Rdata @ 17 September 2020 has ~ 900k reference medications,
# but many are linked, via an encounter, to either zero or only one patients/EMPIs
# as determined from the unfortunately named "MEDICATION_COUNT" column

# > table(source.medications$MEDICATION_COUNT)
#
# 0      1      2
# 701166 132971  21048

# # destructive (changing would require rerunning query or load
source.medications <-
  source.medications[source.medications$MEDICATION_COUNT >= config$min.empi.count ,]

####

# add option for CSV input

# if the source medication table was saved as Rdata, it will have better fidelity
#   than reopening a tab, comma or pipe-delimited text file

# source.medications <- read_delim(
#   config$source.medications.loadpath,
#   "|",
#   escape_double = FALSE,
#   trim_ws = TRUE
# )

####

post.res <- POST(update.endpoint,
                 body = list(update = 'clear all'),
                 saved.authentication)

not.empty.yet <- TRUE

while (not.empty.yet) {
  context.report <- get.context.report()
  if (is.null(context.report)) {
    break
  }
  print("Still need to clear:")
  print(context.report)
  sleep(config$monitor.pause.seconds)
}

####

# normalize source (UPHS) lexical peculiarities

normalization.rules.res <-
  read_csv(config$normalization.file)

normalization.rules.res$char <-
  nchar(normalization.rules.res$pattern)
normalization.rules.res$ws <-
  gsub(pattern = "[^ ]",
       replacement = "",
       x = normalization.rules.res$pattern)
normalization.rules.res$wc <- nchar(normalization.rules.res$ws) + 1

normalization.rules.res$replacement[is.na(normalization.rules.res$replacement)] <-
  ""
normalization.rules.res <-
  normalization.rules.res[normalization.rules.res$confidence == "high" ,]
normalization.rules.res <-
  normalization.rules.res[order(normalization.rules.res$wc,
                                normalization.rules.res$char,
                                decreasing = TRUE),]

normalization.rules.res$pattern <-
  paste("\\b", normalization.rules.res$pattern, "\\b", sep = "")
normalization.rules.res$replacement[is.na(normalization.rules.res$replacement)] <-
  ""

normalization.rules <- normalization.rules.res$replacement
names(normalization.rules) <- normalization.rules.res$pattern

source.medications$normalized <-
  tolower(source.medications$FULL_NAME)
source.medications$normalized[is.na(source.medications$normalized)] <-
  ""

source.medications$GENERIC_NAME.lc <-
  tolower(source.medications$GENERIC_NAME)
source.medications$GENERIC_NAME.lc[is.na(source.medications$GENERIC_NAME.lc)] <-
  ""

# applying longest normalization first
# use some kind of automated synonym discovery, like phrase2vec?
source.medications$normalized <-
  stringr::str_replace_all(source.medications$normalized, normalization.rules)

####

# eliminate initial space
# also remove initial punct?

source.medications$normalized <-
  gsub(pattern = "^\\W+",
       replacement = "",
       x = source.medications$normalized)

source.medications$normalized <-
  gsub(
    pattern = "_",
    replacement = " ",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$normalized <-
  gsub(
    pattern = "(",
    replacement = " ",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$normalized <-
  gsub(
    pattern = ")",
    replacement = " ",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$normalized <-
  gsub(
    pattern = "&",
    replacement = " ",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$normalized <-
  gsub(
    pattern = "=",
    replacement = " ",
    x = source.medications$normalized,
    fixed = TRUE
  )


source.medications$normalized <-
  gsub(
    pattern = "'",
    replacement = "",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$normalized <-
  gsub(
    pattern = '"',
    replacement = "",
    x = source.medications$normalized,
    fixed = TRUE
  )

source.medications$GENERIC_NAME.lc <-
  gsub(
    pattern = "'",
    replacement = "",
    x = source.medications$GENERIC_NAME.lc,
    fixed = TRUE
  )

source.medications$GENERIC_NAME.lc <-
  gsub(
    pattern = '"',
    replacement = "",
    x = source.medications$GENERIC_NAME.lc,
    fixed = TRUE
  )


# run-on correction
source.medications$normalized <-
  gsub(
    "(\\d)([^ \\.0123456789])",
    replacement = "\\1 \\2",
    x = source.medications$normalized,
    fixed = FALSE
  )

# eliminate trailing space
# also remove trailing punct ??
source.medications$normalized <-
  gsub(pattern = "\\W+$",
       replacement = "",
       x = source.medications$normalized)


# extra spaces
source.medications$normalized <- gsub(pattern = " +",
                                      replacement = " ",
                                      x = source.medications$normalized)

# extra any-whitespaces
source.medications$normalized <-
  gsub(pattern = "\\s+",
       replacement = " ",
       x = source.medications$normalized)

###

# query on both normalized full name and generic name.
# may not apply to input sources other than PDS?
# not currently requiring that PDS r_medications
# are annotated with a current single ingredient rxcui

query.list <-
  sort(unique(
    c(
      source.medications$normalized[!(is.na(source.medications$normalized)) &
                                      nchar(source.medications$normalized) > 0],
      source.medications$GENERIC_NAME.lc[!(is.na(source.medications$normalized)) &
                                           nchar(source.medications$GENERIC_NAME.lc) > 0]
    )
  ))

####

safe.rxnav.submission.size <- config$safe.rxnav.submission.size

safe.rxnav.submission.count <-
  ceiling(length(query.list) / safe.rxnav.submission.size)

if (safe.rxnav.submission.count <= 2) {
  safe.rxnav.submission.count <- 2
}

safe.rxnav.submission.chunks <-
  chunk.vec(vec = query.list, chunk.count = safe.rxnav.submission.count)

# paramterize message?
outer.chunks <-
  lapply(
    X = safe.rxnav.submission.chunks,
    FUN = function(current.chunk) {
      print(Sys.time())
      inner.temp <- bulk.approximateTerm(current.chunk)
      print(
        paste0(
          "    sleeping ",
          config$inter.outer.seconds,
          " seconds before starting next chunk of ",
          config$safe.rxnav.submission.size
        )
      )
      gc()
      Sys.sleep(config$inter.outer.seconds)
      return(inner.temp)
    }
  )

####

approximate.term.res <-
  do.call(what = rbind.data.frame, args = outer.chunks)

# # ~ 45 minutes for XXX
# # break up into chunks of 10 or 20k?

###

test.and.refresh()

# two or three minutes
# TODO add some progress indication back in
# in general, should be more consistent about chunking by count vs size
rxaui.asserted.string.res <-
  bulk.rxaui.asserted.strings(approximate.term.res$rxaui,
                              chunk.count = config$rxaui.asserted.strings.chunk.count)

approximate.with.original <-
  left_join(rxaui.asserted.string.res, approximate.term.res)

ehr.full_name.approximate <-
  left_join(
    x = source.medications,
    y = approximate.with.original,
    by = c("normalized" = "query"),
    suffixes = c(".q", ".sr")
  )

ehr.full_name.approximate$query.source <- "normalized FULL_NAME"
ehr.full_name.approximate$query.val <-
  ehr.full_name.approximate$normalized

####

ehr.generic_name.approximate <-
  inner_join(
    x = source.medications,
    y = approximate.with.original,
    by = c("GENERIC_NAME.lc" = "query"),
    suffixes = c(".q", ".sr")
  )

ehr.generic_name.approximate$query.source <-
  "lowercased GENERIC_NAME"
ehr.generic_name.approximate$query.val <-
  ehr.generic_name.approximate$GENERIC_NAME.lc

ehr.approximately <-
  rbind.data.frame(ehr.full_name.approximate, ehr.generic_name.approximate)

####

# moodify global function to sort the string dis methods before looping
string.dist.mat.res <-
  get.string.dist.mat(ehr.approximately[, c("query.val", "STR.lc")])

string.dist.mat.res <- unique(string.dist.mat.res)

ehr.approximate.original.dists <-
  left_join(
    x = ehr.approximately,
    y = string.dist.mat.res,
    by = c("query.val", "STR.lc"),
    suffixes = c(".q", ".sr")
  )

###

# get word and char counts
ehr.approximate.original.dists$q.char <-
  nchar(ehr.approximate.original.dists$query.val)
temp <- ehr.approximate.original.dists$query.val
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
ehr.approximate.original.dists$q.words <- temp

ehr.approximate.original.dists$sr.char <-
  nchar(ehr.approximate.original.dists$STR.lc)
temp <- ehr.approximate.original.dists$STR.lc
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
ehr.approximate.original.dists$sr.words <- temp

###   ###   ###

names(ehr.approximate.original.dists)[names(ehr.approximate.original.dists) == "TTY"] <-
  "TTY.sr"
names(ehr.approximate.original.dists)[names(ehr.approximate.original.dists) == "SAB"] <-
  "SAB.sr"

all.cols <- colnames(ehr.approximate.original.dists)

factor.predictors <- c("TTY.sr", "SAB.sr")

numeric.predictors <-
  c(
    "cosine",
    "rxaui.freq" ,
    "rxcui.freq",
    "jaccard",
    "jw",
    "lcs",
    "lv",
    "qgram",
    "rank",
    "score",
    "q.char",
    "q.words",
    "sr.char",
    "sr.words"
  )

ignore.cols <-
  c(
    "rxaui.count",
    "rxcui.count",
    "rxaui",
    "RXAUI",
    "rxcui",
    "RXCUI",
    "SAB.q",
    "STR.lc",
    "STR.lc.sr",
    "STR.q",
    "STR.sr",
    "SUPPRESS",
    "TTY.q",
    "MEDICATION_COUNT",
    "MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "GENERIC_NAME.lc",
    "normalized",
    "ehr.rxn.annotated",
    "query.source",
    "query.val",
    "RXNORM",
    "STR"
  )

accounted.cols <-
  c(numeric.predictors,
    factor.predictors,
    ignore.cols)

print(dput(sort(setdiff(
  all.cols, accounted.cols
))))
print(dput(sort(setdiff(
  accounted.cols, all.cols
))))
print(sort(table(accounted.cols)))


####

# current.version.list <- version.list
#
# # modifies version list!

load(config$rf.model.path)
version.lol[['classified_search_results']] <- version.list

# rf.model.version.list <- version.list
#
# version.list <- current.version.list

####

temp <-
  as.data.frame(ehr.approximate.original.dists)

placeholder <-
  lapply(names(config$factor.levels), function(current.factor) {
    print(current.factor)
    if (current.factor %in% colnames(temp)) {
      temp[, current.factor] <<- as.character(temp[, current.factor])
      temp[, current.factor] <<-
        factor(temp[, current.factor],
               levels = config$factor.levels[[current.factor]])
      print(table(ehr.approximate.original.dists[, current.factor]))
    }
    return(NULL)
  })

# don't want to exclude meds that are lacking RDS RxNORM annotations!
# probably don't want dummy URIs in the RDF output
temp$RXNORM[is.na(temp$RXNORM)] <- ''
temp$GENERIC_NAME[is.na(temp$GENERIC_NAME)] <- ''
temp$GENERIC_NAME[is.na(temp$GENERIC_NAME)] <- ''

# get before and after counts
pre <- unique(temp$MEDICATION_ID)
temp <- temp[complete.cases(temp), ]
post <- unique(temp$MEDICATION_ID)
lost <- setdiff(pre, post)
lost <-
  ehr.approximate.original.dists[ehr.approximate.original.dists$MEDICATION_ID %in% lost ,]

print(Sys.time())
timed.system <- system.time(rf_responses <-
                              predict(rf_classifier, temp, type = "response"))
print(Sys.time())


print(Sys.time())
timed.system <- system.time(rf_probs <-
                              predict(rf_classifier, temp, type = "prob"))
print(Sys.time())

performance.frame <-
  cbind.data.frame(temp, rf_responses, rf_probs)

performance.frame$override <- performance.frame$rf_responses
table(performance.frame$override)

performance.frame$override[performance.frame$score == 100] <-
  "identical"
performance.frame$override[performance.frame$score == 0] <-
  "more distant"
table(performance.frame$override)


####

# SLOW NOW at min count = 10
dim(performance.frame)
table(performance.frame$override)
all.keys <-
  source.medications$MEDICATION_ID[source.medications$MEDICATION_COUNT >= config$min.empi.count]
# all.keys <- unique(source.medications$MEDICATION_ID)
print(length(all.keys))

covered.keys <-
  unique(performance.frame$MEDICATION_ID[performance.frame$rf_responses != "more distant"])

coverage <- length(covered.keys) / length(all.keys)

# coverage is explicitly: percent of source medications that have at least one non-more-distant predictions
# but more distant may actually be acceptable!

print(coverage)

uncovered.keys <- setdiff(all.keys, covered.keys)

# save for followup?
uncovered.frame <-
  ehr.approximate.original.dists[ehr.approximate.original.dists$MEDICATION_ID %in% uncovered.keys ,]

###

classification.res.tidied <-
  performance.frame[, c(
    "MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "RXNORM",
    "MEDICATION_COUNT",
    "ehr.rxn.annotated",
    "normalized",
    "query.source",
    "query.val",
    "rxcui",
    "rxaui",
    "score",
    "rank",
    "STR",
    "SAB.sr",
    "TTY.sr",
    "rxaui.freq",
    "rxcui.freq",
    "q.char",
    "q.words",
    "sr.char",
    "sr.words",
    "cosine",
    "jaccard",
    "jw",
    "lcs",
    "lv",
    "qgram",
    "rf_responses",
    "consists_of",
    "constitutes",
    "contained_in",
    "contains",
    "form_of",
    "has_form",
    "has_ingredient",
    "has_part",
    "has_quantified_form",
    "has_tradename",
    "identical",
    "ingredient_of",
    "inverse_isa",
    "isa",
    "more distant",
    "part_of",
    "quantified_form_of",
    "tradename_of",
    "override"
  )]

classification.res.tidied <- unique(classification.res.tidied)

# step above (or below?) is slow with min count < 10

# load rxnorm into repo (assume from file)

temp.name <- 'http://purl.bioontology.org/ontology/RXNORM/'
last.post.time <- Sys.time()
placeholder <- import.from.local.file(temp.name,
                                      config$my.import.files[[temp.name]]$local.file,
                                      config$my.import.files[[temp.name]]$format)

last.post.status <- 'Loaded RxNorm'
expectation <- temp.name
monitor.named.graphs()

# now get rxcuis with labels in repo

my.query <- 'PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select distinct ?rxcui_with_rxaui_with_skos_notation
where {
graph <http://purl.bioontology.org/ontology/RXNORM/> {
?s <http://purl.bioontology.org/ontology/RXNORM/RXAUI> ?rxaui ;
skos:notation ?rxcui_with_rxaui_with_skos_notation .
}
}'

result.list <- httr::GET(
  url = paste0(
    config$my.graphdb.base,
    "/repositories/",
    config$my.selected.repo
  ),
  query = list(query = my.query),
  saved.authentication
)

temp <- jsonlite::fromJSON(rawToChar(result.list$content))
rxnorm.entities.in.repo <-
  as.numeric(unique(
    temp$results$bindings$rxcui_with_rxaui_with_skos_notation$value
  ))

####

classification.res.tidied.inactive.rxcui <-
  classification.res.tidied[!(classification.res.tidied$rxcui %in% rxnorm.entities.in.repo),]

classification.res.tidied <-
  classification.res.tidied[classification.res.tidied$rxcui %in% rxnorm.entities.in.repo,]

classification.res.tidied.id <-
  classification.res.tidied[classification.res.tidied$override == "identical", ]
best.identical <-
  aggregate(
    classification.res.tidied.id$identical,
    list(classification.res.tidied.id$MEDICATION_ID),
    FUN = max
  )
colnames(best.identical) <- c("MEDICATION_ID", "identical")
classification.res.tidied.id <-
  base::merge(classification.res.tidied.id, best.identical)

# actually keep one-hops as long as their best prob is as high as or higher than the identical prob

classification.res.tidied.onehop <-
  classification.res.tidied[(
    classification.res.tidied$override != "identical" &
      classification.res.tidied$override != "more distant"
  ) ,]

probs.matrix <- classification.res.tidied.onehop[, c(
  "consists_of",
  "constitutes",
  "contained_in",
  "contains",
  "form_of",
  "has_form",
  "has_ingredient",
  "has_part",
  "has_quantified_form",
  "has_tradename",
  "ingredient_of",
  "inverse_isa",
  "isa",
  "part_of",
  "quantified_form_of",
  "tradename_of"
)]
probs.matrix.rowmax <-
  apply(X = probs.matrix, MARGIN = 1, FUN = max)
classification.res.tidied.onehop <-
  cbind.data.frame(classification.res.tidied.onehop, probs.matrix.rowmax)

best.onehop <-
  aggregate(
    classification.res.tidied.onehop$probs.matrix.rowmax,
    list(classification.res.tidied.onehop$MEDICATION_ID),
    FUN = max
  )
colnames(best.onehop) <-
  c("MEDICATION_ID", "probs.matrix.rowmax")
classification.res.tidied.onehop <-
  base::merge(classification.res.tidied.onehop, best.onehop)

id.scoreonly <-
  unique(classification.res.tidied.id[, c('MEDICATION_ID', 'identical')])
oh.scoreonly <-
  unique(classification.res.tidied.onehop[, c('MEDICATION_ID', 'probs.matrix.rowmax')])

equal.or.better.Q <-
  base::merge(id.scoreonly, oh.scoreonly, all = TRUE)
equal.or.better.Q$identical[is.na(equal.or.better.Q$identical)] <- 0
equal.or.better.Q$probs.matrix.rowmax[is.na(equal.or.better.Q$probs.matrix.rowmax)] <-
  0
equal.or.better.Q <-
  equal.or.better.Q[equal.or.better.Q$probs.matrix.rowmax >= equal.or.better.Q$identical , ]

classification.res.tidied.onehop <-
  classification.res.tidied.onehop[classification.res.tidied.onehop$MEDICATION_ID %in% equal.or.better.Q$MEDICATION_ID , ]

####

classification.res.tidied.md <-
  classification.res.tidied[classification.res.tidied$override == "more distant" &
                              (
                                !(
                                  classification.res.tidied$MEDICATION_ID %in% classification.res.tidied.id$MEDICATION_ID
                                )
                              ) &
                              (
                                !(
                                  classification.res.tidied$MEDICATION_ID %in% classification.res.tidied.onehop$MEDICATION_ID
                                )
                              ) ,]

probs.matrix <- classification.res.tidied.md[, c(
  "consists_of",
  "constitutes",
  "contained_in",
  "contains",
  "form_of",
  "has_form",
  "has_ingredient",
  "has_part",
  "has_quantified_form",
  "has_tradename",
  "ingredient_of",
  "inverse_isa",
  "isa",
  "part_of",
  "quantified_form_of",
  "tradename_of"
)]
probs.matrix.rowmax <-
  apply(X = probs.matrix, MARGIN = 1, FUN = max)
classification.res.tidied.md <-
  cbind.data.frame(classification.res.tidied.md, probs.matrix.rowmax)

best.md <-
  aggregate(
    classification.res.tidied.md$probs.matrix.rowmax,
    list(classification.res.tidied.md$MEDICATION_ID),
    FUN = max
  )
colnames(best.md) <- c("MEDICATION_ID", "probs.matrix.rowmax")
classification.res.tidied.md <-
  base::merge(classification.res.tidied.md, best.md)

shared.cols <-
  intersect(
    colnames(classification.res.tidied.onehop),
    colnames(classification.res.tidied.md)
  )
shared.cols <-
  intersect(shared.cols, colnames(classification.res.tidied.id))

classification.res.tidied <-
  rbind.data.frame(
    classification.res.tidied.id[, shared.cols],
    classification.res.tidied.onehop[, shared.cols],
    classification.res.tidied.md[, shared.cols]
  )

####

uuids <- uuid::UUIDgenerate(n = nrow(classification.res.tidied))
uuids <- paste0("http://example.com/resource/", uuids)

classification.res.tidied <-
  cbind.data.frame(uuids,  classification.res.tidied)

####

med_map_csv_cols <- read_csv(config$per.task.columns)

# source_meds;classified_results

destination.graphs <- strsplit(med_map_csv_cols$graphs, ";")
unique.destination.graphs <- unique(unlist(destination.graphs))

colnames(classification.res.tidied) <- med_map_csv_cols$more_generic

url_casting <-
  med_map_csv_cols[(!is.na(med_map_csv_cols$base)), c("more_generic", "base")]

graphs.cols <-
  lapply(unique.destination.graphs, function(current.graph) {
    print(current.graph)
    inner <-
      grepl(pattern = current.graph, x = med_map_csv_cols$graphs)
    selected <- med_map_csv_cols$more_generic[inner]
    return(selected)
  })

names(graphs.cols) <- unique.destination.graphs

####

# check URLs now

placeholder <-
  apply(
    url_casting,
    MARGIN = 1,
    FUN = function(current.cast) {
      current.col <- current.cast[['more_generic']]
      current.base <- current.cast[['base']]
      print(current.col)
      print(current.base)
      classification.res.tidied[, current.col] <<-
        gsub(" +", "_", classification.res.tidied[, current.col])
      classification.res.tidied[, current.col] <<-
        paste0(current.base, classification.res.tidied[, current.col])
    }
  )

#####


classification.res.tidied$source_rxcui[classification.res.tidied$source_rxcui ==
                                         'http://purl.bioontology.org/ontology/RXNORM/'] <-
  ''

####

# tried rdflib::add approach instead of robot... too slow

robot.templating <- function(current.task) {
  # paramaterize the file names in all subsequent scripts
  # or gz?
  # if zip works, update YAML configuration file
  
  # current.task <- "reference_medications"
  
  print(current.task)
  
  robot.java.settings <- "ROBOT_JAVA_ARGS=-Xmx8G"
  
  more.specific <-
    config::get(file = config$config.fn, config = current.task)
  
  keepers <-
    med_map_csv_cols$more_generic %in% setdiff(graphs.cols[[current.task]], "source_has_rxcui")
  
  body <- unique(classification.res.tidied[, keepers])
  pre.robot <- colnames(body)
  class.col <- rep(more.specific$my.class, nrow(body))
  body <- cbind.data.frame(class.col, body)
  pre.robot <- colnames(body)
  # print(pre.robot)
  
  robot.line <-
    med_map_csv_cols$robot[med_map_csv_cols$more_generic %in% pre.robot]
  robot.line[1] <- 'ID'
  robot.line <-
    c('TYPE', robot.line)
  
  print(robot.line)
  
  body[] <- lapply(body[], as.character)
  
  body <- rbind.data.frame(robot.line, body)
  names(body) <- pre.robot
  
  write.table(
    x = body,
    file = paste0("build/", current.task, '_for_robot.tsv'),
    append = FALSE,
    quote = TRUE,
    sep = '\t',
    row.names = FALSE,
    col.names = TRUE
  )
  
  contextual.version <- version.lol[[current.task]]
  
  build.source.med.classifications.annotations(
    version.list = contextual.version,
    onto.iri = more.specific$onto.iri ,
    onto.file = more.specific$onto.file ,
    onto.file.format = more.specific$onto.file.format
  )
  
  # "-vvv" verbosity flags generate a LOT of statements along the lines of
  # WARN  org.obolibrary.robot.IOHelper - Unable to find namespace for: http://example.com/resource/...
  robot.command <-
    paste0(
      'robot template ',
      '--prefix "xsd: http://www.w3.org/2001/XMLSchema#" ',
      '--prefix "obo: http://purl.obolibrary.org/obo/" ',
      '--template build/',
      current.task,
      '_for_robot.tsv ',
      'annotate ',
      '--ontology-iri "http://example.com/resource/',
      current.task,
      '" ',
      '--annotation-file ',
      more.specific$onto.file,
      ' ',
      '--output build/',
      current.task,
      '_from_robot.ttl '
    )
  
  cat(robot.command)
  
  # many warnings saved to robot.results when intern = TRUE
  robot.results <-
    system(command = paste0(robot.java.settings,
                            ' && ', robot.command),
           intern = capture.robot.output)
  
  
  # print(robot.results)
  
  zip::zip(
    root = "build",
    zipfile = paste0(current.task, "_from_robot.ttl.zip"),
    files = c(paste0(current.task, "_from_robot.ttl"))
  )
  
}

lapply(rev(sort(names(graphs.cols))), robot.templating)
# system calls to robot now replace  med_mapping_robot.sh which had read from and written to completely hardcoded files/path

# # for debugging
# save.image(config$image.fn)

# next run XXX
