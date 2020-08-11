source("rxnav_med_mapping_setup.R")

library(ssh)

# mm.kb.solr.client <-
mm.kb.solr.client <- SolrClient$new(
  host = config$med.map.kb.solr.host,
  path = "search",
  port = config$med.map.kb.solr.port
)

# could also ping it
print(mm.kb.solr.client)

# clear the core!
mm.kb.solr.client$delete_by_query(name = config$med.map.kb.solr.core, query = "*:*")

# https://debian-administration.org/article/530/SSH_with_authentication_key_instead_of_password
session <- ssh_connect(paste0(config$ssh.user,"@",config$ssh.host))
#' @markampa@turbo-prd-app01.pmacs.upenn.edu")
print(session)

scp_upload(
  session = session,
  files = paste0(config$json.source, config$json.for.solr),
  to =  paste0(config$json.dest, config$json.for.solr),
  verbose = TRUE
)

ssh.command <-
  paste0(
    "curl 'http://localhost:8983/solr/",
    config$med.map.kb.solr.core,
    "/update?commit=true&overwrite=false' --data-binary  @",
    config$json.dest, config$json.for.solr,
    " -H 'Content-type:application/json'"
  )

print(ssh.command)

# /project/turbo_graphdb_staging/medlabels_for_chebi_for_solr.json -H 'Content-type:application/json'"
#   )

out <- ssh_exec_wait(session, command = ssh.command)

print(out)
