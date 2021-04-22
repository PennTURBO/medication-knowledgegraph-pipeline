options(java.parameters = "-Xmx6g")

library(rJava)
library(RJDBC)
library(config)

config.file <- "/test/rxnav_test_setup.yaml"

config <- config::get(file = config.file)

print("config$mysql.jdbc.path")
print(config$mysql.jdbc.path)

print("config$rxnav.mysql.address")
print(config$rxnav.mysql.address)

print("config$rxnav.mysql.port")
print(config$rxnav.mysql.port)

print("config$rxnav.mysql.user")
print(config$rxnav.mysql.user)

print("config$rxnav.mysql.pw")
print(config$rxnav.mysql.pw)

rxnDriver <-
  JDBC(driverClass = "com.mysql.cj.jdbc.Driver",
       classPath = config$mysql.jdbc.path)

print(1)

print(
 paste0(
      "jdbc:mysql://",
      config$rxnav.mysql.address,
      ":",
      config$rxnav.mysql.port
    )
)

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

print(rxnCon)

print(2)

dbGetQuery(rxnCon, "select RSAB from rxnorm_current.RXNSAB r")

rxnav.test.and.refresh <- function() {
  local.q <- "select RSAB from rxnorm_current.RXNSAB r"
  tryCatch({
#    dbGetQuery(rxnCon, local.q)
    foo <- dbGetQuery(rxnCon, local.q)
    print(foo)
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
    dbGetQuery(rxnCon, local.q)
  }, finally = {

  })
}

rxnav.test.and.refresh()

print(3)
