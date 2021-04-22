# set the working directory to medication-knowledgegraph-pipeline/pipeline
# for example,
# setwd("~/GitHub/medication-knowledgegraph-pipeline/pipeline")

# get global settings, functions, etc. from https://raw.githubusercontent.com/PennTURBO/turbo-globals

# some people (https://www.r-bloggers.com/reading-an-r-file-from-github/)
# say it’s necessary to load the devtools package before sourcing from GitHub?
# but the raw page is just a http-accessible page of text, right?

# requires a properly formatted "turbo_R_setup.yaml" in medication-knowledgegraph-pipeline/config
# or better yet, a symbolic link to a centrally loated "turbo_R_setup.yaml", which could be used by multiple pipelines
# see https://github.com/PennTURBO/turbo-globals/blob/master/turbo_R_setup.template.yaml

source(
#  "https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup_action_versioning.R"
  "/pipeline/setup.R"
)

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

####

#print(config$oracle.jdbc.path)

if (config$live.pds) {

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

  #print(pdsDriver)
  #print(pds.con.string)
  #print(config$pds.user)

  pdsConnection <-
    dbConnect(pdsDriver,
              pds.con.string,
              config$pds.user,
              config$pds.pw)

  my.query <- "
  SELECT
  rm.PK_MEDICATION_ID,
  rm.FULL_NAME,
  rm.GENERIC_NAME,
  rm.RXNORM,
  COUNT(DISTINCT pe.EMPI) AS empi_count
  FROM
  mdm.R_MEDICATION rm
  LEFT JOIN MDM.ORDER_MED om ON
  rm.PK_MEDICATION_ID = om.FK_MEDICATION_ID
  LEFT JOIN MDM.PATIENT_ENCOUNTER pe ON
  om.FK_PATIENT_ENCOUNTER_ID = pe.PK_PATIENT_ENCOUNTER_ID
  WHERE rownum <= 1000
  GROUP BY
  rm.PK_MEDICATION_ID,
  rm.FULL_NAME,
  rm.GENERIC_NAME,
  rm.RXNORM
  "

  #--WHERE rownum <= 1000

#TH5
#https://www.rforge.net/doc/packages/RJDBC/JDBCConnection-methods.html
#dbGetQuery is a shorthand for sendQuery + fetch. 
#Parameters n=-1, block=2048L and use.label=TRUE are passed through to fetch() others to dbSendQuery. 

#Separate out sendQuery and fetch

# print(Sys.time())

# dbSendQuery(pdsConnection, my.query)

# print(Sys.time())

# print(dbGetInfo(pdsConnection))

# source.medications <- fetch(pdsConnection)

#source.medications <- dbGetQuery(pdsConnection, my.query)

#TH5 end

  # 30 minutes
  print(Sys.time())
  timed.system <- system.time(source.medications <-
                                dbGetQuery(pdsConnection, my.query))
  print(Sys.time())
  # print(timed.system)

  # Close connection
  dbDisconnect(pdsConnection)

} else {

# source.medications <- read.csv("/data/pds_full.csv", header = TRUE)
  source.medications <- read.csv(config$pds.csv, header = TRUE)

}

# should have applied this in the SQL query
# dput(colnames(source.medications))
# c("FK_MEDICATION_ID", "FULL_NAME", "GENERIC_NAME", "RXNORM", "EMPI_COUNT")
# MEDICATION_COUNT is a lousy name. That column actullay contains a count of unique people (by EMPI)
# who received an order for that reference medication (without filtering out canceled orders, etc.)
colnames(source.medications) <-
  c("MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "RXNORM",
    "MEDICATION_COUNT")

# add option for saving as delimited text
# write.table(
#   source.medications,
#   config$source.medications.savepath,
#   append = FALSE,
#   quote = TRUE,
#   sep = "|",
#   row.names = FALSE,
#   col.names = TRUE
# )

#save whole R environment
#save.image("/data/pds_r_medication_sql_select.Rdata")

# print(version.list)
# print(config$source.medications.Rdata.path)

# print(source.medications)

save(source.medications,
     version.list,
     file = config$source.medications.Rdata.path)

