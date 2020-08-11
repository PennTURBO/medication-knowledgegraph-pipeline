library(jsonlite)
library(fields)

# features
stringdist.cols <- c("lv",
                     "lcs",
                     "qgram",
                     "cosine",
                     "jaccard",
                     "jw")

rxnav.cols <- c("score",
                "rank")

id.count.cols <- c("rxcui.count",
                   "rxcui.freq",
                   "rxaui.count",
                   "rxaui.freq")

word.char.count.cols <- c("q.char",
                          "q.words",
                          "sr.char",
                          "sr.words")

categorical.cols <- c("SAB.sr",
                      "TTY.sr")

temp <-
  cor(unknowns.approximate.original.dists[, stringdist.cols, ])

caret::findCorrelation(
  temp,
  cutoff = 0.90,
  verbose = TRUE,
  names = TRUE,
  exact = TRUE
)

# Compare row 3  and column  1 with corr  0.918
# Means:  0.735 vs 0.671 so flagging column 3
# Compare row 1  and column  2 with corr  0.979
# Means:  0.646 vs 0.647 so flagging column 2
# All correlations <= 0.9
# [1] "qgram" "lcs"

# col #1  = 'lv'
# importance calculated below says qgram most important, so remove 'lv' and 'lcs'
# sorry, circular or recursive/bootstrapping?
stringdist.cols <- setdiff(stringdist.cols, c('lv', 'lcs'))

temp <-
  cor(unknowns.approximate.original.dists[, id.count.cols, ])

caret::findCorrelation(
  temp,
  cutoff = 0.90,
  verbose = TRUE,
  names = TRUE,
  exact = TRUE
)
# keep counts or freqs but not both
id.count.cols <- c("rxcui.count",
                   "rxaui.count")

temp <-
  cor(unknowns.approximate.original.dists[, word.char.count.cols, ])

caret::findCorrelation(
  temp,
  cutoff = 0.9,
  verbose = TRUE,
  names = TRUE,
  exact = TRUE
)

# All correlations <= 0.9
# character(0)
# keep all, provided the importances are high

lowest.importance <- c('rxaui.count', 'rxaui.freq')

feature.cols <- setdiff(
  c(
    rxnav.cols,
    id.count.cols,
    categorical.cols,
    word.char.count.cols,
    stringdist.cols
  ),
  lowest.importance
)

# downsample first
keepnum <- 100000
downsampled <- nrow(unknowns.approximate.original.dists)
downsampled <- runif(downsampled)
downsampled <-
  cbind.data.frame(rownames(unknowns.approximate.original.dists), downsampled)
colnames(downsampled) <- c('rowname', 'rank')
downsampled$rowname <- as.numeric(as.character(downsampled$rowname))
downsampled <- downsampled$rowname[order(downsampled$rank)]
downsampled <- downsampled[1:keepnum]
downsampled <- unknowns.approximate.original.dists[downsampled, ]

downsampled <- downsampled[complete.cases(downsampled),]

features <- downsampled[, feature.cols]

target.col <- "RELA"

target <- downsampled[, target.col]

max.ntry <- ncol(features) - 1
min.ntry <- 5
static.ntree <- 601
min.trees <- 201

outer.start <- Sys.time()
err.vs.mtry <- lapply(max.ntry:min.ntry, function(current.mtry) {
  print(current.mtry)
  print(Sys.time())
  timed.system <- system.time(
    rf_classifier <-
      randomForest(
        x = features,
        y = target,
        ntree = static.ntree,
        mtry = current.mtry,
        get.importance =  TRUE
      )
  )
  print(Sys.time())
  print(timed.system)
  return(rf_classifier)
})
outer.end <- Sys.time()

save.image("rxnav_med_mapping_tuneup_followon.Rdata")

names(err.vs.mtry) <- max.ntry:min.ntry

just.oobs <- lapply(err.vs.mtry, function(current.mtry) {
  temp <- current.mtry$err.rate[, 1]
  return(temp)
})

just.oobs <- do.call(cbind, just.oobs)

just.oobs <- just.oobs[, ncol(just.oobs):1]

temp <- log10(just.oobs)
temp[temp == -Inf] <- NA

# set these high enough that the plot doens't show the edges with dramatically highest errors
# not cheating... just good visualizastion
min.trees <- 100
min.try <- 5

steps <- 20

fields::image.plot(
  # temp[min.trees:static.ntree, min.try:max.ntry],
  temp[min.trees:static.ntree, ],
  axes = FALSE,
  main = "log10(RF training error)\n100000 training rows",
  xlab = "ntree",
  ylab = "mtry"
)

temp <- seq(min.trees, static.ntree, static.ntree / steps)
temp.len <- length(temp)

axis(side = 1,
     at = seq(0, 1, 1 / (temp.len - 1)),
     labels = as.character(floor(seq(
       min.trees, static.ntree, static.ntree / steps
     ))))

axis(
  side = 2,
  at = seq(0,
           1, 1 / (max.ntry - min.try)),
  labels = as.character(min.try:max.ntry)
)

importances <- err.vs.mtry[["11"]]$importance

importances <-
  cbind.data.frame(rownames(importances), as.numeric(importances))

colnames(importances) <- c("feature", "MeanDecreaseGini")
importances$rel.importance <-
  importances$MeanDecreaseGini / max(importances$MeanDecreaseGini)

importances <- importances[order(importances$rel.importance), ]

plot(importances$MeanDecreaseGini)

# how to find an inflection point programatically

# why the difference in row counts?
# > dim(unknowns.approximate.original)
# [1] 95347    22
# > dim(unknowns.approximate.original.dists)
# [1] 95230    34


