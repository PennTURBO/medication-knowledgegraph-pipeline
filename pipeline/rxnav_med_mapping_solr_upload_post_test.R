# MAM TODO flesh out post.via.ssh options
#  including creating that varible in the config file

# run from medication-knowledgegraph-pipeline/pipeline
# in RStudio, setwd("~/GitHub/medication-knowledgegraph-pipeline/pipeline")

# get global settings, functions, etc. from https://raw.githubusercontent.com/PennTURBO/turbo-globals

# requires a properly formatted "turbo_R_setup.yaml" in medication-knowledgegraph-pipeline/config
# or better yet, a symbolic link to a centrally located "turbo_R_setup.yaml", which could be used by multiple pipelines
# see https://github.com/PennTURBO/turbo-globals/blob/master/turbo_R_setup.template.yaml

source(
#  "https://raw.githubusercontent.com/PennTURBO/turbo-globals/master/turbo_R_setup_action_versioning.R"
  "/pipeline/setup.R"
)

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

####

# mm.kb.solr.client <-
mm.kb.solr.client <- SolrClient$new(
  host = config$med.map.kb.solr.host,
  path = "search",
  port = config$med.map.kb.solr.port
)

# could also ping it
print(mm.kb.solr.client)

# mm.kb.solr.client$core_exists(config$med.map.kb.solr.core)
# mm.kb.solr.client$core_exists("medication-employment-labels-dev")

# clear the core!
mm.kb.solr.client$delete_by_query(name = config$med.map.kb.solr.core, query = "*:*")

if (config$post.via.ssh) {
  # https://debian-administration.org/article/530/SSH_with_authentication_key_instead_of_password
  session <-
    # ssh_connect(paste0(config$ssh.user, "@", config$ssh.host))
    # ssh_connect(paste0(config$ssh.user, "@", config$ssh.host), passwd = config$ssh.password, verbose=TRUE)
    ssh_connect(paste0(config$ssh.user, "@", config$ssh.host), passwd = config$ssh.password)
  print(session)
  
  # countdown may dip to negative before finishing
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
      config$json.dest,
      config$json.for.solr,
      " -H 'Content-type:application/json'"
    )
  
  print(ssh.command)
  
  out <- ssh_exec_wait(session, command = ssh.command)
  
  print(out)
  
  ssh_disconnect(session)
} else {
  
  assembled.url <- paste0(
    url = #"http://",
    config$med.map.kb.solr.host,
    ":",
    config$med.map.kb.solr.port,
    "/solr/",
    config$med.map.kb.solr.core,
    "/update?commit=true&overwrite=false"
  )

  # print(assembled.url)
  # print(paste0(config$json.source,"/",config$json.for.solr))

  placeholder <-
    httr::POST(url = assembled.url,
               body = upload_file(paste0(config$json.source,"/",config$json.for.solr))
               , timeout(600) #seconds
#               , verbose(data_out = TRUE, data_in = TRUE, info = TRUE, ssl = TRUE)
               )
  print(placeholder)
}



####

# run the sample Solr queries from the TMM ontology

tmm.ont.url <-
  "https://raw.githubusercontent.com/PennTURBO/medication-knowledgegraph-pipeline/master/ontology/tmm_ontology.ttl"

# rdflib is convenient becasue it can pare RDF directly from a URL
# but it doesn't understand property paths
# tmm.ont <-
#   rdflib::rdf_parse(doc = tmm.ont.url,
#                     format = "turtle")

# http://transformunify.org/ontologies/TURBO_0022111 contains known problem cases
solr.queries.query <- "
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
*
where
{
?classes rdfs:subClassOf* <http://transformunify.org/ontologies/TURBO_0022059>  ;
    rdfs:label ?classlab .
?queries a ?classes ;
    rdfs:label ?qlab ;
    <http://transformunify.org/ontologies/TURBO_0022062> ?kword ;
    <http://transformunify.org/ontologies/TURBO_0022061> ?expected .
minus {
?queries a <http://transformunify.org/ontologies/TURBO_0022111>
}

}
"

# solr.queries.result <- rdflib::rdf_query(rdf = tmm.ont, query = solr.queries.query)
# rrdf seems like a better query engine but requires downloading to a tempfile
rdf.temp.file <- tempfile()
download.file(url = tmm.ont.url, destfile = rdf.temp.file)

tmm.ont <-
  rrdf::load.rdf(filename = rdf.temp.file, format = "TURTLE")

solr.queries.result <-
  rrdf::sparql.rdf(model = tmm.ont, sparql = solr.queries.query)

solr.query.template.query <- "
select
*
where {
<http://transformunify.org/ontologies/TURBO_0022078> <http://transformunify.org/ontologies/TURBO_0022060> ?template .
}
"

solr.query.template.result <-
  rrdf::sparql.rdf(model = tmm.ont, sparql = solr.query.template.query)

solr.query.template <- solr.query.template.result[1, 1]
solr.query.template <-
  sub(
    pattern = "(search keywords)",
    replacement = "",
    x = solr.query.template,
    fixed = TRUE
  )

solr.param.list <- list(defType = "edismax",
                        fl = "id,medlabel,employment,definedin,tokens,score",
                        qf = "medlabel tokens")

solr.queries.result <- as.data.frame(solr.queries.result)

unique.solr.queries <- sort(unique(solr.queries.result$queries))

placeholder <-
  lapply(unique.solr.queries, function(current.query) {
    current.kword <-
      unique(solr.queries.result$kword[solr.queries.result$queries == current.query])
    current.expected <-
      unique(solr.queries.result$expected[solr.queries.result$queries == current.query])
    
    placeholder <- lapply(current.kword, function(single.kword) {
      print(paste0("query IRI: ", current.query))
      print(paste0("Solr keyword: ", single.kword))
      print("expecting...")
      print(current.expected)
      solr.param.list[['q']] <- single.kword
      current.solr.result <-
        solr_search(
          conn = mm.kb.solr.client,
          name = config$med.map.kb.solr.core,
          params = solr.param.list
        )

      # print(current.solr.result)

      failures <- setdiff(current.expected, current.solr.result$id)
      print("failures...")
      print(failures)
      cat("\n\n")
    })
  })
