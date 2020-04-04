# Things we could still do with the medication knowledge graph



- [ ] Make images of visual graphs corresponding to user stories
- [x] check defined in/is an ontology relationships
  - [x] also get versions
  - [ ] **now reconcile**
- [ ] confirm PDS R_MEDICATION PKs being used as stable PKs
- [ ] add the PKs as properties of the source medications? (As opposed to just being the RHS of the IRIs)
- [ ] make a sample, non-PDS input file
- [ ] try BioPortal ontology submission API method
  - [ ] http://data.bioontology.org/documentation#OntologySubmission
- [ ] clean up file and variable names
- [ ] see if there’s anything worth keeping in the `extras` and `old` GitHub subdirectories
- [ ] purge other old files, semantic repos, Solr cores...
- [ ] plan for adding knowledge, e.g. from lung cancer effort
  - [ ] added knowledge destinations: 
    - [ ] custom BioPortal mappings (esp. for LOINC bld->blood in clinical labs)
    - [ ] Custom Solr documents
    - [ ] assertions (esp. dispositions) in DrOn
    - [ ] Assertions in TURBO ontology
- [x] Check DrOn for inactive RxCUIs
- [x] Check DrOn for ChEBI mappings exposed by BioPortal
  - [x] how many ingredients overall?
  - [ ] **examine DrOn native ingredient that don't have mappings**
- [ ] Add source medications to Solr?
- [ ] **Keep yaml template up to date**
- [ ] **remove minimal templating ontology invocation from ROBOT shell script** and confirm it still works!
- [ ] use TURBO or OBO predicates for source/reference medications and classified search results, not `mydata:`
- [x] create direct relationship between source medication and RxCUI
- [ ] run classification again with lower min (EMPI) count... 20? 10?

  - [ ] still haven't taken any action about the apparent ceiling on the number of approximate match API calls from R script to RxNav in a box.

  - [ ] would be nice to use R rdflib's as rdf function. see stack overflow issue.
- [x] **add RxNorm types to RxCUIs (from RxNav MySQL?)**
- [ ] normalize mydata:bioportal_mappings graph with mydata:bioportal_mapping predicate
- [x] more aggressive consensus building when multiple classified search results could be reasonably associated with a source medication. **See below**
  
  - [ ] maybe the direct relationships will make this moot
  - [ ] take a vote?
  - [ ] weight scores by classified semantic distance and sum?
  - [ ] lowest common subsumer?



## Consensus by sum of identical scores

### How many search results are available for each source medication

Remember, some filtering has already been applied in the R script.

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#* 
# this should already have been depleted of RxCUIs that RxNav suggested
# but which aren't defined in the loaded RxNorm RDF model
?sourcemed (count(distinct ?match_rxcui ) as ?count)
where {
    # also cource_count, source_full_name, source_normalized_full_name. source_generic_name?
    graph mydata:reference_medications {
        ?sourcemed a obo:PDRO_0000024 .
    }
    # also defined_in graph
    # also reference_medications_labels graph
    # also defined in, type ()
    graph mydata:classified_search_results {
        ?classified_search_result mydata:source_id_uri ?sourcemed ;
                                  mydata:prob_more_distant ?prob_more_distant ;
                                  mydata:match_rxcui ?match_rxcui .
    }
    filter(?prob_more_distant < 0.06)
}
group by ?sourcemed 
order by desc (count(distinct ?match_rxcui ))
```



<img src="useful_classified_rxcui_count.png"/>Not shown: http://example.com/resource/source_med_id/6173011 'Lyrica' has roughly 15 search results pointing to their own unique RxCUI and about 15 all pointing to one shared RxCUI



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
insert {
    graph mydata:elected_mapping {
        ?wasinner mydata:elected_mapping ?outermrxc
    }
}
where 
{
    {
        select
        (?innersm as ?wasinner) ?outermrxc ?innerpimax (sum(?outerpi) as ?outersum) 
        where {
            graph mydata:classified_search_results {
                ?doublecheck mydata:source_id_uri ?innersm ;
                             mydata:prob_identical ?outerpi ;
                             mydata:match_rxcui ?outermrxc .
            }
            {
                select (?sourcemed as ?innersm) (max(?pisum) as ?innerpimax) 
                where
                {
                    select ?sourcemed ?match_rxcui (sum( ?prob_identical ) as ?pisum)
                    where {
                        graph mydata:reference_medications {
                            ?sourcemed a obo:PDRO_0000024 ;
                                       mydata:source_count ?source_count .
                        }
                        graph mydata:classified_search_results {
                            ?classified_search_result mydata:source_id_uri ?sourcemed ;
                                                      mydata:prob_more_distant ?prob_more_distant ;
                                                      mydata:prob_identical ?prob_identical ;
                                                      mydata:match_rxcui ?match_rxcui .
                        }
                    }
                    group by ?sourcemed ?match_rxcui
                    order by desc (sum( ?prob_identical ))
                }
                group by ?sourcemed 
            }
        }
        group by ?innersm ?innerpimax ?outermrxc
    }
    filter(?innerpimax = ?outersum) 
}
```

***Number of triples inserted & timing?***

**I haven't accounted for all of the biases in the mapping elections above. For example, if a perfect lexical match is only found in one RxNav source, but close matches are found in several, the sum of the close match scores will probably outweigh the one perfect score. **

**This may also cause a bias towards generic name classifications.**

Having said that, the medication mapping only associates http://example.com/resource/source_med_id/2148179 'Lyrica' with http://purl.bioontology.org/ontology/RXNORM/593441 'Lyrica'. (PDS associates it with Lyrica's active ingredient, http://purl.bioontology.org/ontology/RXNORM/187832 'pregabalin'). ChEBI asserts the http://purl.obolibrary.org/obo/CHEBI_35623 'anticonvulsant' role on http://purl.obolibrary.org/obo/CHEBI_64356 'pregabalin', but DrOn asserts their native 'pregabalin' term http://purl.obolibrary.org/obo/DRON_00017760 as the ingredient in Lyrica/pregabalin products.

There are BioPortal mappings between the RxNorm, ChEBI and DrOn pregabalin terms, but that doesn't address the fact that TMM associates medication 2148179 with 'Lyrica'

Solutions:

- trust the source (PDS) asserted RxCUI
- Traverse RxNorm relations. In this case, it's only one: pregabalin has_tradename Lyrica



## What DrOn terms could be replaced by a ChEBI term

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
distinct ?dronterm ?dl ?chebiterm ?cl ?ci_identical
where {
    graph mydata:bioportal_mappings {
        ?dronterm mydata:bioportal_mapping ?chebiterm .
    }
    #    better (faster?) as union? acceptable either way in this case
    # can also check the graph in which a thing has its type (owl:Class?) asserted
    values ?drongraph {
        <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl>
        <http://purl.obolibrary.org/obo/dron/dron-hand.owl>
    }
    graph mydata:defined_in {
        ?dronterm mydata:defined_in ?drongraph .
    }
    graph mydata:defined_in {
        ?chebiterm mydata:defined_in obo:chebi.owl .
    }
    minus {
        ?dronterm mydata:defined_in obo:chebi.owl .
    }
    graph obo:chebi.owl {
        ?chebiterm rdfs:label ?cl .
    }
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?dronterm rdfs:label ?dl .
    }
    bind((lcase(str( ?dl))) = (lcase(str( ?cl))) as ?ci_identical)
}
order by ?ci_identical ?dl ?cl
```

> Showing results from 1,001 to 1,681 of **1,681**. Query took 0.8s, minutes ago.



## What's the breakdown of DrOn ingredient term sources?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select ?chebient ?dronent (count(distinct ?s) as ?count) 
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
    }
    filter(isiri(?s))
    bind(contains(str(?s), "CHEBI") as ?chebient)
    bind(contains(str(?s), "DRON") as ?dronent)
}
group by ?chebient ?dronent
```

> Showing results from 1 to 2 of 2. Query took 1.6s, minutes ago.



| **chebient** | **dronent** | **count** |
| ------------ | ----------- | --------: |
| true         | false       |       795 |
| false        | true        |      5246 |

## How many DrOn-native ingredient terms don't have a ChEBI mapping?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
?chebimapped (count(distinct ?s ) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    optional {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(bound( ?mappedterm ) as ?chebimapped)
}
group by ?chebimapped
```

> Showing results from 1 to 2 of 2. Query took 4.3s, minutes ago.



| **chebimapped**      | **count**           |
| -------------------- | ------------------: |
| true  | 1677 |
| false | 3569 |

### Oops, make sure they're active ingredients

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
?chebimapped (count(distinct ?s ) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
        ?x1 rdf:rest rdf:nil ;
            rdf:first ?r .
        ?x2 rdf:rest ?x1 ;
            rdf:first ?x3 .
        ?x3 a owl:Restriction ;
            owl:someValuesFrom obo:DRON_00000028 ;
            owl:onProperty obo:BFO_0000053 .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    optional {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(bound( ?mappedterm ) as ?chebimapped)
}
group by ?chebimapped
```



> Showing results from 1 to 2 of 2. Query took 4.4s, minutes ago.



| **chebimapped**      | **count**           |
| -------------------- | ------------------: |
| true  | 1546 |
| false | 2531 |

## What are the DrOn-native active ingredient terms that lack ChEBI mappings?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
distinct ?s ?l ?lcl
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
        ?x1 rdf:rest rdf:nil ;
            rdf:first ?r .
        ?x2 rdf:rest ?x1 ;
            rdf:first ?x3 .
        ?x3 a owl:Restriction ;
            owl:someValuesFrom obo:DRON_00000028 ;
            owl:onProperty obo:BFO_0000053 .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    minus {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(lcase(str(?l)) as ?lcl)
}
order by ?lcl
```

> Showing results from 1 to 1,000 of 2,531. Query took 2.5s, minutes ago.

### Common words in unmapped terms

| **count** | **dron_term_word** |
| ----: | -------------- |
| 785   | extract        |
| 348   | allergenic     |
| 240   | pollen         |
| 129   | vaccine        |
| 85    | preparation    |
| 56    | virus          |
| 54    | a              |
| 52    | protein        |
| 46    | human          |
| 43    | capsular       |

-----

## What proportion of DrOn RxCUI assertions are active?

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select 
?active (count(distinct ?dronent) as ?count)
where {
    {
        {
            graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
                ?dronent <http://purl.obolibrary.org/obo/DRON_00010000> ?rxcval .
            }
        } union {
            graph obo:dron-rxnorm.owl {
                ?dronent <http://purl.obolibrary.org/obo/DRON_00010000> ?rxcval .
            }
        }
        optional {
            graph <http://purl.bioontology.org/ontology/RXNORM/> {
                ?rxnent skos:notation ?rxcval ;
                        a ?t .
            }
        }
        bind(bound(?t) as ?active)
    }
}
group by ?active
```

> Showing results from 1 to 2 of 2. Query took 2.2s, minutes ago.

| **active** | **count** |
| ---------- | --------: |
| true       |     42108 |
| false      |     50066 |

## Should also check if some DrOn entries have more than one RxCUI assertion

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select (?count as ?rxcui_count) (count(distinct ?dronent) as ?dronents)
where {
    select ?dronent (count(distinct ?rxcval) as ?count)
    where {
        {
            {
                graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
                    ?dronent <http://purl.obolibrary.org/obo/DRON_00010000> ?rxcval .
                }
            } union {
                graph obo:dron-rxnorm.owl {
                    ?dronent <http://purl.obolibrary.org/obo/DRON_00010000> ?rxcval .
                }
            }
        }
    }
    group by ?dronent
    order by desc (count( ?rxcval ))
}
group by ?count 
order by (count(distinct ?dronent))
```

> Showing results from 1 to 3 of 3. Query took 5.1s, moments ago.



### Could this be explained by many DrOn terms taking multiple RxCUIs? Some old and some current?

| rxcui_count      | dronents             |
| ---------------- | -------------------: |
|  3   |  1       |
|  2   |  6       |
|  1   |  92167   |



## Additional DrOn and general Graph/Ontology accounting



```SPARQL
select 
?g (count(distinct ?s) as ?count)
where {
    graph ?g {
        ?s a ?t .
    }
}
group by ?g
order by desc (count(distinct ?s))
```

> Showing results from 1 to 14 of 14. Query took 3.9s, minutes ago.



| **g**                                                        | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 636232 |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 502504 |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) | 138159 |
| [mydata:cui](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcui) | 136044 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | 113234 |
| [obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | 86926  |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | 36202  |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | 35165  |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) | 6362   |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | 2553   |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 606    |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | 181    |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) | 4      |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | 1      |



| **g**                                                        | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) | 6362   |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 606    |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 502504 |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | 181    |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | 2553   |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) | 138159 |
| [mydata:cui](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcui) | 136044 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | 35165  |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) | 4      |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | 36202  |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 636232 |
| **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)** | **86926** |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | 1  |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | 113234 |



```SPARQL
select 
?o (count( ?s) as ?count)
where {
    graph <http://example.com/resource/defined_in> {
        ?s <http://example.com/resource/defined_in> ?o .
    }
}
group by ?o
order by desc (count( ?s))

```

> Showing results from 1 to 13 of 13. Query took 1.4s, minutes ago.



| **o**                                                        | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) | 138158 |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 134657 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | 113234 |
| [obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | 86151  |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 43705  |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | 36202  |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | 35164  |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) | 6362   |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | 1706   |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 161    |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | 112    |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) | 4      |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | 1      |



| **o**                                                        | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) | 6362   |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 161    |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 43705  |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | 112    |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | 1706   |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) | 138158 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | 35164  |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) | 4      |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | 36202  |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 134657 |
| **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)** | **86151** |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | 1  |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | 113234 |



### Versions

| **subject**                                                  | **predicate**                                                | **object**                                                   | **context**                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:versionIRI](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionIRI) | [chebi:185/chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2F185%2Fchebi.owl) | [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |



| **subject**                                                  | **predicate**                                                | **object**                    | **context**                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------- | ------------------------------------------------------------ |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | [owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo) | 2019aa                        | [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | [owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo) | 2019ab                        | [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |
| **[http://purl.bioontology.org/ontology/UATC/](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FUATC%2F)** | **[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)** | **2019ab**                    | **[atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F)** |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | [owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo) | 2020-01-06                    | [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |
| *[obo:ido.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fido.owl)* | *[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)* | *2017-11-03*                  | *[https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl)* |
| *[obo:obi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fobi.owl)* | *[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)* | *2019-06-05*                  | *[https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl)* |
| *[obo:obi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fobi.owl)* | *[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)* | *2019-11-12*                  | *[https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl)* |
| *[obo:ogg.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fogg.owl)* | *[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)* | *"Vision Release: 1.0.59"@en* | *[https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl)* |
| *[obo:omrse.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fomrse.owl)* | *[owl:versionInfo](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionInfo)* | *2019-21-02*                  | *[https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl)* |



### Ontologies

| **subject**                                                  | **predicate**                                                | **object**                                                   | **context**                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| _:node1328838                                                | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) |
| _:node1328839                                                | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |
| **[dron:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-rxnorm.owl)** | **[rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type)** | **[owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology)** | **[mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand)** |
| **[dron:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-rxnorm.owl)** | **[rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type)** | **[owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology)** | **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)** |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) |
| **[http://purl.bioontology.org/ontology/UATC/](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FUATC%2F)** | **[rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type)** | **[owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology)** | **[atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F)** |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |
| [mydata:bioportal_mappings](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fbioportal_mappings) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Ontology](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |

- ATC graph should be renamed http://purl.bioontology.org/ontology/UATC/
- **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)**  graph should be renamed  **[dron:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-rxnorm.owl)**  
  - error in upload configuration?
- check mydata:turbo_med_mapping_hand
- can robot templating assert the ontology name? 
  - mydata:reference_medications (source meds)  
  - mydata:classified_search_results



----

## placeholder for clinical labs

- [ ] custom BioPortal mappings (esp. for LOINC bld->blood) ?
- [ ] ...