source("rxnav_med_mapping_setup.R", chdir = TRUE)

# currently unused
# config$tune.rf boolean

# the target of the rf prediction over search results is set in the config file
# this script assumes it is "rxnmatch"... is the search results exactly right?
# I have stubs of code here and in other scripts to account for RxNorm assigned proximities
#   "RELA"

# may need to reactivate at some point
rxnCon <-   dbConnect(
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

random.str.q <- paste0(
  "SELECT
  RXCUI ,
  RXAUI ,
  SAB ,
  TTY ,
  STR
  FROM
  rxnorm_current.RXNCONSO r
  ORDER BY
  RAND()
  LIMIT ",
  config$approximate.row.count
)

random.str.res <- dbGetQuery(rxnCon, random.str.q)

print(table(random.str.res$TTY, random.str.res$SAB))

random.str.res$bad.tty <-
  (random.str.res$TTY %in%  config$excluded.term.types) |
  (random.str.res$TTY == 'SY' &
     (!(
       random.str.res$SAB %in% config$allowed.synonym.sources
     )))

# throw out really long query strings?
# hist(log10(nchar(random.str.res$STR)), breaks = 99)
# see PDS r_medication full_name histogram elsewhere
# somewhat rght skewed. 100 good cutoff
random.str.res$STR.lc <- tolower(random.str.res$STR)

### DOES THIS (incomplete merges from discarded sandom rxnorm string inputs)
###   EFFECT COVERAGE CALCULATION?
random.queries <-
  sort(unique(random.str.res$STR.lc[!random.str.res$bad.tty &
                                      nchar(random.str.res$STR) < config$approximate.max.chars]))

# since I'm running the queries against a local rxnav-in-a-box,
# i haven't applied and error handling
# whoops, with 100 000 queries -> 70 000 unique normalized
# it seemed to have frozen after pot...
#  confirm wherehter there is some technical limit
# the queries are being submitted one at a time... is there a bulk submission?
# 30 000 -> 22 000 unique normalized queries
# c0...->cz... ~ 2 minutes
# 1 hour total? no, only 20 minutes
start.time <- Sys.time()
approximate.term.res <- bulk.approximateTerm(random.queries)
end.time <- Sys.time()

rxnCon <-   dbConnect(
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
rxaui.asserted.string.res <-
  bulk.rxaui.asserted.strings(approximate.term.res$rxaui,
                              chunk.count = config$rxaui.asserted.strings.chunk.count)

hist(log10(nchar(rxaui.asserted.string.res$STR)), breaks = 99)
print(table(rxaui.asserted.string.res$TTY))

rxaui.asserted.string.res$too.long <-
  nchar(rxaui.asserted.string.res$STR) > config$approximate.max.chars
rxaui.asserted.string.res$bad.tty <-
  rxaui.asserted.string.res$TTY %in% config$excluded.term.types |
  (rxaui.asserted.string.res$TTY == "SY" &
     (
       !(
         rxaui.asserted.string.res$SAB %in% config$allowed.synonym.sources
       )
     ))

approximate.with.original <-
  base::merge(approximate.term.res, rxaui.asserted.string.res[!(rxaui.asserted.string.res$too.long |
                                                                  rxaui.asserted.string.res$bad.tty) ,])

print(table(nchar(approximate.with.original$STR)))
print(table(approximate.with.original$TTY))

unknowns.approximate.original <-
  base::merge(
    x = random.str.res,
    y = approximate.with.original,
    by.x = "STR.lc",
    by.y = "query",
    suffixes = c(".q", ".sr")
  )

string.dist.mat.res <-
  get.string.dist.mat(unknowns.approximate.original[, c("STR.lc", "STR.lc.sr")])

string.dist.mat.res <- unique(string.dist.mat.res)

unknowns.approximate.original.dists <-
  base::merge(
    x = unknowns.approximate.original,
    y = string.dist.mat.res,
    by.x = c("STR.lc", "STR.lc.sr"),
    by.y = c("STR.lc", "STR.lc.sr"),
    suffixes = c("", ".dist")
  )

# skip rela semantic proximity for now

rxnCon <-   dbConnect(
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

rxnrels <-
  dbGetQuery(
    rxnCon,
    "select
    RXCUI2 ,
    r.RELA ,
    r.RXCUI1
    from
    rxnorm_current.RXNREL r
    where
    RXCUI1 != ''
    and RXCUI2 != ''"
  )


unknowns.approximate.original.dists <-
  base::merge(
    x = unknowns.approximate.original.dists,
    y = rxnrels,
    by.x = c("RXCUI", "rxcui"),
    by.y = c("RXCUI2", "RXCUI1"),
    suffixes = c("", ".rel"),
    all.x = TRUE
  )

unknowns.approximate.original.dists$RELA[unknowns.approximate.original.dists$RXCUI ==
                                           unknowns.approximate.original.dists$rxcui] <-
  'identical'

unknowns.approximate.original.dists$RELA[is.na(unknowns.approximate.original.dists$RELA)] <-
  'more distant'

rels.tab <-
  table(unknowns.approximate.original.dists$RELA, useNA = 'always')
rels.tab <- cbind.data.frame(names(rels.tab), as.numeric(rels.tab))

print(rels.tab)

###   ###   ###

unknowns.approximate.original.dists$rxnmatch <-
  unknowns.approximate.original.dists$RXCUI == unknowns.approximate.original.dists$rxcui

unknowns.approximate.original.dists$q.char <-
  nchar(unknowns.approximate.original.dists$STR.q)
temp <- unknowns.approximate.original.dists$STR.q
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
unknowns.approximate.original.dists$q.words <- temp

unknowns.approximate.original.dists$sr.char <-
  nchar(unknowns.approximate.original.dists$STR.sr)
temp <- unknowns.approximate.original.dists$STR.sr
temp <- strsplit(x = temp, split = " +")
temp <- sapply(temp, length)
unknowns.approximate.original.dists$sr.words <- temp

###   ###   ###

# will need to get factors in the right order and partition appropriately for training
# drop antyhign that can't be partitioned

all.cols <-
  sort(colnames(unknowns.approximate.original.dists))

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
    "bad.tty.q",
    "bad.tty.sr",
    "too.long"
  )

accounted.cols <-
  c(config$target.col,
    numeric.predictors,
    factor.predictors,
    ignore.cols)

print(setdiff(all.cols, accounted.cols))
print(setdiff(accounted.cols, all.cols))
print(sort(table(accounted.cols)))

# unknowns.approximate.original.dists[factor.predictors] <-
#   lapply(unknowns.approximate.original.dists[factor.predictors], as.factor)

# > sort(table(unknowns.approximate.original.dists$TTY.q))
#
# PTGB       SYGB     RXN_IN        MIN       GPCK         CE         DF        PEP MTH_RXN_BD MTH_RXN_DP         N1         PM
# 5         16         35         37         42         47         47         47         48         48         50         53
# NM        FSY        PIN MTH_RXN_CD         MH         ET         GN       SBDF         MS       SCDF       SBDG         BN
# 66         77         82        103        123        164        164        303        314        480        585        608
# SCDG         SU       SBDC        SBD       SCDC         AB         FN        CDA       TMSY         PT        PSN        CDD
# 619        670        675        812        863        891        952       1070       1088       1130       1244       1382
# CDC        SCD         IN         SY         CD         BD         DP
# 1467       1643       1647       2382       2667       2851       7677

unknowns.approximate.original.dists[, config$target.col] <-
  as.factor(unknowns.approximate.original.dists[, config$target.col])

placeholder <-
  lapply(names(config$factor.levels), function(current.factor) {
    print(current.factor)
    unknowns.approximate.original.dists[, current.factor] <<-
      as.character(unknowns.approximate.original.dists[, current.factor])
    unknowns.approximate.original.dists[, current.factor] <<-
      factor(unknowns.approximate.original.dists[, current.factor],
             levels = config$factor.levels[[current.factor]])
    print(table(unknowns.approximate.original.dists[, current.factor]))
    return(NULL)
  })

unknowns.approximate.original.dists <-
  unknowns.approximate.original.dists[complete.cases(unknowns.approximate.original.dists), ]

coverage.check <-
  unique(unknowns.approximate.original.dists$STR.q)

coverage.check.randos <- runif(length(coverage.check))

coverage.check <-
  coverage.check[coverage.check.randos > (1 - config$coverage.check.fraction)]

coverage.check.frame <-
  unknowns.approximate.original.dists[unknowns.approximate.original.dists$STR.q %in% coverage.check , ]

# using rela as a target (semantic proximity)? include it below
train.test <-
  unknowns.approximate.original.dists[!(unknowns.approximate.original.dists$STR.q %in% coverage.check) ,
                                      c(config$target.col, numeric.predictors, factor.predictors)]

train.test <-
  train.test[, c(config$target.col, config$important.features)]

strat.res <-
  stratified(train.test,
             c(
               config$target.col,
               intersect(factor.predictors, config$important.features)
             ),
             config$train.split,
             bothSets = TRUE)

train.frame <- strat.res[[1]]

test.frame <- strat.res[[2]]

###   ###   ###

### probably would require retuning (ntree, mtry, important factors) if switching back to predicting relations

# 10 minutes with 30 000 labels queried from RxNorm
# ~ 20 000 (case?) normalized unique queries
# ~ 450 000 rows in trainframe

target <- as.data.frame(train.frame)
target <- target[, config$target.col]
features <- as.data.frame(train.frame)
drops <- config$target.col
features <- features[,!(names(features) %in% drops)]

# hah! tuning determined that 11 was a good mtry, but only 9 features were deemd important
# use |important features| - 1

if (config$static.mtry > ncol(train.frame) - 2) {
  static.mtry <- ncol(train.frame) - 2
} else {
  static.mtry <- config$static.mtry
}

Sys.time()
rf_classifier <-
  randomForest(
    x = features,
    y = target,
    ntree = config$static.ntree,
    mtry = static.mtry
  )
Sys.time()

###   ###   ###

print(Sys.time())
timed.system <- system.time(rf_responses <-
                              predict(rf_classifier, test.frame, type = "response"))
print(Sys.time())


print(Sys.time())
timed.system <- system.time(rf_probs <-
                              predict(rf_classifier, test.frame, type = "prob"))
print(Sys.time())

performance.frame <-
  cbind.data.frame(test.frame, rf_responses, rf_probs)

performance.frame$overridden <- performance.frame$rf_responses
table(performance.frame$overridden)

# performance.frame$overridden[performance.frame$score == 100] <- "TRUE"


performance.frame$overridden[performance.frame$score == 100] <-
  "identical"
performance.frame$overridden[performance.frame$score == 0] <-
  "more distant"
table(performance.frame$overridden)

###   ###   ###

# print(
#   confusionMatrix(performance.frame$overridden, test.frame$rxnmatch, positive = "TRUE")
# )

print(confusionMatrix(performance.frame$overridden, test.frame$RELA, positive = "TRUE"))

# get from config
write.csv(rf_classifier$confusion, file = config$testing.confusion.writepath)

### ROC options for multi class are different from teh options for single class
# # ROCRpred <-
# #   prediction(
# #     as.numeric(performance.frame$overridden),
# #     as.numeric(performance.frame$rxnmatch)
# #   )
#
# ROCRpred <-
#   prediction(
#     as.numeric(performance.frame$overridden),
#     as.numeric(performance.frame$RELA)
#   )
#
# plot(performance(ROCRpred, 'tpr', 'fpr'), main = "ROCR")
#
# auc.perf  <- performance(ROCRpred, measure = "auc")
# print(auc.perf@y.values)
#
# ###

### PICK BACK UP WTH COVERAGE HERE.... "MORE DISTANT" ONLY MEDS ARE UNCOVERED

print(Sys.time())
timed.system <- system.time(coverage_probs <-
                              predict(rf_classifier, coverage.check.frame, type = "prob"))
print(Sys.time())


print(Sys.time())
timed.system <- system.time(
  coverage_responses <-
    predict(rf_classifier, coverage.check.frame, type = "response")
)
print(Sys.time())

coverage.check.frame <-
  cbind.data.frame(coverage.check.frame, coverage_responses, coverage_probs)

covered.rxcuis <-
  unique(coverage.check.frame$RXCUI[coverage.check.frame$coverage_responses != 'more distant'])
attempted.rxcuis <- unique(coverage.check.frame$RXCUI)
coverage <- length(covered.rxcuis) / length(attempted.rxcuis)

print(coverage)

# # include prediction with  score = 100 in rxnmatch = true, even if the RF doesn't think so
# acceptable.coverage.search.results <-
#   coverage.check.frame[coverage.check.frame$coverage_responses == TRUE |
#                        coverage.check.frame$score == 100 ,]
#
# submitted.for.coverage <- unique(coverage.check.frame$RXCUI)
# accepted.from.coverage <-
#   unique(acceptable.coverage.search.results$RXCUI)
#
# coverage <-
#   length(accepted.from.coverage) / length(submitted.for.coverage)
#
# print(coverage)

# 24 MB... on the large size for github
save(rf_classifier, file = config$rf.model.savepath)

# could even save all objects in memory for QC/debugging in the future
# save.image("no_tuning_202003041313.Rdata")
