# assumes this script has been launched from the current working directory that contains
#  rxnav_med_mapping_setup.R, rxnav_med_mapping.yaml

source("rxnav_med_mapping_setup.R")

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
timed.system <- system.time(source.medications <-
                              dbGetQuery(pdsConnection, my.query))
print(Sys.time())
print(timed.system)

# Close connection
dbDisconnect(pdsConnection)

# should ahve applied this in the SQL query

dput(colnames(source.medications))

# c("FK_MEDICATION_ID", "FULL_NAME", "GENERIC_NAME", "RXNORM", "EMPI_COUNT")

colnames(source.medications) <-
  c("MEDICATION_ID",
    "FULL_NAME",
    "GENERIC_NAME",
    "RXNORM",
    "MEDICATION_COUNT")

write.table(
  source.medications,
  config$source.medications.savepath,
  append = FALSE,
  quote = TRUE,
  sep = "|",
  row.names = FALSE,
  col.names = TRUE
)

save(source.medications,
     file = config$pds.rmedication.result.savepath)
