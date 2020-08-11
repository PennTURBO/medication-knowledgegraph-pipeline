library(devtools)
library(ssh)

# requires a properly formatted "turbo_R_setup.yaml" in the home directory of the user who started this script
# see https://gist.github.com/turbomam/a3915d00ee55d07510493a9944f96696 for template
devtools::source_gist(id = "https://gist.github.com/turbomam/f082295aafb95e71d109d15ca4535e46",
                      sha1 = "dbc656aaf63b23dfdd35d875f6772e7c468170a4",
                      filename = "turbo_R_setup.R")

# MAIN labels
# < 1 minute
system.time(pre.main.solr.res <-
              q2j2df(query = config$main.solr.query))

main.solr.res <-
  pre.main.solr.res[, c("mediri", "definedin",  "employment", "medlabel")]

names(main.solr.res) <-
  c("id", "definedin",  "employment", "main.label")

# clinrel structctclass labels
system.time(crsc.solr.res <-
              q2j2df(query = config$clinrel_structclass.solr))

crsc.addtions <- setdiff(crsc.solr.res$id, main.solr.res$id)

colnames(crsc.solr.res) <-
  c("main.label", "definedin", "id", "employment")

crsc.solr.res <-
  crsc.solr.res[crsc.solr.res$id %in% crsc.addtions, ]

main.solr.res <-
  rbind.data.frame(main.solr.res, crsc.solr.res[, colnames(main.solr.res)])

### DrOn's labels for ChEBI
system.time(
  dron.additional.chebi.labels <-
    q2j2df(query = config$dron.additional.chebi.label.query)
)

colnames(dron.additional.chebi.labels) <-
  c('id', 'dron.for.chebi', 'dtich')

temp <- table(dron.additional.chebi.labels$id)
temp <- cbind.data.frame(names(temp), as.numeric(temp))
colnames(temp) <- c("id", "count")
temp <- temp$id[temp$count == 1]
dron.additional.chebi.labels <-
  dron.additional.chebi.labels[dron.additional.chebi.labels$id %in% temp , c("id", "dron.for.chebi")]

merged <-
  dplyr::full_join(main.solr.res, dron.additional.chebi.labels)

#### All RxNorm alternative labels
# BROKEN as of 2020AA?

system.time(rxn.alt.lab.solr.res <-
              q2j2df(query = config$rxn.alt.lab.solr.query))

colnames(rxn.alt.lab.solr.res) <- c("rxn.alt",  "id")

temp <- colnames(rxn.alt.lab.solr.res)

rxn.alt.lab.solr.res <-
  aggregate(rxn.alt ~ id,
            data = rxn.alt.lab.solr.res,
            paste,
            collapse = "|")

merged <-
  dplyr::full_join(merged, rxn.alt.lab.solr.res)

#### chebi synonyms
system.time(chebi.synonym.res <-
              q2j2df(query = config$chebi.synonym.query))

colnames(chebi.synonym.res) <-
  c("chebi.syn",
    "synstrength",
    "synlen",
    "syntype",
    "id",
    "synsource",
    "employment" ,
    "l")

chebi.synonym.res$synsource <-
  sub(
    pattern = 'http://purl.obolibrary.org/obo/chebi#',
    replacement = '',
    x = chebi.synonym.res$synsource,
    fixed = TRUE
  )

chebi.synonym.res$syntype <-
  sub(
    pattern = 'http://purl.obolibrary.org/obo/chebi#',
    replacement = '',
    x = chebi.synonym.res$syntype,
    fixed = TRUE
  )

chebi.synonym.res$synstrength <-
  sub(
    pattern = 'http://www.geneontology.org/formats/oboInOwl#',
    replacement = '',
    x = chebi.synonym.res$synstrength,
    fixed = TRUE
  )

chebi.selected.syns <-
  unique(chebi.synonym.res[(!(is.na(chebi.synonym.res$syntype)) &
                              chebi.synonym.res$syntype == 'BRAND_NAME') |
                             chebi.synonym.res$synsource %in% c('KEGG_COMPOUND', 'KEGG_DRUG', 'DrugBank', 'UniProt') |
                             chebi.synonym.res$employment == 'http://example.com/resource/clinrel_structclass' ,
                           c("id", "chebi.syn")])

colnames(chebi.selected.syns) <- c("id", "synalt")

chebi.selected.syns$synalt <-
  as.character(chebi.selected.syns$synalt)

temp <- colnames(chebi.selected.syns)

chebi.selected.syns <-
  aggregate(synalt ~ id, data = chebi.selected.syns, paste, collapse = "|")

merged <-
  dplyr::full_join(merged, chebi.selected.syns)

merged <- merged[order(merged$id), ]

merged$chebi.demoted <- NA
merged$chebi.demoted[!is.na(merged$dron.for.chebi)] <-
  merged$main.label[!is.na(merged$dron.for.chebi)]
merged$main.label[!is.na(merged$dron.for.chebi)] <-
  merged$dron.for.chebi[!is.na(merged$dron.for.chebi)]

####

system.time(chebi.chebi.role.syns <-
              q2j2df(query = config$chebi.role.syns))

names(chebi.chebi.role.syns) <- c("id", "rolesyn")

agg <-
  aggregate(rolesyn ~ id, data = chebi.chebi.role.syns, paste, collapse = "|")

merged <-
  dplyr::full_join(merged, agg)

####

listed <-
  apply(
    X = merged,
    MARGIN = 1,
    FUN = function(currentrow) {
      print(currentrow[['id']])
      tokens <-
        c(currentrow[["main.label"]],
          currentrow[["dron.for.chebi"]],
          currentrow[["rxn.alt"]],
          currentrow[["synalt"]],
          currentrow[["rolesyn"]],
          currentrow[["chebi.demoted"]])
      tokens <- unlist(tokens)
      tokens <- unlist(strsplit(tokens, " |\\|"))
      tokens <- sort(unique(tolower(tokens)))
      # print(tokens)
      return(
        list(
          id = currentrow[['id']],
          medlabel = tolower(currentrow[['main.label']]),
          tokens = tokens,
          definedin = currentrow[['definedin']],
          employment = currentrow[['employment']]
        )
      )
    }
  )
names(listed) <- merged$id

temp <- listed
names(temp) <-  NULL
temp <- toJSON(temp, pretty = TRUE)

write_lines(temp, path = config$json.for.solr)

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
session <-
  ssh_connect(paste0(config$ssh.user, "@", config$ssh.host))
#' @markampa@turbo-prd-app01.pmacs.upenn.edu")
print(session)

# countdown dips to negative before finishing
# finishes at -31%
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

####

# run the sample Solr queries from teh TMM ontology

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

# prepared.solr.query <- c()

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
      # print(head(current.solr.result))
      failures <- setdiff(current.expected, current.solr.result$id)
      print("failures...")
      print(failures)
      cat("\n\n")
    })
  })
