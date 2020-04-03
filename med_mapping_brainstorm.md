# Things we could still do with the medication knowledge graph



- [ ] Make images of visual graphs corresponding to user stories
- [ ] check defined in/is an ontology relationships
- [ ] confirm PDS R_MEDICATION PKs being used as stable PKs
- [ ] add the PKs as properties of the source medications? (As opposed to just being the RHS of the IRIs)
- [ ] make a sample, non-PDS input file
- [ ] try BioPortal ontology submission API method
- [ ] clean up file and variable names
- [ ] see if there’s anything worth keeping in the `extras` and `old` GitHub subdirectories
- [ ] purge other old files, semantic repos, Solr cores...
- [ ] plan for adding knowledge, e.g. from lung cancer effort
  - [ ] added knowledge destinations: 
    - [ ] custom BioPortal mappings (esp. for LOINC bld->blood in clinical labs)
    - [ ] Custom Solr documents
    - [ ] assertions (esp. dispositions) in DrOn
    - [ ] Assertions in TURBO ontology
- [ ] Check DrOn for inactive RxCUIs
- [ ] Check DrOn for ChEBI mappings exposed by BioPortal
- [ ] Add source medications to Solr
- [ ] Keep yaml template up to data
- [ ] remove minimal templating ontology from ROBOT
- [ ] use TURBO or OBO predicates for source/reference medications and classified search results, not `mydata:`
- [ ] direct relationship between source medication and rxcui
- [ ] run classification again with lower min (EMPI) count... 20? 10?

  - [ ] still haven't taken any action about the apparent ceiling on the number of approximate match API calls from R script to RxNav in a box.

  - [ ] would be nice to use R rdflib's as rdf function. see stack overflow issue.
- [ ] add RxNorm types to RxCUIs
- [ ] more aggressive consensus building when multiple classified search results could be reasonably associated with a source medication. **See below**
  
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
#select 
#* 
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
                        #                        values ?sourcemed {
                        #                            <http://example.com/resource/source_med_id/6173011>
                        #                        }
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
                        #                        filter(?source_count > 44)
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

Showing results from 1 to 2 of 2. Query took 2.2s, minutes ago.

| **active** | **count** |
| ---------- | --------: |
| true       |     42108 |
| false      |     50066 |

## Should also check if some DrOn enties have more than one RxCUI assertion

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



Showing results from 1 to 3 of 3. Query took 5.1s, moments ago.

| rxcui_count      | dronents             |
| ---------------- | -------------------- |
| "3"^^xsd:integer | "1"^^xsd:integer     |
| "2"^^xsd:integer | "6"^^xsd:integer     |
| "1"^^xsd:integer | "92167"^^xsd:integer |

## placeholder for clinical labs

- [ ] custom BioPortal mappings (esp. for LOINC bld->blood) ?
- [ ] ...

