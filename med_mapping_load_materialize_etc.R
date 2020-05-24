source("rxnav_med_mapping_setup.R")

# load public ontologies & RDF data sets
# inspired by disease_diagnosis_dev.R
# more refactoring (even package writing) opportunities

####    ####    ####    ####

### upload from file if upload from URL might fail
# the name of the destination graph is part of the "endpoint URL"

####    ####    ####    ####

# probably don't really need dron_chebi or dron_pro?

import.urls <- config$my.import.urls
import.names <- names(import.urls)
context.report <- get.context.report()
import.names <- setdiff(import.names, context.report)

placeholder <-
  lapply(import.names, function(some.graph.name) {
    some.ontology.url <- import.urls[[some.graph.name]]$url
    some.rdf.format <- import.urls[[some.graph.name]]$format
    import.from.url(some.graph.name,
                    some.ontology.url,
                    some.rdf.format)
  })

import.files <- config$my.import.files
import.names <- names(import.files)
context.report <- get.context.report()
import.names <- setdiff(import.names, context.report)

placeholder <-
  lapply(import.names, function(some.graph.name) {
    # some.graph.name <- import.names[[1]]
    some.ontology.file <- import.files[[some.graph.name]]$local.file
    some.rdf.format <- import.files[[some.graph.name]]$format
    import.from.local.file(some.graph.name,
                           some.ontology.file,
                           some.rdf.format)
  })

# "/Users/markampa/cleanroom/med_mapping/classified_search_results_from_robot.ttl.zip"
# "/Users/markampa/cleanroom/med_mapping/classified_search_results_from_robot.ttl"
# "/Users/markampa/cleanroom/med_mapping/reference_medications_from_robot.ttl

# import.from.local.file(
#   some.graph.name = "http://example.com/resource/classified_search_results",
#   some.local.file = "/Users/markampa/cleanroom/med_mapping/classified_search_results_from_robot.ttl",
#   some.rdf.format = "text/turtle"
# )

# need to wait for imports to finish
# file uploads may be synchronous blockers

last.post.status <-
  'Multiple OBO and BioPortal/UMLS uploads from URLs '
last.post.time <- Sys.time()

expectation <- import.names

monitor.named.graphs()

####    ####    ####    ####

sparql.list <-
  config$materializastion.projection.sparqls

placeholder <-
  lapply(names(sparql.list), function(current.sparql.name) {
    print(current.sparql.name)
    innner.sparql <- sparql.list[[current.sparql.name]]
    cat(innner.sparql)
    cat('\n\n')
    
    post.res <- POST(update.endpoint,
                     body = list(update = innner.sparql),
                     saved.authentication)
  })

####    ####    ####    ####

# RxNorm TTY types, asserted as employment

# i keep re-doing this thorugh other scripts
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


my.query <- "
SELECT
RXCUI, TTY
from
rxnorm_current.RXNCONSO r
where
SAB = 'RXNORM'"

print(Sys.time())
timed.system <- system.time(rxcui_ttys <-
                              dbGetQuery(rxnCon, my.query))
print(Sys.time())
print(timed.system)

# Close connection
dbDisconnect(rxnCon)

rxcui_ttys$placeholder <- 1

rxcui.tab <- table(rxcui_ttys$RXCUI)
rxcui.tab <-
  cbind.data.frame(names(rxcui.tab), as.numeric(rxcui.tab))
names(rxcui.tab) <- c("RXCUI", "TTY.entries")

tty.tab <- table(rxcui_ttys$TTY)
tty.tab <-
  cbind.data.frame(names(tty.tab), as.numeric(tty.tab))
names(tty.tab) <- c("TTY", "RXCUI.entries")

# skip
# DF
# DFG
# ET
# PSN
# SY
# TMSY

one.per <-
  rxcui_ttys[rxcui_ttys$TTY %in% c(
    'BN',
    'BPCK',
    'GPCK',
    'IN',
    'MIN',
    'PIN',
    'SBD',
    'SBDC',
    'SBDF',
    'SBDG',
    'SCD',
    'SCDC',
    'SCDF',
    'SCDG'
  ), c('RXCUI', 'TTY')]

one.per.tab <- table(one.per$RXCUI)
one.per.tab <-
  cbind.data.frame(names(one.per.tab), as.numeric(one.per.tab))
names(one.per.tab) <- c("RXCUI", "TTY.entries")

print(table(one.per.tab$TTY.entries))

one.per$RXCUI <-
  paste0('http://purl.bioontology.org/ontology/RXNORM/',
         one.per$RXCUI)

one.per$TTY <-
  paste0('http://example.com/resource/rxn_tty/', one.per$TTY)

as.rdf <- as_rdf(x = one.per)

# todo parmaterize this hardcoding
rdf_serialize(rdf = as.rdf, doc = 'rxcui_ttys.ttl', format = 'turtle')


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp>'),
  saved.authentication
)

placeholder <-
  import.from.local.file('http://example.com/resource/rxn_tty_temp',
                         'rxcui_ttys.ttl',
                         'text/turtle')

# move the statement to the config file
rxn.tty.update <- 'PREFIX mydata: <http://example.com/resource/>
insert {
graph mydata:employment {
?ruri mydata:employment ?turi .
}
}
where {
graph <http://example.com/resource/rxn_tty_temp> {
?s <df:RXCUI> ?r ;
<df:TTY> ?t .
bind(iri(?r) as ?ruri)
bind(iri(?t) as ?turi)
}
}'

# Added 203754 statements. Update took 16s, moments ago.

post.res <- POST(update.endpoint,
                 body = list(update = rxn.tty.update),
                 saved.authentication)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp>'),
  saved.authentication
)

if (FALSE) {
  # this should probably be optional... it is verbose,
  #   and the http://example.com/resource/elected_mapping replacement
  #   is proabbply more useful in most circumstances
  #   but it takes a long time to reload
  post.res <- POST(
    update.endpoint,
    body = list(update = 'clear graph <http://example.com/resource/classified_search_results>'),
    saved.authentication
  )
}

####    ####    ####    ####

# Solr prerequisites
# $ ~/solr-8.4.1/bin/solr start
# *** [WARN] *** Your open file limit is currently 2560.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# *** [WARN] ***  Your Max Processes Limit is currently 5568.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# Waiting up to 180 seconds to see Solr running on port 8983 [-]
# Started Solr server on port 8983 (pid=33449). Happy searching!
#
# $ ~/solr-8.4.1/bin/solr create_core -c <config$med.map.kb.solr.host>

# many of the next steps take several minutes each

####    ####    ####    ####

# < 1 minute
system.time(main.solr.res <- q2j2df(query = config$main.solr.query))

main.solr.res <-
  main.solr.res[, c("mediri", "medlabel", "definedin", "labelpred",  "employment")]

colnames(main.solr.res) <-
  c("id", "medlabel", "definedin", "labelpred", "employment")

# main.solr.res$id <- main.solr.res$mediri

# names(main.solr.res) <- c("id", "medlabel", "definedin", "labelpred",  "employment")

# MAKE A MAIN LIST
main.solr.list <- do.call(function(...)
  Map(list, ...), main.solr.res)

####

# all alternative labels for SELECTED rxnorm employees

system.time(rxn.alt.lab.solr.res <-
              q2j2df(query = config$rxn.alt.lab.solr.query))

colnames(rxn.alt.lab.solr.res) <- c("medlabel",  "id")

unique.medids <- unique(rxn.alt.lab.solr.res$id)

# make free standing alternative label list
# just a few seconds
# refactor
# MAKE A RXN PREFLAB LIST
system.time(rxn.alt.lab.solr.list <-
              lapply(unique.medids, function(current.medid) {
                temp <-
                  unique(rxn.alt.lab.solr.res$medlabel[rxn.alt.lab.solr.res$id == current.medid])
                # print(temp)
                return(list(id = current.medid,
                            altlabels = temp))
              }))

names(rxn.alt.lab.solr.list) <- unique.medids

# # i stopped retreiving labels and synonyms/altlabels for rxnorm products for now
# # print(unlist(rxn.alt.lab.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']]))
# print(rxn.alt.lab.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']])

# ####

# don't really need to keep ?l (rdfs:label) or length
# may want to filter on length... 2-40?
# take a look at str distance between ?l and alt label value

# is there some way to exclude foreign spellings?

# have already filtered for ?l != ?synval

# also removed IUPAC synonym types
# so there won't be any exact synonyms, only related?
# should probably still filter on sources

system.time(chebi.synonym.res <-
              q2j2df(query = config$chebi.synonym.query))

chebi.synonym.res$synstrength <-
  sub(
    pattern = 'http://www.geneontology.org/formats/oboInOwl#',
    replacement = '',
    x = chebi.synonym.res$synstrength,
    fixed = TRUE
  )

colnames(chebi.synonym.res) <-
  c("synval",
    "synstrength",
    "synlen",
    "syntype",
    "id",
    "synsource",
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

# hist(log10(as.numeric(chebi.synonym.res$synlen)), breaks = 99)
## maybe they're all related synonyms since IUPAC terms have been removed?
# table(chebi.synonym.res$synstrength)
# table(chebi.synonym.res$syntype, useNA = 'always')
## length distribution by synstrength, syntype, or synsource categorical ?

# # so far
# http://turbo-prd-app01.pmacs.upenn.edu:8983/solr/listtest/select?q=*:*&wt=csv&rows=0&facet
# labelpred,mediri,employment,medlabel,definedin,id,altlabels
# medlabel,altlabels
# http://turbo-prd-app01.pmacs.upenn.edu:8983/solr/listtest/select?q=medlabel:(acetaminophen%20codeine)
# http://turbo-prd-app01.pmacs.upenn.edu:8983/solr/listtest/select?q=altlabels:(apap%20tramadol)
# try edismax or allText?

# for brand names
# synstrength === hasRelatedSynonym
# syntype === BRAND_NAME
# synsource and synval come in pairs,
#   but we could ignore source for now

# cs.bn <-
#   unique(chebi.synonym.res[!(is.na(chebi.synonym.res$syntype)) &
#                              chebi.synonym.res$syntype == 'BRAND_NAME' , c("mediri", "synval")])

chebi.selected.syns <-
  unique(chebi.synonym.res[(!(is.na(chebi.synonym.res$syntype)) &
                              chebi.synonym.res$syntype == 'BRAND_NAME') |
                             chebi.synonym.res$synsource %in% c('KEGG_COMPOUND', 'KEGG_DRUG', 'DrugBank', 'UniProt') , c("id", "synval")])

## just skip these for now
# cs.inn <-
#   chebi.synonym.res[!(is.na(chebi.synonym.res$syntype)) &
#                       chebi.synonym.res$syntype == 'INN' ,]
# cs.other <- chebi.synonym.res[is.na(chebi.synonym.res$syntype), ]

# # refactor
# unique.mediris <- unique(cs.bn$mediri)
# system.time(cs.bn.list <-
#               lapply(unique.mediris, function(current.mediri) {
#                 temp <-
#                   unique(cs.bn$synval[cs.bn$mediri == current.mediri])
#                 return(list(mediri = current.mediri,
#                             brandnames = temp))
#               }))
#
# names(cs.bn.list) <- unique.mediris


# refactor
# MAKE A CHEBI SYN LIST
unique.medids <- unique(chebi.selected.syns$id)
system.time(chebi.selected.syns.list <-
              lapply(unique.medids, function(current.medid) {
                temp <-
                  unique(chebi.selected.syns$synval[chebi.selected.syns$id == current.medid])
                return(list(id = current.medid,
                            chebisyns = temp))
              }))

names(chebi.selected.syns.list) <- unique.medids

####

# print(rxn.alt.lab.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']])
# print(main.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']])

####

# library(rlist)

# may not like the fact that the outer list names are back-ticked URLs?
# doesn't seem very fast anyway
# i.e. takes a long time to deliver an error message
#
# print(Sys.time())
# system.time(joined.lists <-
#   list.join(main.solr.list, rxn.alt.lab.solr.list, mediri))

####

# get and make a dron lab list

# OR COULD DO A UNIQUE TERMS FIELD (INCLUDING MEDLABEL) AND A UNIQUE TOKENS FIELD


system.time(
  dron.additional.chebi.labels <-
    q2j2df(query = config$dron.additional.chebi.label.query)
)
colnames(dron.additional.chebi.labels) <-
  c('id', 'dron.for.chebi', 'dtich')
dron.additional.chebi.labels <-
  dron.additional.chebi.labels[, c('id', 'dron.for.chebi')]

dron.solr.list <- do.call(function(...)
  Map(list, ...), dron.additional.chebi.labels)

chebi.ids <- names(chebi.selected.syns.list)
dron.ids <- names(dron.solr.list)
rxn.ids <- names(rxn.alt.lab.solr.list)

needs.attention <- sort(unique(c(chebi.ids, dron.ids, rxn.ids)))

system.time(lapply(needs.attention, function(current.id) {
  medlablel <- tolower(main.solr.list[[current.id]][['medlabel']])
  chebi.vals <-
    sort(unique(tolower(unlist(
      chebi.selected.syns.list[[current.id]][["chebisyns"]]
    ))))
  dron.vals <-
    sort(unique(tolower(unlist(dron.solr.list[[current.id]][["dron.for.chebi"]]))))
  rxn.vals <-
    sort(unique(tolower(unlist(
      rxn.alt.lab.solr.list[[current.id]][["altlabels"]]
    ))))
  # print(medlablel)
  # print(chebi.vals)
  # print(dron.vals)
  # print(rxn.vals)
  
  # main.solr.list[[current.iri]]$altlabels <<-
  #   rxn.alt.lab.solr.list[[current.iri]]$altlabels
  propigate <-
    unlist(sort(setdiff(
      c(chebi.vals, dron.vals, rxn.vals), medlablel
    )))
  # return(propigate)
  
  main.solr.list[[current.id]]$extras <<- propigate
}))

main.solr.list[["http://purl.bioontology.org/ontology/RXNORM/5933"]]

# chebi.selected.syns.list[[1]]
# "http://purl.obolibrary.org/obo/CHEBI_10100"
# # chebisyns
# 
# dron.solr.list[[1]]
# "http://purl.obolibrary.org/obo/CHEBI_15407"
# # dron.for.chebi
# 
# rxn.alt.lab.solr.list[[1]]
# "http://purl.bioontology.org/ontology/RXNORM/5933"
# # altlabels

# gather the ids of anything that has a dron label, chebi syn or rxn altlabel
# loop over the main list
# make a unique list of the lowercase extra terms
# subtract the lowercased medlabe
# assert the rest as extras

# # 300 seconds
# unique.mediris <- names(rxn.alt.lab.solr.list)
# print(Sys.time())
# system.time(lapply(unique.mediris, function(current.iri) {
#   main.solr.list[[current.iri]]$altlabels <<-
#     rxn.alt.lab.solr.list[[current.iri]]$altlabels
# }))
# 
# print(main.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']])
# 
# # # almost instantaneous
# # unique.mediris <- names(cs.bn.list)
# # print(Sys.time())
# # system.time(lapply(unique.mediris, function(current.iri) {
# #   main.solr.list[[current.iri]]$brandnames <<-
# #     cs.bn.list[[current.iri]]$brandnames
# # }))
# 
# 
# # almost instantaneous
# unique.mediris <- names(chebi.selected.syns.list)
# print(Sys.time())
# system.time(lapply(unique.mediris, function(current.iri) {
#   main.solr.list[[current.iri]]$chebisyns <<-
#     chebi.selected.syns.list[[current.iri]]$chebisyns
# }))
# 
# print(main.solr.list[['http://purl.obolibrary.org/obo/CHEBI_3611']])

####

# take out the hardcoded settings, put them in the config file
# remove the Solr-related code above (connections and posts)

mm.kb.solr.client <-
  SolrClient$new(
    host = config$med.map.kb.solr.host,
    path = "search",
    port = config$med.map.kb.solr.port
  )

# could also ping it
print(mm.kb.solr.client)

# clear the core!
mm.kb.solr.client$delete_by_query(name = config$med.map.kb.solr.core, query = "*:*")

####    ####    ####    ####

print(length(main.solr.list))

main.solr.list <- list.sort(main.solr.list, "medlabel")
list.order(main.solr.list, "medlabel")

# ~ 1.5 hours
print(Sys.time())
system.time(lapply(main.solr.list, function(current.doc) {
  print(current.doc)
  if (nchar(current.doc$id) > 0) {
    mm.kb.solr.client$add(current.doc, config$med.map.kb.solr.core, commit = FALSE)
  }
  return()
}))
system.time(mm.kb.solr.client$commit(config$med.map.kb.solr.core))
print(Sys.time())

# coalesce the lower-cased, uniqfied(ChEBI synonyms (no longer sourced or types) and the RxNorm alternative terms?)
# eliminate allText if we use edismax, or down boost A LOT
# add unique DrOn labels back in?


# print(unlist(rxn.alt.lab.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']]))
#
#
# print(main.solr.list[['http://purl.bioontology.org/ontology/RXNORM/836397']])
# print(main.solr.list[['http://purl.obolibrary.org/obo/CHEBI_3611']])
