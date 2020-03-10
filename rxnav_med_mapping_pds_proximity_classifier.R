# assumes this script has been launched from the current workign directory that contains
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

### what's the realtiobship between liklihood of arxnorm annotation and # of patients receivign order

ggplot(
  pds.r.medications.results,
  aes(
    x = EMPI_COUNT + 0.01,
    color = pds.rxn.annotated,
    fill = pds.rxn.annotated
  )
) + geom_histogram(alpha = 0.1) + scale_x_log10() + scale_y_sqrt()

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

pds.r.medications.results$normalized <-
  tolower(pds.r.medications.results$FULL_NAME)
pds.r.medications.results$normalized[is.na(pds.r.medications.results$normalized)] <-
  ""

pds.r.medications.results$GENERIC_NAME.lc <-
  tolower(pds.r.medications.results$GENERIC_NAME)
pds.r.medications.results$GENERIC_NAME.lc[is.na(pds.r.medications.results$GENERIC_NAME.lc)] <-
  ""

# does the order of applying the normalizastions matter?
# use some kind of automted synonym discovery, like phrase2vec?
pds.r.medications.results$normalized <-
  stringr::str_replace_all(pds.r.medications.results$normalized, normalization.rules)


###

# eliminate initial space
# also remove intial punct?
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

# runon correction
pds.r.medications.results$normalized <-
  gsub(
    "(\\d)([^ \\.0123456789])",
    replacement = "\\1 \\2",
    x = pds.r.medications.results$normalized,
    fixed = FALSE
  )

# eliminate trailing space
# also remove trianing punct ??
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

# query on both fullname and generic name. may not apply to input sources other than PDS?
# not currently requiring that pds rmedications are annoated with a current single ingredient rxcui
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

random.sampler <- runif(length(query.list))
random.sampler <-
  random.sampler > (1 - (config$pds2rxnav.fraction / 100))
query.list <- query.list[random.sampler]

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
  base::merge(approximate.term.res, rxaui.asserted.string.res)

pds.full_name.approximate <-
  base::merge(
    x = pds.r.medications.results,
    y = approximate.with.original,
    by.x = "normalized",
    by.y = "query",
    suffixes = c(".q", ".sr")
  )

pds.full_name.approximate$query.source <- "normalized FULL_NAME"
pds.full_name.approximate$query.val <-
  pds.full_name.approximate$normalized

pds.generic_name.approximate <-
  base::merge(
    x = pds.r.medications.results,
    y = approximate.with.original,
    by.x = "GENERIC_NAME.lc",
    by.y = "query",
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
  base::merge(
    x = pds.approximately,
    y = string.dist.mat.res,
    by.x = c("query.val", "STR.lc"),
    by.y = c("query.val", "STR.lc"),
    suffixes = c("", ".dist")
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

temp <-
  pds.approximate.original.dists


print("begin reordering factors")

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

print("reordering factors complete")

print(str(temp))

# temp$TTY.sr <- as.character(temp$TTY.sr)
# temp$TTY.sr <-
#   factor(temp$TTY.sr,
#          levels = config$factor.levels$TTY.sr)
#
# temp$SAB.sr <- as.character(temp$SAB.sr)
# temp$SAB.sr <-
#   factor(temp$SAB.sr,
#          levels = levels(unknowns.approximate.original.dists$SAB.sr))

temp <- temp[complete.cases(temp), ]

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

# performance.frame$override[performance.frame$score == 100] <- "TRUE"

performance.frame$override[performance.frame$score == 100] <-
  "identical"
performance.frame$override[performance.frame$score == 0] <-
  "more distant"
table(performance.frame$override)

all.keys <- unique(performance.frame$FK_MEDICATION_ID)

# covered.keys <- unique(performance.frame$FK_MEDICATION_ID[performance.frame$override == "TRUE"])

covered.keys <-
  unique(performance.frame$FK[performance.frame$rf_responses != "more distant"])

coverage <- length(covered.keys) / length(all.keys)

print(coverage)

uncovered.keys <- setdiff(all.keys, covered.keys)

# save for followup?
# first extract "best" hit for each query?
uncovered.frame <-
  performance.frame[performance.frame$FK_MEDICATION_ID %in% uncovered.keys , ]

# i haven't guaranteed that all inputs ahve beena ccoutned for
# maybe no search result was returned for some
# no EASY colculation as long as a fraction of the PDS terms are being sent for searching
write.csv(
  performance.frame,
  file = config$final.predictions.writepath,
  row.names = FALSE
)
