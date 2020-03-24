# assumes this script has been launched from the current working directory that contains
#  rxnav_med_mapping_setup.R, rxnav_med_mapping.yaml

source("rxnav_med_mapping_setup.R")

if (config$reissue.pds.query) {
  # VPN and tunnel may be required
  # set that up outside of this script
  pdsDriver <-
    JDBC(driverClass = "oracle.jdbc.OracleDriver",
         classPath = config$oracle.jdbc.path)
  
  pds.con.string <- paste0(
    "jdbc:oracle:thin:@//",
    config$pds.host,
    ":",
    config$pds.port,
    "/",
    config$pds.database
  )
  
  pdsConnection <-
    dbConnect(pdsDriver,
              pds.con.string,
              config$pds.user,
              config$pds.pw)
  
  my.query <- "
  SELECT
  om.FK_MEDICATION_ID ,
  rm.FULL_NAME , rm.GENERIC_NAME,
  rm.RXNORM ,
  COUNT(DISTINCT pe.EMPI) AS empi_count
  FROM
  mdm.ORDER_MED om
  JOIN mdm.R_MEDICATION rm ON
  om.FK_MEDICATION_ID = rm.PK_MEDICATION_ID
  JOIN mdm.PATIENT_ENCOUNTER pe ON
  om.FK_PATIENT_ENCOUNTER_ID = pe.PK_PATIENT_ENCOUNTER_ID
  GROUP BY
  om.FK_MEDICATION_ID ,
  rm.FULL_NAME , rm.GENERIC_NAME,
  rm.RXNORM"
  
  print(Sys.time())
  timed.system <- system.time(pds.r.medications.results <-
                                dbGetQuery(pdsConnection, my.query))
  print(Sys.time())
  print(timed.system)
  
  # Close connection
  dbDisconnect(pdsConnection)
  
  save(pds.r.medications.results,
       file = config$pds.rmedication.result.savepath)
} else {
  load(config$pds.rmedication.result.loadpath)
}

pds.r.medications.results$pds.rxn.annotated <-
  !is.na(pds.r.medications.results$RXNORM)

# ~ 900k r-medications,
# but only ~250k that have an order/encounter link to a patient with an EMPI

# # destructive (changing would require rerunning query or load
pds.r.medications.results <-
  pds.r.medications.results[pds.r.medications.results$EMPI_COUNT >= config$min.empi.count ,]

### what's the relationship between the likelihood of an rxnorm annotation and the # of patients receiving an order?

ggplot(
  pds.r.medications.results,
  aes(
    x = EMPI_COUNT + 0.01,
    color = pds.rxn.annotated,
    fill = pds.rxn.annotated
  )
) + geom_histogram(alpha = 0.1) + scale_x_log10() + scale_y_sqrt()


# likelihood is consistent across patient frequencies

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

pds.r.medications.results$normalized <-
  tolower(pds.r.medications.results$FULL_NAME)
pds.r.medications.results$normalized[is.na(pds.r.medications.results$normalized)] <-
  ""

pds.r.medications.results$GENERIC_NAME.lc <-
  tolower(pds.r.medications.results$GENERIC_NAME)
pds.r.medications.results$GENERIC_NAME.lc[is.na(pds.r.medications.results$GENERIC_NAME.lc)] <-
  ""

# does the order of applying the normalizations matter?
# applying longest ones first
# use some kind of automated synonym discovery, like phrase2vec?
pds.r.medications.results$normalized <-
  stringr::str_replace_all(pds.r.medications.results$normalized, normalization.rules)


###

# eliminate initial space
# also remove initial punct?

pds.r.medications.results$normalized <-
  gsub(pattern = "^\\W+",
       replacement = "",
       x = pds.r.medications.results$normalized)

pds.r.medications.results$normalized <-
  gsub(
    pattern = "_",
    replacement = " ",
    x = pds.r.medications.results$normalized,
    fixed = TRUE
  )

pds.r.medications.results$normalized <-
  gsub(
    pattern = "(",
    replacement = " ",
    x = pds.r.medications.results$normalized,
    fixed = TRUE
  )

pds.r.medications.results$normalized <-
  gsub(
    pattern = ")",
    replacement = " ",
    x = pds.r.medications.results$normalized,
    fixed = TRUE
  )

pds.r.medications.results$normalized <-
  gsub(
    pattern = "&",
    replacement = " ",
    x = pds.r.medications.results$normalized,
    fixed = TRUE
  )

pds.r.medications.results$normalized <-
  gsub(
    pattern = "=",
    replacement = " ",
    x = pds.r.medications.results$normalized,
    fixed = TRUE
  )

# run-on correction
pds.r.medications.results$normalized <-
  gsub(
    "(\\d)([^ \\.0123456789])",
    replacement = "\\1 \\2",
    x = pds.r.medications.results$normalized,
    fixed = FALSE
  )

# eliminate trailing space
# also remove trailing punct ??
pds.r.medications.results$normalized <-
  gsub(pattern = "\\W+$",
       replacement = "",
       x = pds.r.medications.results$normalized)


# extra spaces
pds.r.medications.results$normalized <- gsub(pattern = " +",
                                             replacement = " ",
                                             x = pds.r.medications.results$normalized)

# extra any-whitespaces
pds.r.medications.results$normalized <-
  gsub(pattern = "\\s+",
       replacement = " ",
       x = pds.r.medications.results$normalized)

###

# query on both normalized full name and generic name.
# may not apply to input sources other than PDS?
# not currently requiring that PDS r_medications
# are annotated with a current single ingredient rxcui
query.list <-
  sort(unique(
    c(
      pds.r.medications.results$normalized[pds.r.medications.results$EMPI_COUNT > config$min.empi.count &
                                             !(is.na(pds.r.medications.results$normalized)) &
                                             nchar(pds.r.medications.results$normalized) > 0],
      pds.r.medications.results$GENERIC_NAME.lc[pds.r.medications.results$EMPI_COUNT > config$min.empi.count &
                                                  !(is.na(pds.r.medications.results$normalized)) &
                                                  nchar(pds.r.medications.results$GENERIC_NAME.lc) > 0]
    )
  ))

approximate.term.res <- bulk.approximateTerm(query.list)

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
    x = pds.r.medications.results,
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
    x = pds.r.medications.results,
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
    "EMPI_COUNT",
    "FK_MEDICATION_ID",
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

###

load(config$rf.model.savepath)

####

temp <-
  pds.approximate.original.dists

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
pre <- unique(temp$FK_MEDICATION_ID)
temp <- temp[complete.cases(temp), ]
post <- unique(temp$FK_MEDICATION_ID)
lost <- setdiff(pre, post)
lost <-
  pds.approximate.original.dists[pds.approximate.original.dists$FK_MEDICATION_ID %in% lost ,]

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

all.keys <- unique(pds.r.medications.results$FK_MEDICATION_ID)

covered.keys <-
  unique(performance.frame$FK[performance.frame$rf_responses != "more distant"])

coverage <- length(covered.keys) / length(all.keys)

print(coverage)

uncovered.keys <- setdiff(all.keys, covered.keys)

# save for followup?
uncovered.frame <-
  pds.approximate.original.dists[pds.approximate.original.dists$FK_MEDICATION_ID %in% uncovered.keys , ]

###

classification.res.tidied <-
  performance.frame[, c(
    "FK_MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "RXNORM",
    "EMPI_COUNT",
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

classification.res.tidied.id <-
  classification.res.tidied[classification.res.tidied$override == "identical", ]
best.identical <-
  aggregate(
    classification.res.tidied.id$identical,
    list(classification.res.tidied.id$FK_MEDICATION_ID),
    FUN = max
  )
colnames(best.identical) <- c("FK_MEDICATION_ID", "identical")
classification.res.tidied.id <-
  base::merge(classification.res.tidied.id, best.identical)

classification.res.tidied.onehop <-
  classification.res.tidied[(
    classification.res.tidied$override != "identical" &
      classification.res.tidied$override != "more distant" &
      (
        !(
          classification.res.tidied$FK_MEDICATION_ID %in% classification.res.tidied.id$FK_MEDICATION_ID
        )
      )
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
    list(classification.res.tidied.onehop$FK_MEDICATION_ID),
    FUN = max
  )
colnames(best.onehop) <-
  c("FK_MEDICATION_ID", "probs.matrix.rowmax")
classification.res.tidied.onehop <-
  base::merge(classification.res.tidied.onehop, best.onehop)

classification.res.tidied.md <-
  classification.res.tidied[classification.res.tidied$override == "more distant" &
                              (
                                !(
                                  classification.res.tidied$FK_MEDICATION_ID %in% classification.res.tidied.id$FK_MEDICATION_ID
                                )
                              ) &
                              (
                                !(
                                  classification.res.tidied$FK_MEDICATION_ID %in% classification.res.tidied.onehop$FK_MEDICATION_ID
                                )
                              ) , ]

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
    list(classification.res.tidied.md$FK_MEDICATION_ID),
    FUN = max
  )
colnames(best.md) <- c("FK_MEDICATION_ID", "probs.matrix.rowmax")
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

# conclusion based on data

types <-
  rep("http://purl.obolibrary.org/obo/OBI_0001909",
      nrow(classification.res.tidied))

source_med_types <-
  rep("http://purl.obolibrary.org/obo/PDRO_0000024",
      nrow(classification.res.tidied))

classification.res.tidied <-
  cbind.data.frame(uuids , types, source_med_types, classification.res.tidied)

####

med_map_csv_cols <- read_csv("med_map_csv_cols.csv")

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

# graph name/column relationships are in graphs.cols
# would theoretically be better to iterate over that
# but will use  hard-coded names as special actions for now

keepers <-
  med_map_csv_cols$more_generic %in% setdiff(graphs.cols[['classified_results']], "source_has_rxcui")

headers <-
  rbind.data.frame(med_map_csv_cols$more_generic, med_map_csv_cols$robot)
colnames(headers) <- paste0("X", 1:ncol(headers))
headers <- headers[, keepers]

write_csv(
  x = headers,
  path = config$final.predictions.writepath,
  append = FALSE,
  col_names = FALSE
)

body <- unique(classification.res.tidied[, keepers])

write_csv(
  x = body,
  path = config$final.predictions.writepath,
  append = TRUE,
  col_names = FALSE
)

####

# should really extract this from pds.r.medications.results

keepers <-
  med_map_csv_cols$more_generic %in% setdiff(graphs.cols[['source_meds']], "source_has_rxcui")
# ROBOT is interpreting both FALSE and TRUE as 'false'^^xsd:boolean

headers <-
  rbind.data.frame(med_map_csv_cols$more_generic, med_map_csv_cols$robot)
colnames(headers) <- paste0("X", 1:ncol(headers))
headers <- headers[, keepers]
headers <- as.matrix(headers)
headers[2, 2] <- "ID"

write_csv(
  x = as.data.frame(headers),
  path = "source_meds.csv",
  append = FALSE,
  col_names = FALSE
)

body <- unique(classification.res.tidied[, keepers])
body$source_rxcui[body$source_rxcui == 'http://purl.bioontology.org/ontology/RXNORM/'] <-
  ''

write_csv(
  x = body,
  path = "source_meds.csv",
  append = TRUE,
  col_names = FALSE
)
