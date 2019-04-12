# do tree number vs error with importance detection off
# all features or just imporant?

static.mtry <- 10
rf_classifier <- randomForest(
  my.form ,
  data = trainframe,
  ntree = 500,
  mtry = static.mtry,
  get.importance =  FALSE
)

err.rate.frame <- as.data.frame(rf_classifier$err.rate)
plot(
  rownames(err.rate.frame),
  err.rate.frame$OOB,
  pch = 20,
  type = "l",
  lty = 1
)

# assessing mtry will require running the training at various mtry levels and examining the resulting training error

static.ntree <- 300

err.vs.mtry <- lapply(15:1, function(current.mtry) {
  print(current.mtry)
  rf_classifier <- randomForest(
    my.form ,
    data = trainframe,
    ntree = static.ntree,
    mtry = current.mtry,
    get.importance =  FALSE
  )
  err.at.current <- min(rf_classifier$err.rate[, 1])
  print(err.at.current)
  return(list(current.mtry, err.at.current))
})

err.vs.mtry <- do.call(rbind.data.frame, err.vs.mtry)
names(err.vs.mtry) <- c("mtry", "oob.err")
plot(err.vs.mtry$mtry, err.vs.mtry$oob.err, type = 'l')

###   ###   ###

# feature importance

get.importance.Q <- TRUE
my.ntree = 200
my.mtry = 10

print(Sys.time())
timed.system <- system.time(
  rf_classifier <- randomForest(
    my.form ,
    data = trainframe,
    ntree = my.ntree,
    mtry = my.mtry,
    get.importance = get.importance.Q
  )
)


print(rf_classifier)
print(timed.system)
print((1 - save.for.coverage.frac) * next.scaling * train.frac)
print(next.scaling)

importance.frame <-
  cbind.data.frame(rownames(rf_classifier$importance),
                   as.numeric(rf_classifier$importance))
names(importance.frame) <- c('feature', 'MeanDecreaseGini')
importance.frame$relimport <-
  importance.frame$MeanDecreaseGini / (max(importance.frame$MeanDecreaseGini))

importance.frame$suggested.drop <-
  importance.frame$feature %in% tfn.excessive

empirically.important <-
  as.character(importance.frame$feature[importance.frame$relimport > 0.1])

save(empirically.important, file = "empirically_important.Rdata")

# save.image("all_features.Rdata")

###   ###   ###
