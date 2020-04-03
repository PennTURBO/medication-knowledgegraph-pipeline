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
- [ ] add RxNorm types to RxCUIs
- [ ] more aggressive consensus building for the multiple acceptable classified search results that could be associated with a source medication.
  - [ ] maybe the direct relationships will make this moot
  - [ ] take a vote?
  - [ ] weight scores by classified semantic distance and sum?
  - [ ] lowest common subsumer?



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#* 
# this should aleady ahve been depleted of RxCUIs that RxNav suggested
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



<img src="/Users/markampa/Downloads/useful_classified_rxcui_count.png"  />

http://example.com/resource/source_med_id/6173011 6173011|Lyrica has roughly 15 search results pointing to thieir own unique RxCUI and about 15 all pointing to one shared RxCUI



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#* 
?sourcemed ?match_rxcui (sum( ?prob_identical ) as ?pisum)
where {
    values ?sourcemed {
        <http://example.com/resource/source_med_id/6173011>
    }
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
                                  mydata:prob_identical ?prob_identical ;
                                  mydata:match_rxcui ?match_rxcui .
    }
    filter(?prob_more_distant < 0.05)
}
group by ?sourcemed ?match_rxcui
order by desc (sum( ?prob_identical ))
```



- [ ] run again with lower min (EMPI) count... 20? 10?
  - [ ] still haven't taken any action about the apparent ceiling on the nuber of approximate match API calls from R script to RxNav in a box.
- [ ] would be nice to use R rdflib's as rdf function. see stack overflow issue.



## placeholder for clinical labs

- [ ] custom BioPortal mappings (esp. for LOINC bld->blood) ?
- [ ] ...

