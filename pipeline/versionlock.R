library(jsonlite)

vl.fn <- "build/versionlock.json"

action.request <- commandArgs(trailingOnly = TRUE)

cat(paste0(
  "\nYou provided the following arguments: ",
  paste0(action.request, collapse = " "),
  "\n\n"
))

if (action.request[[1]] == "create") {
  cat("Attempting to create the version lock.\n\n")
  if (length(action.request) > 1) {
    vl.exists <- file_test("-f", vl.fn)
    if (vl.exists) {
      cat(paste0("Refusing to overwrite ", vl.fn, " in create mode.\n\n"))
    } else {
      # cat(paste0('Using "', action.request[[2]], '" as the semantic version\n\n'))
      tm <- as.POSIXlt(Sys.time(), "UTC", "%Y-%m-%dT%H:%M:%S")
      tm <- strftime(tm , "%Y-%m-%d")
      # cat(paste0('Using "', tm, '" as the datestamp\n\n'))
      payload <-
        toJSON(list(semantic = action.request[[2]], datestamp = tm))
      cat(paste0("Writing\n", payload, "\nto ", vl.fn, "\n\n"))
      write_json(x = payload, path = vl.fn)
      # print(write.success)
      # add test or exception handling for json write
    }
  } else {
    cat("create requires a second argument, the semantic version, like 1.0.7\n\n")
  }
} else if (action.request[[1]] == "overwrite") {
  print("I will overwrite the version lock")
} else if (action.request[[1]] == "release") {
  cat("Attempting to release the version lock by renaming the file.\n\n")
  vl.exists <- file_test("-f", vl.fn)
  if (vl.exists) {
    cat("Version lock file info:\n")
    temp <- t(file.info(vl.fn))
    print(temp)
    cat("\n\n")
    tm <- as.POSIXlt(Sys.time(), "UTC", "%Y-%m-%dT%H:%M:%S")
    tm <- strftime(tm , "%Y%m%d%H%M%S")
    new.fn <- paste0(vl.fn, ".", tm)
    rename.success <- file.rename(from = vl.fn, new.fn)
    if (rename.success) {
      cat(paste0("Renamed to ", new.fn, "\n\n"))
    } else {
      cat(paste0("Couldn't rename ", vl.fn, "\n\n"))
    }
  } else {
    cat(paste0("I can't find a ", vl.fn, " to delete\n\n"))
  }
} else {
  cat(
    paste0(
      'This script requires exactly one of the following commands: create, overwrite, or release.\n',
      'create and overwrite also take a semantic version argument, like 1.0.7\n\n'
    )
  )
}