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

options(error = function()traceback(2))

# Java memory is set in turbo_R_setup.R
print(getOption("java.parameters"))

####

# load public ontologies & RDF data sets
# more refactoring (even package writing) opportunities

# upload from file if upload from URL might fail

# the name of the destination graph is part of the "endpoint URL"

####    ####    ####    ####

# probably don't really need dron_chebi or dron_pro?

last.post.status <-
  'Multiple OBO and BioPortal/UMLS uploads from URLs '

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

# need to wait for imports to finish
# file uploads may be synchronous blockers

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
    
    print("POST(URL):") #TH5
    print(update.endpoint)

#https://rdrr.io/cran/httr/man/verbose.html
#   post.res <- POST(update.endpoint,
    post.res <- tryCatch({
                    POST(update.endpoint,
                        body = list(update = innner.sparql),
                        saved.authentication,
                        timeout(1300),
                        verbose(data_out=TRUE, data_in=TRUE, info=TRUE, ssl=TRUE),
                        config(tcp_keepalive=1) #useless?
                    )
                }, error = function(e){
                             print("Caught error, sleeping for 10 minutes")
                             Sys.sleep(600) #seconds
                           }
                )
    print(post.res)
  }
)

####    ####    ####    ####

# RxNorm TTY types, asserted as employment

tryCatch({
  dbDisconnect(rxnCon)
},
warning = function(w) {
  
}, error = function(e) {
  print(e)
})

rxnCon <- NULL

connected.test.query <-
  "select RSAB from rxnorm_current.RXNSAB r"

# todo paramterize connection and query string
test.and.refresh <- function() {
  tryCatch({
    dbGetQuery(rxnCon, connected.test.query)
  }, warning = function(w) {
    
  }, error = function(e) {
    print(e)
    print("trying to reconnect")
    rxnCon <<- dbConnect(
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
    dbGetQuery(rxnCon, connected.test.query)
  }, finally = {
    
  })
}

test.and.refresh()


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

# # Close connection ?
# dbDisconnect(rxnCon)

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
# DF dose form like oral capsule
# DFG dose form group like oral product ?
# ET entry term
# PSN prfered  source name?
# SY synonym
# TMSY tallMAN synonym

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
rdf_serialize(rdf = as.rdf,
              doc = config$rxcui_ttys.fp,
              format = 'turtle')

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp>'),
  saved.authentication
)

placeholder <-
  import.from.local.file('http://example.com/resource/rxn_tty_temp',
                         config$rxcui_ttys.fp,
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

####    ####    ####    ####

if (config$clear.raw.class.search.res) {
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

# we should include the schema.xml in the repo

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

####    ####    ####    ####

# many of the next steps take several minutes each

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
  crsc.solr.res[crsc.solr.res$id %in% crsc.addtions,]

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

write_lines(temp, file = paste0(config$json.source, "/", config$json.for.solr))

####

# med_mapping_kb_labels_exp , /project/turbo_graphdb_staging

# curl 'http://localhost:8983/solr/med_mapping_kb_labels/update?commit=true&overwrite=false' \
# --data-binary  @medlabels_for_chebi_for_solr.json  -H 'Content-type:application/json'

# now run rxnav_med_mapping_solr_upload_post.R
