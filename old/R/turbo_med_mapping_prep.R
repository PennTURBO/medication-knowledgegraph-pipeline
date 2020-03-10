# options(java.parameters = "-Xmx32g")
options(java.parameters = "-Xmx8g")

# document system dependencies like xml, openssl...
library(e1071)
library(solrium)
library(stringdist)
library(reshape)
library(uuid)
library(data.table)
library(tidyr)
library(randomForest)
library(caret)
library(plyr)
library(tidytext)
library(tibble)
library(devtools)
library(httr)
# rrdf requires rJava and is installed from github via devtools
library(rrdf)

###   ###   ###

# prerequistites for this script:
# create a graphdb repo called XXX
# and populate with XXX
#   assumes all dron graphs (except ndc?) and rxnorm are loaded
# this script optionally creates csv files that need to be loaded into a core called XXX
# usign this command: XXX
# then retreive data from the graph and train a random forest with
# "more_hybrid_20181113.R"
# SHOULD REALLY RENAME THAT!

# ?
# might we want to keep direct and parent rxn materializations?
# do we want to include materializations for ChEBI terms modeled in DRON?
# keep the all parent and all direct materialization graphs?

# update.endpoint <-
#   "http://localhost:7200/repositories/epic_mdm_ods_20180918/statements"
#
# sparql.endpoint <-
#   "http://localhost:7200/repositories/epic_mdm_ods_20180918"



# options(java.parameters = "-Xmx16g")
options(java.parameters = "-Xmx8g")
library(rrdf)

dumps_for_solr <- TRUE


update.endpoint <-
  "http://localhost:7200/repositories/med_map_support_20180403/statements"

sparql.endpoint <-
  "http://localhost:7200/repositories/med_map_support_20180403"



###   ###   ###
# end of site-specific settings?
###   ###   ###

# edits
# materialized_direct_dbxr  -> materialized_direct_dron2rxn
# materialized_parents_dbxr -> materialized_parents_dron2rxn
# materialized_dbxr         -> materialized_dron2rxn

###
# these imply downloads from bioportal, but several of the umls aren't downloadadble from there
# so use a consistent umls centric URI for the graph names
# unfortunately doesn't include a version number in the graph name
# either find it in the triples ir assert it (in the graph catalogue?)
# http://data.bioontology.org/ontologies/RXNORM/submissions/15/download -> https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/

# "optionally"
# https://bitbucket.org/uamsdbmi/dron/raw/master/dron-ingredient.owl -> http://purl.obolibrary.org/obo/dron/dron-ingredient.owl
# <http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl>

# rethink syaing that a DRON entry has a materialized relatioship with it's parent's rxnomr code
# that could mess up training, because a med order solr result could be labeled as off by one
# when its really an eact match (semntically)

dron.rxn.materialization.statments <- list(
  clear.materialized_direct_dbxr = "clear graph <http://example.com/resource/materialized_direct_dron2rxn>",
  clear.materialized_parents_dbxr = "clear graph <http://example.com/resource/materialized_parents_dron2rxn>",
  clear.final.materialized_dbxr = "clear graph <http://example.com/resource/materialized_dbxr>",
  clear.combos = "clear graph <http://example.com/resource/combo_check>",
  # ins.direct.materialized.rxn Added 38522 statements. Update took 2.5s, moments ago.
  ins.direct.materialized.rxn = '
  PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
insert {
    graph <http://example.com/resource/materialized_direct_dron2rxn> {
        ?s <http://example.com/resource/materialized_dron2rxn> ?rxn
    }
}
where {
    {
        {
            graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
                ?s  obo:DRON_00010000 ?o .
            }
        }
        union
        {
            graph <http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl> {
                ?s  obo:DRON_00010000 ?o .
            }
        }
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?something <http://purl.bioontology.org/ontology/RXNORM/RXCUI> ?o
    }
    bind(uri(concat("http://purl.bioontology.org/ontology/RXNORM/",?o)) as ?rxn)
}
  ',
combo.likely.true = 'PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX mydata: <http://example.com/resource/>
insert {
    graph mydata:combo_check {
        ?RXNORM_CODE_URI mydata:combination_likely true
    }
}
where {
    select ?RXNORM_CODE_URI
    where {
        graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
            ?RXNORM_CODE_URI a owl:Class .
            optional {
                ?RXNORM_CODE_URI rxnorm:has_ingredient ?ing
            }
            optional {
                ?RXNORM_CODE_URI rxnorm:has_part ?part
            }
            optional {
                ?RXNORM_CODE_URI rxnorm:contains ?component
            }
            optional {
                ?RXNORM_CODE_URI rxnorm:has_ingredients ?ings
            }
            optional {
                ?RXNORM_CODE_URI rxnorm:has_precise_ingredient ?ping
            }
        }
    }
    group by ?RXNORM_CODE_URI
    having (
        (count(distinct ?ing) > 1 )  ||
        (count(distinct ?part)  > 1 )  ||
        (count(distinct ?component)  > 1 )  ||
        (count(distinct ?ings)  > 0 )  ||
        (count(distinct ?ping)  > 1 )
    )
}',
combo.likely.false = '
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
  PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX mydata: <http://example.com/resource/>
  insert {
  graph mydata:combo_check {
  ?RXNORM_CODE_URI mydata:combination_likely false
  }
  }
  where {
  select ?RXNORM_CODE_URI
  where {
  graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
  ?RXNORM_CODE_URI a owl:Class .
  optional {
  ?RXNORM_CODE_URI rxnorm:has_ingredient ?ing
  }
  optional {
  ?RXNORM_CODE_URI rxnorm:has_part ?part
  }
  optional {
  ?RXNORM_CODE_URI rxnorm:contains ?component
  }
  optional {
  ?RXNORM_CODE_URI rxnorm:has_ingredients ?ings
  }
  optional {
  ?RXNORM_CODE_URI rxnorm:has_precise_ingredient ?ping
  }
  }
  }
  group by ?RXNORM_CODE_URI
  having (
  (count(distinct ?ing) < 2  )  &&
  (count(distinct ?part)  < 2 )  &&
  (count(distinct ?component)  < 2 )  &&
  (count(distinct ?ings)  < 1 )   &&
  (count(distinct ?ping)  < 2 )
  )
  }'
,
clear.pds.rxncasts = 'clear graph <http://example.com/resource/pds_rxn_casts>',
recreate.pds.rxncasts = '
# why should the IDs necessarily be numeric?
# no longer considering medications records DIRECTLY from EPIC, only PDS imports from EPIC
PREFIX mydata: <http://example.com/resource/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:pds_rxn_casts {
        ?pdsrecord mydata:RXNORM_CODE_URI ?rxn_record .
    }
}
where {
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?pdsrecord mydata:RXNORM ?RXNORM_CODE .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn_record skos:notation  ?RXNORM_CODE .
    }
}
  '
)

placeholder <-
  lapply(names(dron.rxn.materialization.statments), function(current.update) {
    print(current.update)
    print(Sys.time())
    current.statement <-
      dron.rxn.materialization.statments[[current.update]]
    # cat(current.statement)
    insert.result <-
      POST(update.endpoint, body = list(update = current.statement))
    
    print(insert.result$status_code)
    print(insert.result$times)
    
  })

ephemeral.timed.sparql <- function(sparql.q)
{
  time.start <-  Sys.time()
  print(time.start)
  sparql.res <-
    sparql.remote(endpoint = sparql.endpoint,
                  sparql = sparql.q,
                  jena = TRUE)
  time.stop <-  Sys.time()
  time.duration <- time.stop - time.start
  print(time.duration)
  print(sparql.res)
}

# combo table
ephemeral.timed.sparql(
  '
  PREFIX mydata: <http://example.com/resource/>
  select ?o (count(distinct ?s) as ?count) where {
  ?s mydata:combination_likely ?o .
  }
  group by ?o
  '
)

# multi-rxn maps
ephemeral.timed.sparql(
  '
  select
?s (count(distinct ?dbxr) as ?count)
where {
    ?s <http://example.com/resource/materialized_dron2rxn> ?dbxr
}
group by ?s
order by desc (count(distinct ?dbxr))
limit 20
  '
)

# create document collections for solr:  dron-based, rxnorm-based and other (mostly UMLS + chebi?)
# need to add rxnorm and other scripts
# solr create -c <colelction>
# curl http://localhost:8983/solr/umls_chebi_some_dron_distinct/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
# ./solr-7.5.0/bin/post -c umls_chebi_some_dron_distinct -params "overwrite=false" for_solr_dron_via_r.csv for_solr_rxnorm.csv for_solr_other.csv
# do this all within R?
# check with soemthign like this
# http://18.232.185.180:8983/solr/medmappers_20181109/select?q=anyLabel:(500%20mg%20acetaminophen%20codeine%20oral%20tablet)
# could also include score

if (dumps_for_solr) { 
  for_solr_dron.q <- '
# dron has more rxn mappings than bioportal, and extremely high overlap
# PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX umls: <http://bioportal.bioontology.org/ontologies/umls/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
#PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
#PREFIX obo: <http://purl.obolibrary.org/obo/>
select
(<https://bitbucket.org/uamsdbmi/dron/raw/master/dron-full.owl> as ?ontology) ?term ("DrOn assertion" as ?rxnMatchMeth) ( <http://www.w3.org/2000/01/rdf-schema#label> as ?labelType) (lcase(str(?preal)) as ?labelContent) ?rxn (group_concat(distinct ?indirecttui) as ?gctui) ?combo_likely
where {
    values ?graph {
#        <http://purl.obolibrary.org/obo/dron/dron-pro.owl>
        <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl>
        <http://purl.obolibrary.org/obo/dron/dron-chebi.owl>
        <http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl>
        <http://purl.obolibrary.org/obo/dron/dron-hand.owl>
    }
    graph ?graph {
        ?term a owl:Class ;
              <http://www.w3.org/2000/01/rdf-schema#label>  ?preal .
        minus {
            ?term <http://www.w3.org/2000/01/rdf-schema#subClassOf>* <http://purl.obolibrary.org/obo/BFO_0000016>
        }
        optional {
            graph <http://example.com/resource/materialized_direct_dron2rxn> {
                ?term  mydata:materialized_dron2rxn ?rxn .
            }
            graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
                ?rxn a owl:Class .
                optional {
                    ?rxn umls:tui ?indirecttui
                }
            }
            optional {
                graph mydata:combo_check {
                    ?rxn mydata:combination_likely ?combo_likely .
                }
            }
        }
    }
}
group by ?term ?preal ?rxn ?combo_likely
'

time.start <-  Sys.time()
print(time.start)
for_solr_dron.res <-
  sparql.remote(endpoint = sparql.endpoint,
                sparql = for_solr_dron.q,
                jena = TRUE)
time.stop <-  Sys.time()
time.duration <- time.stop - time.start
print(time.duration)
dim(for_solr_dron.res)
for_solr_dron.res <- as.data.frame(for_solr_dron.res)

table(for_solr_dron.res$ontology, useNA = 'always')
table(for_solr_dron.res$rxnMatchMeth, useNA = 'always')
table(for_solr_dron.res$labelType, useNA = 'always')
table(for_solr_dron.res$gctui, useNA = 'always')
table(for_solr_dron.res$combo_likely, useNA = 'always')

# expand match type and rxn uris

# for_solr_dron.res$rxn <- sub(pattern = "^rxnorm:",
#                              replacement = "http://purl.bioontology.org/ontology/RXNORM/",
#                              x = for_solr_dron.res$rxn)
# 
# for_solr_dron.res$labelType <-
#   "http://www.w3.org/2000/01/rdf-schema#label"

###   ###   ###

# write.csv(for_solr_dron.res, file = "for_solr_dron_20181109.csv", row.names = FALSE)

###   ###   ###

for_solr_rxnorm.q <- '
PREFIX owl: <http://www.w3.org/2002/07/owl#>
#PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX umls: <http://bioportal.bioontology.org/ontologies/umls/>
PREFIX mydata: <http://example.com/resource/>
select
?ontology ?term ?rxnMatchMeth ?labelType
(lcase(str(?preal)) as ?labelContent)
?rxn
(group_concat(distinct ?directtui) as ?gctui)
?combo_likely
where {
    values ?labelType {
        <http://www.w3.org/2004/02/skos/core#prefLabel> <http://www.w3.org/2004/02/skos/core#altLabel>
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?term a owl:Class ;
              ?labelType ?preal ;
              <http://purl.bioontology.org/ontology/RXNORM/RXCUI> ?rxcui .
        optional {
            ?term umls:tui ?directtui
        }
    }
    optional {
        graph mydata:combo_check {
            ?term mydata:combination_likely ?combo_likely
        }
    }
    bind(uri("https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM") as ?ontology)
    bind("RxNorm direct" as ?rxnMatchMeth)
    # for the dron and UMLS other solr-populating queries, ?term and ?rxn are different.
    bind(?term as ?rxn)
}
group by ?ontology ?term ?rxnMatchMeth ?labelType  ?preal ?rxn ?combo_likely
'

print(Sys.time())
time.duration <- system.time(
  for_solr_rxnorm.res <-
    sparql.remote(
      endpoint = sparql.endpoint,
      sparql = for_solr_rxnorm.q,
      jena = TRUE
    )
)
print(time.duration)
dim(for_solr_rxnorm.res)
for_solr_rxnorm.res <- as.data.frame(for_solr_rxnorm.res)


table(for_solr_rxnorm.res$ontology, useNA = 'always')
table(for_solr_rxnorm.res$rxnMatchMeth, useNA = 'always')
table(for_solr_rxnorm.res$labelType, useNA = 'always')
table(for_solr_rxnorm.res$gctui, useNA = 'always')
table(for_solr_rxnorm.res$combo_likely, useNA = 'always')


# for_solr_rxnorm.res$labelType <- sub(pattern = "^skos:",
#                                      replacement = "http://www.w3.org/2004/02/skos/core#",
#                                      x = for_solr_rxnorm.res$labelType)


###   ###   ###

# write.csv(for_solr_rxnorm.res, file = "for_solr_rxnorm_20181109.csv", row.names = FALSE)

###   ###   ###

for_solr_chebi.q <- '
#PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX umls: <http://bioportal.bioontology.org/ontologies/umls/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX mydata: <http://example.com/resource/>
#PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
?ontology ?term
(group_concat(distinct ?preRxnMatchMeth;separator="; " ) as ?rxnMatchMeth)
?labelType (lcase(str(?preal)) as ?labelContent) ?rxn
(concat(group_concat(distinct ?directtui), " ", group_concat(distinct ?indirecttui)) as ?gctui)
?combo_likely
where {
    bind(<ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz> as ?ontology)
    bind(<http://www.w3.org/2000/01/rdf-schema#label> as ?labelType)
    graph <ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz> {
    # subCLass of http://purl.obolibrary.org/obo/CHEBI_24431... apply same kind of constarint to other ontologies?
    # would probably be harder
        ?term a owl:Class ;
               ?labelType ?preal .
    }
    optional {
        graph <http://bioportal.bioontology.org/mappings> {
            ?mapping rdf:type mydata:Row	;
                     mydata:mapTerm ?term ;
                     mydata:sourceTerm ?rxn ;
                     mydata:sourceOnt <http://data.bioontology.org/ontologies/RXNORM> ;
                     mydata:mapMeth ?preRxnMatchMeth .
        }
        optional {
            graph mydata:combo_check {
                ?rxn mydata:combination_likely ?combo_likely .
            }
        }
        optional {
            graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
                ?rxn umls:tui ?indirecttui
            }
        }
    }
}
group by ?ontology ?term ?labelType ?preal ?rxn ?combo_likely
'

print(Sys.time())
time.duration <- system.time(
  for_solr_chebi.res <-
    sparql.remote(
      endpoint = sparql.endpoint,
      sparql = for_solr_chebi.q,
      jena = TRUE
    )
)
print(time.duration)
dim(for_solr_chebi.res)

for_solr_chebi.res <- as.data.frame(for_solr_chebi.res)


table(for_solr_chebi.res$ontology, useNA = 'always')
table(for_solr_chebi.res$rxnMatchMeth, useNA = 'always')
table(for_solr_chebi.res$labelType, useNA = 'always')
table(for_solr_chebi.res$gctui, useNA = 'always')
table(for_solr_chebi.res$combo_likely, useNA = 'always')



# for_solr_dron.res$labelType <-
#   "http://www.w3.org/2000/01/rdf-schema#label"

###   ###   ###

# write.csv(for_solr_chebi.res, file = "for_solr_chebi_20181109.csv", row.names = FALSE)

###   ###   ###

# ~ 15 minutes... better run manually in GraphDB web browser then dumped to file

for_solr_other.q <- '
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
#PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
#PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX umls: <http://bioportal.bioontology.org/ontologies/umls/>
select
?ontology ?term
(group_concat(distinct ?preRxnMatchMeth ;separator="; " ) as ?rxnMatchMeth)
?labelType (lcase(str(?preal)) as ?labelContent) ?rxn
(concat(group_concat(distinct ?directtui), " ", group_concat(distinct ?indirecttui)) as ?gctui)
?combo_likely
where {
    values ?ontology {
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/ATC/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/CVX/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/DRUGBANK/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/GS/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MDDB/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MED-RT/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMSL/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMX/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MTH/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_FDA/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_NCPDP/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDFRT/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/SPN/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/UMD/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USP/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USPMG/>
        <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/VANDF/>
                <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/SNOMED/>
    }
    values ?labelType {
        <http://www.w3.org/2000/01/rdf-schema#label>
        <http://www.w3.org/2004/02/skos/core#prefLabel>
        <http://www.w3.org/2004/02/skos/core#altLabel>
    }
    graph ?ontology {
        ?term a owl:Class ;
              ?labelType ?preal ;
              umls:cui ?cui .
        optional {
            ?term umls:tui ?directtui
        }
    }
    minus {
        graph <https://www.nlm.nih.gov/research/umls/META3_current_semantic_types.html> {
            ?term  a owl:Class
        }
    }
    optional {
        {
            {
                graph <http://bioportal.bioontology.org/mappings> {
                    ?mapping rdf:type mydata:Row	;
                             mydata:mapTerm ?term ;
                             mydata:sourceTerm ?rxn ;
                             mydata:sourceOnt <http://data.bioontology.org/ontologies/RXNORM> ;
                             mydata:mapMeth ?preRxnMatchMeth .
                }
            }
            union {
                graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
                    ?rxn umls:cui ?cui .
                    bind("non-BP-CUI" as ?preRxnMatchMeth)
                }
            }
        }
        optional {
            graph mydata:combo_check {
                ?rxn mydata:combination_likely ?combo_likely .
            }
        }
        optional {
            graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
                ?rxn umls:tui ?indirecttui
            }
        }
    }
}
group by ?ontology ?term ?labelType ?preal ?rxn ?combo_likely
'


print(Sys.time())
time.duration <- system.time(
  for_solr_other.res <-
    sparql.remote(
      endpoint = sparql.endpoint,
      sparql = for_solr_other.q,
      jena = TRUE
    )
)
print(time.duration)
dim(for_solr_other.res)
for_solr_other.res <- as.data.frame(for_solr_other.res)


table(for_solr_other.res$ontology, useNA = 'always')
table(for_solr_other.res$rxnMatchMeth, useNA = 'always')
table(for_solr_other.res$labelType, useNA = 'always')
table(for_solr_other.res$gctui, useNA = 'always')
table(for_solr_other.res$combo_likely, useNA = 'always')



# write.csv(for_solr_other.res, file = "for_solr_other_allcols_20181113.csv", row.names = FALSE)

actually.chebi <-
  grepl(pattern = "CHEBI", x = for_solr_dron.res$term)
dron2rxn.success <- !is.na(for_solr_dron.res$rxn)
chebi2rxn.via.dron <-
  unique(for_solr_dron.res[actually.chebi &
                             dron2rxn.success , c("term", "labelContent", "rxn")])

chebi2rxn.via.bp <-
  unique(for_solr_chebi.res[!is.na(for_solr_chebi.res$rxn) , c("term", "labelContent", "rxn")])

chebi2rxn.via.bp[] <- lapply(chebi2rxn.via.bp[], as.character)
chebi2rxn.via.dron[] <- lapply(chebi2rxn.via.dron[], as.character)

fun.12 <- function(x.1, x.2, ...) {
  x.1p <- do.call("paste", x.1)
  x.2p <- do.call("paste", x.2)
  x.1[!x.1p %in% x.2p, ]
}

dron.contribution <- fun.12(chebi2rxn.via.dron, chebi2rxn.via.bp)
dron.contribution <-
  merge(
    x = dron.contribution,
    y = for_solr_dron.res,
    by.x = c("term", "labelContent", "rxn"),
    by.y = c("term", "labelContent", "rxn")
  )

for_solr_dron.res.pure <- for_solr_dron.res[!actually.chebi, ]

for_solr_chebi.res.aggregated <-
  rbind.data.frame(for_solr_chebi.res, dron.contribution)

for_solr <-
  unique(
    rbind.data.frame(
      for_solr_dron.res.pure,
      for_solr_chebi.res.aggregated,
      for_solr_other.res,
      for_solr_rxnorm.res
    )
  )

gctui.cleanup <- strsplit(as.character(for_solr$gctui), " ")
gctui.cleanup <- lapply(gctui.cleanup, function(current.tui) {
  return(gsub(
    pattern = " +",
    replacement = "",
    x = current.tui
  ))
})
# innefficient
gctui.cleanup <- lapply(gctui.cleanup, function(current.tui) {
  temp <- paste(unique(sort(current.tui)), collapse =  " ")
})

table(for_solr$rxnMatchMeth)

method.cleanup <- strsplit(as.character(for_solr$rxnMatchMeth), "; ")
method.cleanup <- lapply(method.cleanup, function(current.list) {
  temp <- sub(pattern = "^ +",
              replacement = "",
              x = current.list)
  temp <- sub(pattern = " +$",
              replacement = "",
              x = current.list)
  temp <- gsub(pattern = " +",
               replacement = " ",
               x = current.list)
})
# innefficient
method.cleanup <- lapply(method.cleanup, function(current.list) {
  temp <- paste(unique(sort(current.list)), collapse =  "; ")
})

for_solr$gctui <- unlist(gctui.cleanup)
for_solr$rxnMatchMeth <- unlist(method.cleanup)


table(for_solr_other.res$ontology, useNA = 'always')
table(for_solr_other.res$rxnMatchMeth, useNA = 'always')
table(for_solr_other.res$labelType, useNA = 'always')
table(for_solr_other.res$gctui, useNA = 'always')
table(for_solr_other.res$combo_likely, useNA = 'always')




sort(table(for_solr$gctui))
table(for_solr$rxnMatchMeth)

write.csv(for_solr,file = "for_solr_20180408_guaranteed_full_q_uris.csv", row.names = FALSE)


}

