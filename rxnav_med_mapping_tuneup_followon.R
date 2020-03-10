library(jsonlite)

# 3000 queries
# each mtry step ~ 10 minutes

max.ntry <- ncol(train.frame) - 1
static.ntree <- 500

err.vs.mtry <- lapply(max.ntry:1, function(current.mtry) {
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

save.image("tuning_followon.Rdata")

names(err.vs.mtry) <- max.ntry:1

names(err.vs.mtry[["9"]])

representative.error.rate.obj <- err.vs.mtry[["9"]]$err.rate

str(representative.error.rate.obj)

just.oobs <- lapply(err.vs.mtry, function(current.mtry) {
  temp <- current.mtry$err.rate[, 1]
  return(temp)
})

just.oobs <- do.call(cbind, just.oobs)

image(log10(just.oobs), xlab = "ntree: '0' = 1, '1' = 500", ylab = "mtry: '1' = 1, '0' = 16")

# oob error vs mytry
plot(just.oobs[, "11"])

# oob error vs ntree
plot(rev(just.oobs[200, ]))

importances <- err.vs.mtry[["11"]]$importance

importances <-
  cbind.data.frame(rownames(importances), as.numeric(importances))

colnames(importances) <- c("feature", "MeanDecreaseGini")
importances$rel.importance <-
  importances$MeanDecreaseGini / max(importances$MeanDecreaseGini)

importances <- importances[order(importances$rel.importance),]

plot(importances$MeanDecreaseGini)

# how to find an inflection point programatically
toJSON(importances$feature[importances$rel.importance > 0.15])
