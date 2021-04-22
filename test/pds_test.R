options(java.parameters = "-Xmx6g")

library(rJava)
library(RJDBC)
library(config)

config.file <- "pds_test_setup.yaml"

config <- config::get(file = config.file)

print(config$oracle.jdbc.path)

pdsDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver",
       classPath = config$oracle.jdbc.path)

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

print(pdsDriver)
print(pds.con.string)
print(config$pds.user)

pdsConnection <-
  dbConnect(pdsDriver,
            pds.con.string,
            config$pds.user,
            config$pds.pw)

my.query <- "
SELECT
rm.PK_MEDICATION_ID
FROM
mdm.R_MEDICATION rm
WHERE rownum <= 1
"

print("Running:")
#print(my.query)
cat(my.query)

#source.medications <- dbGetQuery(pdsConnection, my.query)
pds.sql.output <- dbGetQuery(pdsConnection, my.query)

print("Returns:")
print(pds.sql.output)

# Close connection
dbDisconnect(pdsConnection)

#colnames(source.medications) <-
#  c("MEDICATION_ID",
#    "FULL_NAME",
#    "GENERIC_NAME",
#    "RXNORM",
#    "MEDICATION_COUNT")


#save(source.medications,
#     version.list,
#     file = config$source.medications.Rdata.path)

#save the current whole R workspace, including pulled data
#save.image("test_completed_env.Rdata")

#save only the PDS data and version
#save(source.medications,
#     version.list,
#     file = config$source.medications.Rdata.path)
