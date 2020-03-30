# assumes this script has been launched from the current working directory that contains
#  rxnav_med_mapping_setup.R, rxnav_med_mapping.yaml

source("rxnav_med_mapping_setup.R")

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

####

# source.medications <-
#   read.table(
#     config$source.medications.loadpath,
#     header = TRUE,
#     sep = "|",
#     # quote = TRUE,
#     row.names = FALSE
#   )

source.medications <- read_delim(
  config$source.medications.loadpath,
  "|",
  escape_double = FALSE,
  trim_ws = TRUE
)

source.medications$pds.rxn.annotated <-
  !is.na(source.medications$RXNORM)

# ~ 900k r-medications,
# but only ~250k that have an order/encounter link to a patient with an EMPI

# # destructive (changing would require rerunning query or load
source.medications <-
  source.medications[source.medications$MEDICATION_COUNT >= config$min.empi.count ,]

# ### what's the relationship between the likelihood of an rxnorm annotation and the # of patients receiving an order?
#
# ggplot(
#   source.medications,
#   aes(
#     x = MEDICATION_COUNT + 0.01,
#     color = pds.rxn.annotated,
#     fill = pds.rxn.annotated
#   )
# ) + geom_histogram(alpha = 0.1) + scale_x_log10() + scale_y_sqrt()
#
#
# # likelihood is consistent across patient frequencies

####

# normalize UPHS lexical peculiarities

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
  normalization.rules.res[normalization.rules.res$confidence == "high" , ]
normalization.rules.res <-
  normalization.rules.res[order(normalization.rules.res$wc,
                                normalization.rules.res$char,
                                decreasing = TRUE), ]

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

# does the order of applying the normalizations matter?
# applying longest ones first
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
# query.list <-
#   sort(unique(
#     c(
#       source.medications$normalized[source.medications$MEDICATION_COUNT > config$min.empi.count &
#                                              !(is.na(source.medications$normalized)) &
#                                              nchar(source.medications$normalized) > 0],
#       source.medications$GENERIC_NAME.lc[source.medications$MEDICATION_COUNT > config$min.empi.count &
#                                                   !(is.na(source.medications$normalized)) &
#                                                   nchar(source.medications$GENERIC_NAME.lc) > 0]
#     )
#   ))

query.list <-
  sort(unique(
    c(
      source.medications$normalized[!(is.na(source.medications$normalized)) &
                                      nchar(source.medications$normalized) > 0],
      source.medications$GENERIC_NAME.lc[!(is.na(source.medications$normalized)) &
                                           nchar(source.medications$GENERIC_NAME.lc) > 0]
    )
  ))

begin.time <- Sys.time()
approximate.term.res <- bulk.approximateTerm(query.list)
end.time <- Sys.time()
print(end.time - begin.time)

###

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

# add some progress indication back in
rxaui.asserted.string.res <-
  bulk.rxaui.asserted.strings(approximate.term.res$rxaui,
                              chunk.count = config$rxaui.asserted.strings.chunk.count)

approximate.with.original <-
  left_join(rxaui.asserted.string.res, approximate.term.res)

pds.full_name.approximate <-
  left_join(
    x = source.medications,
    y = approximate.with.original,
    by = c("normalized" = "query"),
    suffixes = c(".q", ".sr")
  )

pds.full_name.approximate$query.source <- "normalized FULL_NAME"
pds.full_name.approximate$query.val <-
  pds.full_name.approximate$normalized

####

pds.generic_name.approximate <-
  inner_join(
    x = source.medications,
    y = approximate.with.original,
    by = c("GENERIC_NAME.lc" = "query"),
    suffixes = c(".q", ".sr")
  )

pds.generic_name.approximate$query.source <-
  "lowercased GENERIC_NAME"
pds.generic_name.approximate$query.val <-
  pds.generic_name.approximate$GENERIC_NAME.lc

pds.approximately <-
  rbind.data.frame(pds.full_name.approximate, pds.generic_name.approximate)

####

string.dist.mat.res <-
  get.string.dist.mat(pds.approximately[, c("query.val", "STR.lc")])

string.dist.mat.res <- unique(string.dist.mat.res)

pds.approximate.original.dists <-
  left_join(
    x = pds.approximately,
    y = string.dist.mat.res,
    by = c("query.val", "STR.lc"),
    suffixes = c(".q", ".sr")
  )


###

# get word and char counts
pds.approximate.original.dists$q.char <-
  nchar(pds.approximate.original.dists$query.val)
temp <- pds.approximate.original.dists$query.val
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
pds.approximate.original.dists$q.words <- temp

pds.approximate.original.dists$sr.char <-
  nchar(pds.approximate.original.dists$STR.lc)
temp <- pds.approximate.original.dists$STR.lc
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
pds.approximate.original.dists$sr.words <- temp

###   ###   ###

names(pds.approximate.original.dists)[names(pds.approximate.original.dists) == "TTY"] <-
  "TTY.sr"
names(pds.approximate.original.dists)[names(pds.approximate.original.dists) == "SAB"] <-
  "SAB.sr"

all.cols <- colnames(pds.approximate.original.dists)

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
    "pds.rxn.annotated",
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

load(config$rf.model.savepath)

####

temp <-
  as.data.frame(pds.approximate.original.dists)

placeholder <-
  lapply(names(config$factor.levels), function(current.factor) {
    print(current.factor)
    if (current.factor %in% colnames(temp)) {
      temp[, current.factor] <<- as.character(temp[, current.factor])
      temp[, current.factor] <<-
        factor(temp[, current.factor],
               levels = config$factor.levels[[current.factor]])
      print(table(pds.approximate.original.dists[, current.factor]))
    }
    return(NULL)
  })

# print(str(temp))

# temp$TTY.sr <- as.character(temp$TTY.sr)
# temp$TTY.sr <-
#   factor(temp$TTY.sr,
#          levels = config$factor.levels$TTY.sr)
#
# temp$SAB.sr <- as.character(temp$SAB.sr)
# temp$SAB.sr <-
#   factor(temp$SAB.sr,
#          levels = levels(unknowns.approximate.original.dists$SAB.sr))

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
  pds.approximate.original.dists[pds.approximate.original.dists$MEDICATION_ID %in% lost ,]

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

all.keys <- unique(source.medications$MEDICATION_ID)

covered.keys <-
  unique(performance.frame$MEDICATION_ID[performance.frame$rf_responses != "more distant"])

coverage <- length(covered.keys) / length(all.keys)

print(coverage)

uncovered.keys <- setdiff(all.keys, covered.keys)

# save for followup?
uncovered.frame <-
  pds.approximate.original.dists[pds.approximate.original.dists$MEDICATION_ID %in% uncovered.keys , ]

###

classification.res.tidied <-
  performance.frame[, c(
    "MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "RXNORM",
    "MEDICATION_COUNT",
    "pds.rxn.annotated",
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

# now get rxcuis with labels in repo
# this should go into setup

select.endpoint <-
  paste0(config$my.graphdb.base,
         "/repositories/",
         config$my.selected.repo)

saved.authentication <-
  authenticate(config$my.graphdb.username,
               config$my.graphdb.pw,
               type = "basic")

# print(select.endpoint)

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

classification.res.tidied.inactive.rxcui <-
  classification.res.tidied[!(classification.res.tidied$rxcui %in% rxnorm.entities.in.repo), ]

classification.res.tidied <-
  classification.res.tidied[classification.res.tidied$rxcui %in% rxnorm.entities.in.repo, ]

#### need to put soemthing in place that picks best search results
#### in the context of wheter the rxnorm term is defined

classification.res.tidied.id <-
  classification.res.tidied[classification.res.tidied$override == "identical",]
best.identical <-
  aggregate(
    classification.res.tidied.id$identical,
    list(classification.res.tidied.id$MEDICATION_ID),
    FUN = max
  )
colnames(best.identical) <- c("MEDICATION_ID", "identical")
classification.res.tidied.id <-
  base::merge(classification.res.tidied.id, best.identical)

# classification.res.tidied.onehop <-
#   classification.res.tidied[(
#     classification.res.tidied$override != "identical" &
#       classification.res.tidied$override != "more distant" &
#       (
#         !(
#           classification.res.tidied$MEDICATION_ID %in% classification.res.tidied.id$MEDICATION_ID
#         )
#       )
#   ) ,]

# actually keep one-hops as long as their best prob is as high as or higher than the identical prob

classification.res.tidied.onehop <-
  classification.res.tidied[(
    classification.res.tidied$override != "identical" &
      classification.res.tidied$override != "more distant"
  ) , ]

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
  equal.or.better.Q[equal.or.better.Q$probs.matrix.rowmax >= equal.or.better.Q$identical ,]

classification.res.tidied.onehop <-
  classification.res.tidied.onehop[classification.res.tidied.onehop$MEDICATION_ID %in% equal.or.better.Q$MEDICATION_ID ,]

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
uuids <- paste0("http://example.com.resource/", uuids)

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

# graph name/column relationships are in graphs.cols
# would theoretically be better to iterate over that
# but will use  hard-coded names as special actions for now

# keepers <-
#   med_map_csv_cols$more_generic %in% setdiff(graphs.cols[['classified_search_results']], "source_has_rxcui")
# body <- unique(classification.res.tidied[, keepers])
#
# # should really extract this from source.medications
#
# keepers <-
#   med_map_csv_cols$more_generic %in% setdiff(graphs.cols[['classified_search_results']], "source_has_rxcui")
# # ROBOT is interpreting both FALSE and TRUE as 'false'^^xsd:boolean
#
#
# body <- unique(classification.res.tidied[, keepers])
# # # WHOA THIS GOT LOST SOMEWHERE
# # body$source_rxcui[body$source_rxcui == 'http://purl.bioontology.org/ontology/RXNORM/'] <-
# #   ''


# my.config <- config::get(file = "get_bioportal_mappings.yaml")

# > print(predlist)
# [1] "source_med_id"               "source_full_name"            "source_generic_name"         "source_rxcui"
# [5] "source_count"                "source_normalized_full_name"

####

# 90 minutes for all search results, not filtered by best identical score etc.

# why do I that way? need to see if search result's rxcui is in the RxNorm RDF
# we have loaded into the repo


current.task <- 'classified_search_results'

keepers <-
  med_map_csv_cols$more_generic %in% setdiff(graphs.cols[[current.task]], "source_has_rxcui")

body <- unique(classification.res.tidied[, keepers])
body[, 1] <- as.character(body[, 1])

print(Sys.time())
instantiate.and.upload(current.task)
print(Sys.time())

####

current.task <- 'reference_medications'

keepers <-
  med_map_csv_cols$more_generic %in% setdiff(graphs.cols[[current.task]], "source_has_rxcui")

body <- unique(classification.res.tidied[, keepers])

body$source_rxcui[body$source_rxcui == 'http://purl.bioontology.org/ontology/RXNORM/'] <-
  ''

print(Sys.time())
instantiate.and.upload(current.task)
print(Sys.time())
