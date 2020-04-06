# Things we could still do with the medication knowledge graph

*With indication of complexity.*

*What about **importance**?*

- [ ] Start compressing ttl files before sending to graphdb over network

```bash
1187698125 Apr  5 09:27 classified_search_results_from_robot.ttl

  18365299 Mar 29 09:29 med_mapping_bioportal_mapping.ttl

  45197994 Apr  5 09:15 reference_medications_from_robot.ttl

  28596154 Apr  5 14:14 rxcui_ttys.ttl
```



- [ ] the following scripts have been combined into `med_mapping_load_materialize_etc.R` but not tested yet

- `med_mapping_load_materialize_project.R`
- `afterthoughts.R`
- `sparql_mm_kb_labels_to_solr.R`



- [ ] add yaml parsing to robot sh wrapper, so TSV and TTL files doen't ahve to be hardcoded

- [ ] discover more normalizable abbreviations with somethings like phrase2vec, over a large **clinical** corpus? *Complex*.
- [ ] review notes from DLM's MS student
  - [ ] insulin syringe needles
  - [ ] CBC
  - [ ] home nursing
- [ ] add two-hop classicization’s to classifier. *complex*.

  - [ ] important for understanding "coverage"
  - [ ] coverage correlates with min count
- [ ] Prioritize fullname search results over generics? *Medium*.
- [ ] **insert triples about mapping process into triplestore. which params?** which graph? which parameters? *medium*.
  - [ ] Database etc connections? prob not
  - [ ] Filenames? any use in the absence of a hostname a full path? should the files be saved somewhere? what about the yaml file itself, stripped of sensitive info?
  - [ ] ntree and mtry?
  - [ ] min.empi.count?

- [ ] Make images of visual graphs corresponding to user stories. *Medium*.

- [ ] confirm PDS R_MEDICATION PKs being used as stable PKs. *Discussion*.

- [ ] **add the PKs as properties of the source medications? (As opposed to just being the RHS of the IRIs)**. *Easy*.

- [ ] make a sample, non-PDS input file. *Medium*.

- [ ] try BioPortal ontology submission API method. *complex*.
  
  - [ ] http://data.bioontology.org/documentation#OntologySubmission
  
- [ ] clean up file and variable names. *Medium*.

- [ ] see if there’s anything worth keeping in the `extras` and `old` GitHub subdirectories. *Medium*.

- [ ] add option for saving diagnostic data structures in R scripts. *medium*.

  

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

- [x] remove minimal templating ontology invocation from ROBOT shell script and confirm it still works!

- [ ] use TURBO or OBO predicates for source/reference medications and classified search results, not `mydata:`

- [x] create direct relationship between source medication and RxCUI

- [x] run classification again with min (EMPI) count of 10
  - [ ] still haven't taken any action about the apparent ceiling on the number of approximate match API calls from R script to RxNav in a box.
  - [ ] would be nice to use R rdflib's as rdf function. see stack overflow issue.
  
- [x] add RxNorm types to RxCUIs (from RxNav MySQL?)

- [ ] normalize mydata:bioportal_mappings graph with mydata:bioportal_mapping predicate

- [x] more aggressive consensus building when multiple classified search results could be reasonably associated with a source medication. **See below**
  - [ ] maybe the direct relationships will make this moot
  - [ ] take a vote?
  - [ ] weight scores by classified semantic distance and sum?
  - [ ] lowest common subsumer?




### check `defined_in`/`rdf:type owl:Ontology` relationships   

- [x] also get versions
- [ ] **now reconcile**
    - [ ] ATC graph should be renamed http://purl.bioontology.org/ontology/UATC/
    - [ ] **obo:dron-rxnorm.owl** graph should be renamed  **dron:dron-rxnorm.owl]**
        - [ ] error in upload configuration?
        - [ ] check mydata:turbo_med_mapping_hand
    - [ ] can robot templating assert the ontology name? 
        - [ ] probably use an input "ontology" file and a merge parameter?
    - [ ] mydata:reference_medications (source meds)  
    - [ ] mydata:classified_search_results


## Consensus of med mappings by sum of identical scores

### First:  How many search results are available for each source medication

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
    # also source_count, source_full_name, source_normalized_full_name. source_generic_name?
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

See mapping elections solution `fewer_directer_mappings` in `rxnav_med_mapping.yaml`. I haven't recorded number of triples inserted or execution time. (I think it's arround 5 minutes.)

**I haven't accounted for all of the possible biases in the mapping elections. For example, if a perfect lexical match is only found in one RxNav source, but close matches are found in several, the sum of the close match scores will probably outweigh the one perfect score. **

**This may also cause a bias towards generic name classifications.**

Having said that, the medication mapping only associates http://example.com/resource/source_med_id/2148179 'Lyrica' with http://purl.bioontology.org/ontology/RXNORM/593441 'Lyrica'. (PDS associates it with Lyrica's active ingredient, http://purl.bioontology.org/ontology/RXNORM/187832 'pregabalin'). ChEBI asserts the http://purl.obolibrary.org/obo/CHEBI_35623 'anticonvulsant' role on http://purl.obolibrary.org/obo/CHEBI_64356 'pregabalin', but DrOn asserts their native 'pregabalin' term http://purl.obolibrary.org/obo/DRON_00017760 as the ingredient in Lyrica/pregabalin products.

There are BioPortal mappings between the RxNorm, ChEBI and DrOn pregabalin terms, but that doesn't address the fact that TMM associates medication 2148179 with 'Lyrica'

Solutions:

- trust the source (PDS) asserted RxCUI
- Traverse RxNorm relations. In this case, it's only one: pregabalin has_tradename Lyrica




## Empirically, what minimum was applied to source_counts?

```SPARQL
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
select 
(min(?source_count) as ?min)
where {
    graph <http://example.com/resource/reference_medications>  {
        ?sourcemed <http://example.com/resource/source_count> ?source_count
    }
}
```



### Solr post-instal prerequisites

```bash
$ ~/solr-8.4.1/bin/solr start
```



> *** [WARN] *** Your open file limit is currently 2560.
> It should be set to 65000 to avoid operational disruption.
> If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
> *** [WARN] ***  Your Max Processes Limit is currently 5568.
> It should be set to 65000 to avoid operational disruption.
> If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
> Waiting up to 180 seconds to see Solr running on port 8983 [-]
> Started Solr server on port 8983 (pid=33449). Happy searching!



```bash
$ ~/solr-8.4.1/bin/solr create_core -c <med.map.kb.solr.host from rxnav_med_mapping.yaml> 
```



### additional Solr notes

- [ ] give the different authorities different weights?

- [x] Core is cleared in R script before reloading

  - [ ] delete core from command line?

  ```bash
  bin/Solr delete -c med_mapping_labels
  ```

  > Deleting core 'med_mapping_labels' using command:
  > http://localhost:8983/solr/admin/cores?action=UNLOAD&core=med_mapping_labels&deleteIndex=true&deleteDataDir=true&deleteInstanceDir=true

- [x] usage of ~ fuzzy operator shown in `all_fuzzy_solr_label_to_iri.R`

  - [ ] also consider edgengrams (in query and index parsers)
  - [ ] use these features? probsbaly not.
    - [ ] mlt (more like this)
    - [ ] Highlighting
  - [ ] R facting example:

  ```R
  cli$facet("med_mapping_labels", params = list(q="*:*", facet.field='temp_normlab_value'),
      callopts = list(verbose = TRUE))
  ```

  

## r script ordering


#### what about requirements? 

(besides R & libraries)


1. before classification
    - `rxnav_med_mapping_setup.R`
        - never invoked directly. always invoked from the other R scripts.
        - uses config file `rxnav_med_mapping.yaml`
    - `rxnav_med_mapping_proximity_training_no_tuning.R`
        - Required. probably doesn't need to be rerun that often.
        - requires RxNav, preferably local container
    - `rxnav_med_mapping_tuneup_followon.R`
        - Optional. Run interactively, or modify code. new settings should be entered into `rxnav_med_mapping.yaml`.
1. classification
    - `pds_r_medication_sql_select.R`
        - Optional
        - requires SQL connection to PDS
    - `rxnav_med_mapping_pds_proximity_classifier.R`
        - requires RxNav, preferably local container
        - requires triplestore
        - clears repo
        - generates two TSV outputs in current working directory... for filenmaes, see `med_mapping_robot.sh`
1. generate med mapping RDF
    - `med_mapping_robot.sh`
        - Converts TSV from above into TTL
1. post classification
    1. `serialize_bioportal_mappings.R`
        - required. probably doesn't need to be rerun that often. requires BioPortal connection, preferably local VM. BioPortal connection must be populated with certain ontologies. RDF models
    1. `med_mapping_load_materialize_project.R`
        - loads TTL results from previous steps
    1. `afterthoughts.R`
    1. `sparql_mm_kb_labels_to_solr.R`



- `all_fuzzy_solr_label_to_iri.R`
  - just an example of querying Solr