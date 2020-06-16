library(devtools)

# this script queries a private database and may require a VPN, a ssh tunnel, or other similar measures

# requires a properly formatted "turbo_R_setup.yaml" in the home directory of the user who started this script
# see https://gist.github.com/turbomam/a3915d00ee55d07510493a9944f96696 for template
devtools::source_gist(id = "https://gist.github.com/turbomam/f082295aafb95e71d109d15ca4535e46")

mm.kb.solr.client <- SolrClient$new(
  host = config$med.map.kb.solr.host,
  path = "search",
  port = config$med.map.kb.solr.port
)

# what cores are available? assumes conenction has been established
solrium::cores(mm.kb.solr.client)

## examine schema?
# solrium::schema(conn = mm.kb.solr.client, name = "med_mapping_kb_labels_exp")

# # one way of confirming the connection
# print(mm.kb.solr.client)
# # could also ping it

tmm.ont <-
  rdf_parse(doc = "https://raw.githubusercontent.com/PennTURBO/med_mapping/master/tmm_ontology/tmm_ontology.ttl",
            format = "turtle")

solr.expectations.q <-
  'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
distinct ?skw ?esr
where {
    ?sqe a <http://transformunify.org/ontologies/TURBO_0022059> ;
         <http://www.w3.org/2000/01/rdf-schema#seeAlso> ?applicable_emp ;
         <http://www.w3.org/2000/01/rdf-schema#label> ?qlab ;
         <http://transformunify.org/ontologies/TURBO_0022062> ?skw ;
         <http://transformunify.org/ontologies/TURBO_0022061> ?esr .
    ?applicable_emp a ?t .
    ?t <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://transformunify.org/ontologies/TURBO_0022023> .
}
'

# getting an error from * property path in
# ?t <http://www.w3.org/2000/01/rdf-schema#subClassOf>* <http://transformunify.org/ontologies/TURBO_0022023>

# very slow
# and gets bogus results
# optional {
#   ?applicable_emp rdfs:label ?apemplab .
# }

solr.expectations.res <-
  rdf_query(rdf = tmm.ont, query = solr.expectations.q)
solr.expectations.res$esr.len <- nchar(solr.expectations.res$esr)

####

# for a reality check, let's try querying all combinations of the two fields intended for searching

qf.options <- list("medlabel", "tokens", "medlabel tokens")

results.by.qf <- lapply(qf.options, function(the.qf) {
  results.by.kw <-
    lapply(sort(unique(solr.expectations.res$skw)), function(current.kw) {
      # print("using qf:")
      print(the.qf)
      
      # print(paste0("Searching for: "))
      print(current.kw)
      
      current.esr <-
        solr.expectations.res$esr[solr.expectations.res$skw == current.kw]
      
      print("Expecting: ")
      print(current.esr)
      
      empirical.results <- solrium::solr_search(
        conn = mm.kb.solr.client,
        name = config$med.map.kb.solr.core,
        params = list(
          q = current.kw ,
          defType = "edismax",
          qf = the.qf ,
          rows = 4,
          fl = "id,medlabel,employment,definedin,tokens,score"
        )
      )
      
      # cat("\n")
      print("Found: ")
      print(empirical.results$id)
      # cat("\n")
      
      print("Missing:")
      different.set <- setdiff(current.esr, empirical.results$id)
      print(different.set)
      
      cat("\n")
      cat("\n")
      
      missing.expecteds <-
        cbind.data.frame(rep(current.kw, length(different.set)), different.set)
      
      return(missing.expecteds)
      
    })
  
  results.by.kw <- do.call(rbind.data.frame, results.by.kw)
  # print(is.data.frame(results.by.kw))
  # print(nrow(results.by.kw))
  if (nrow(results.by.kw) > 0) {
    colnames(results.by.kw) <- c("skw", "missing")
    results.by.kw$qf <- the.qf
    
    return(results.by.kw)
  }
  
})

results.by.qf <- do.call(rbind.data.frame, results.by.qf)

results.by.qf$qf <- factor(x = results.by.qf$qf, levels = unlist(qf.options))

# which qf combination has the most failures?
table(results.by.qf$qf)
