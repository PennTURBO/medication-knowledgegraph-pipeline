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


print(Sys.time())
timed.system <- system.time(source.medications <-
                              dbGetQuery(pdsConnection, my.query))
print(Sys.time())
print(timed.system)

# Close connection
dbDisconnect(pdsConnection)

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

save.image("pds_r_medication_sql_select.Rdata")

# optional exploration

# temp <- table(source.medications$MEDICATION_COUNT)
# temp <- cbind.data.frame(names(temp), as.numeric(temp))
# colnames(temp) <- c('patient.count', 'medication.count')
# temp$patient.count <- as.numeric(as.character(temp$patient.count))
#
# addmargins(table(is.na(source.medications$GENERIC_NAME)))
#
# addmargins(table(is.na(source.medications$RXNORM)))
#
# library(ggplot2)
#
# source.medications$has.ehr.rxn <- !is.na(source.medications$RXNORM)
#
# source.medications$fn.nchar <- nchar(source.medications$FULL_NAME)
#
# # Change histogram plot fill colors by groups
# ggplot(source.medications, aes(x=MEDICATION_COUNT, fill=has.ehr.rxn, color=has.ehr.rxn)) +
#   geom_histogram(position="identity") + scale_x_log10()
# # Use semi-transparent fill
# p<-ggplot(source.medications, aes(x=MEDICATION_COUNT, fill=has.ehr.rxn, color=has.ehr.rxn)) +
#   geom_histogram(position="identity", alpha=0.5, bins = 99) + scale_x_log10()
# p
# # Add mean lines
# p+geom_vline(data=mu, aes(xintercept=grp.mean, color=sex),
#              linetype="dashed")
#
# ggplot(source.medications, aes(x=fn.nchar, fill=has.ehr.rxn, color=has.ehr.rxn)) +
#   geom_histogram(position="identity")+ scale_x_log10()
#
# mean(source.medications$fn.nchar[source.medications$has.ehr.rxn])
# mean(source.medications$fn.nchar[!source.medications$has.ehr.rxn], na.rm = TRUE)
#
# temp <- table(source.medications$RXNORM)
# temp <- cbind.data.frame(names(temp), as.numeric(temp))
# colnames(temp) <- c('rxnorm', 'medication.count')
# temp$rxnorm <- as.numeric(as.character(temp$rxnorm))

# R_MEDICATION <- read_csv("~/R_MEDICATION_202005121651.csv")
# dput(colnames(R_MEDICATION))
# 
# temp <- table(R_MEDICATION$PHARMACY_CLASS)
# temp <- cbind.data.frame(names(temp), as.numeric(temp))
# 
# R_MEDICATION$has.rxn <- !is.na(R_MEDICATION$RXNORM)
# R_MEDICATION$has.ncid <- !is.na(R_MEDICATION$FK_3M_NCID_ID)

