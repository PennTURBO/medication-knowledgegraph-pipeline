source("rxnav_med_mapping_setup.R")

# my.query <- "
# SELECT
# TTY,
# count(RXCUI)
# from
# rxnorm_current.RXNCONSO r
# where
# SAB = 'RXNORM'
# GROUP by TTY"

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

write.csv(x = tty.tab,
          file = 'rxn_tty_table.csv',
          row.names = FALSE)

# BN
# BPCK
# GPCK
# IN
# MIN
# PIN
# SBD
# SBDC
# SBDF
# SBDG
# SCD
# SCDC
# SCDF
# SCDG


# DF
# DFG
# ET
# PSN
# SY
# TMSY

# SAB = 'RXNORM' and RXCUI  = '1119573'

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

# http://purl.bioontology.org/ontology/RXNORM/
# http://example.com/resource/
# http://www.w3.org/1999/02/22-rdf-syntax-ns#type

one.per$RXCUI <-
  paste0('http://purl.bioontology.org/ontology/RXNORM/',
         one.per$RXCUI)

one.per$TTY <-
  paste0('http://example.com/resource/rxn_tty/', one.per$TTY)

as.rdf <- as_rdf(x = one.per)
rdf_serialize(rdf = as.rdf, doc = 'rxcui_ttys.ttl', format = 'turtle')


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp/>'),
  saved.authentication
)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty/>'),
  saved.authentication
)


placeholder <-
  import.from.local.file('http://example.com/resource/rxn_tty_temp/',
                         'rxcui_ttys.ttl',
                         'text/turtle')

rxn.tty.update <- 'insert {
graph <http://example.com/resource/rxn_tty/> {
?ruri a ?turi .
}
}
where {
graph <http://example.com/resource/rxn_tty_temp/> {
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
  body = list(update = 'clear graph <http://example.com/resource/rxn_tty_temp/>'),
  saved.authentication
)

post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/classified_search_results>'),
  saved.authentication
)


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/materialized_rxcui>'),
  saved.authentication
)


post.res <- POST(
  update.endpoint,
  body = list(update = 'clear graph <http://example.com/resource/cui>'),
  saved.authentication
)
