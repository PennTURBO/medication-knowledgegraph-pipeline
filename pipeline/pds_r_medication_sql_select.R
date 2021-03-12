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
  "https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup_action_versioning.R"
)

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

####

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
GROUP BY
rm.PK_MEDICATION_ID,
rm.FULL_NAME,
rm.GENERIC_NAME,
rm.RXNORM"

# 30 minutes
print(Sys.time())
timed.system <- system.time(source.medications <-
                              dbGetQuery(pdsConnection, my.query))
print(Sys.time())
print(timed.system)

# Close connection
dbDisconnect(pdsConnection)

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

# save.image("pds_r_medication_sql_select.Rdata")

save(source.medications,
     version.list,
     file = config$source.medications.Rdata.path)
