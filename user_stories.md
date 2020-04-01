## User is interested in patients with orders for "antitussive" cough medications



### Solr search

http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:antiussive~&rows=3

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"medlabel:antiussive~",
      "fl":"mediri,labelpred,medlabel,score",
      "rows":"3"}},
  "response":{"numFound":41,"start":0,"maxScore":13.348372,"docs":[
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_51177"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["antitussive"],
        "score":13.348372},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000178319"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["antitussive"],
        "score":13.348372},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000029416"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["antitussive/antimuscarinic"],
        "score":12.05588}]
  }}
```


####  Q1 (ChEBI role)
_One route, in unoptimized SPARQL, for finding medication orders that include an ingredient with an **antitussive role**, according to ChEBI_

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
select 
distinct ?source_med_id ?prob_more_distant ?match_rxcui ?bioportal_mapping ?dron_chebi_ing ?drugrole
where {
    values ?drugrole {<http://purl.obolibrary.org/obo/CHEBI_51177>}
    graph mydata:classified_search_results {
        ?classified_search_res a obo:OBI_0001909 ;
                               mydata:prob_more_distant ?prob_more_distant ;
                               mydata:match_rxcui ?match_rxcui ;
                               mydata:source_id_uri ?source_id_uri .
    }
    filter( ?prob_more_distant < 0.06 )
    bind(replace(str(?source_id_uri), "http://example.com/resource/source_med_id/", "") as ?source_med_id)
    ?match_rxcui mydata:bioportal_mapping ?bioportal_mapping .
    ?bioportal_mapping mydata:transitively_materialized_dron_ingredient ?dron_chebi_ing .
    # chebi ing to role case
    ?dron_chebi_ing mydata:transitive_role_of_class ?drugrole .
}
```

Why `?prob_more_distant < 0.06`

The random forest knows of ~ 18 classes, including 

- identical
- more distant
- ingredient of, etc.

A "random" score for `more distant` would be ~ 1/18 or ~ 0.06

_RxCUI associations with source medications have already gone through one round of quality filtering, but it's not uncommon for a source medication to still have RxCUI associations. All of those RxCUI associations may have the same RxCUI value, but sometimes there are multiple associated RxCUI values. Even then, they seem to be semantically very close. Nonetheless,  I'm still thinking of finding additionally ways to get a single consensus RxCUI, and to build a direct relationship between the source/reference medication and the RxCUI. That would eliminate the need for traversing the classified search result entities._

----

**Q1** can be easily modified to look for orders including a known **antitussive ChEBI ingredient**, like dextromethorphan ([CHEBI:4470](https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI%3A4470))

#### Q2 (ChEBI ingredient)

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
select 
distinct ?source_med_id ?prob_more_distant ?match_rxcui ?bioportal_mapping ?dron_chebi_ing ?drugrole
where {
    values ?dron_chebi_ing {<http://purl.obolibrary.org/obo/CHEBI_4470>}
    graph mydata:classified_search_results {
        ?classified_search_res a obo:OBI_0001909 ;
                               mydata:prob_more_distant ?prob_more_distant ;
                               mydata:match_rxcui ?match_rxcui ;
                               mydata:source_id_uri ?source_id_uri .
    }
    filter( ?prob_more_distant < 0.06 )
    bind(replace(str(?source_id_uri), "http://example.com/resource/source_med_id/", "") as ?source_med_id)
    ?match_rxcui mydata:bioportal_mapping ?bioportal_mapping .
    ?bioportal_mapping mydata:transitively_materialized_dron_ingredient ?dron_chebi_ing .
}
```

## User is interested in patients with orders for drugs in the "statin" class

Note: not using the fuzzy spelling `~` operator with the row limit of 3 here. It brings terms like "nystatin oral capsule [bio-statin]", with multiple `*statin*` tokens, up to the top. In that case, "statin" CHEBI:87631 appears 8th in the list.

http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:(statin)&rows=3

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"medlabel:(statin)",
      "fl":"mediri,labelpred,medlabel,score",
      "rows":"3"}},
  "response":{"numFound":20,"start":0,"maxScore":15.66116,"docs":[
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_87631"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["statin"],
        "score":15.66116},
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_87635"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["statin (synthetic)"],
        "score":14.144724},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/215681"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["bio-statin"],
        "score":14.144724}]
  }}
```

#### Q3 ChEBI class

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
select 
distinct ?source_med_id ?prob_more_distant ?match_rxcui ?bioportal_mapping ?dron_chebi_ing ?drugclass
where {
    values ?drugclass {
        <http://purl.obolibrary.org/obo/CHEBI_87631>
    }
    graph mydata:classified_search_results {
        ?classified_search_res a obo:OBI_0001909 ;
                               mydata:prob_more_distant ?prob_more_distant ;
                               mydata:match_rxcui ?match_rxcui ;
                               mydata:source_id_uri ?source_id_uri .
    }
    filter( ?prob_more_distant < 0.06 )
    bind(replace(str(?source_id_uri), "http://example.com/resource/source_med_id/", "") as ?source_med_id)
    ?match_rxcui mydata:bioportal_mapping ?bioportal_mapping .
    ?bioportal_mapping mydata:transitively_materialized_dron_ingredient ?dron_chebi_ing .
    # chebi ing to chebi class case
    ?dron_chebi_ing mydata:transitive_massless_rolebearer ?drugclass
}
```

- *what about macrolide antibiotics?* http://purl.obolibrary.org/obo/CHEBI_25105
- No mass is asserted for that term. It's a subclass of [macrolide, CHEBI:25106 ](http://purl.obolibrary.org/obo/CHEBI_25106) and the restriction below.
- erythromycins ([CHEBI:23953](https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI%3A23953)) 'is a' [rdfs:subClassOf] macrolide antibiotic ([CHEBI:25105](https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI%3A25105))
- maybe no orders for erythromycins etc.?



| **rp**                                                       | **ro**                                                       |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [rdf:type](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | [owl:Restriction](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) |
| [owl:onProperty](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:RO_0000087](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0000087)  has role |
| [owl:someValuesFrom](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | [obo:CHEBI_33281](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_33281)  [antimicrobial agent](http://purl.obolibrary.org/obo/CHEBI_33281) |



## What if a user searches for "rosuvastatin" 

There are equally good ingredient terms from multiple terminologies

- CHEBI:38545, defined in http://purl.obolibrary.org/obo/chebi.owl
  - **Q1** ingredient query returns nothing
  - therefore, rosuvastatin containing drugs won't show up in a **Q3 ChEBI class** query either
- DRON:00018679 from http://purl.obolibrary.org/obo/dron/dron-ingredient.owl
  - DrOn usually imports ChEBI terms for ingredients but has authored a few of its own
  - substituting DRON:00018679 does return source medications
  - but that won't show up in the statin **Q3 ChEBI class** query above either, without modifications
- RxNorm [301542](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F301542) from [ http://purl.bioontology.org/ontology/RXNORM/](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F)
- ATC
- NDF-RT

http://<solraddress>:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:(rosuvastatin)&rows=10

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"medlabel:(rosuvastatin)",
      "fl":"mediri,labelpred,medlabel,score",
      "rows":"10"}},
  "response":{"numFound":92,"start":0,"maxScore":13.384594,"docs":[
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_38545"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["rosuvastatin"],
        "score":13.384594},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/301542"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["rosuvastatin"],
        "score":13.384594},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000148821"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["rosuvastatin"],
        "score":13.384594},
      {
        "mediri":["http://purl.bioontology.org/ontology/UATC/C10AA07"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["rosuvastatin"],
        "score":13.384594},
      {
        "mediri":["http://purl.obolibrary.org/obo/DRON_00018679"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["rosuvastatin"],
        "score":13.384594},
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_77313"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["rosuvastatin(1-)"],
        "score":12.0885935},
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_77249"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["rosuvastatin calcium"],
        "score":12.0885935},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/323828"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["rosuvastatin calcium"],
        "score":12.0885935},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/1157992"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["rosuvastatin pill"],
        "score":12.0885935},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000191941"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["rosuvastatin calcium"],
        "score":12.0885935}]
  }}
```

#### Q4: User asks for ChEBI ingredient, but DrOn models that ingredients with a DrOn native term. Connect with additional BioPortal mappings.

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
select 
distinct ?source_med_id ?prob_more_distant ?match_rxcui ?d_c_bp_mapping ?dron_chebi_ing ?dronprod
where {
    values ?dron_chebi_ing {<http://purl.obolibrary.org/obo/CHEBI_38545>}
    ?dron_chebi_ing mydata:bioportal_mapping ?d_c_bp_mapping ;
                     mydata:defined_in <http://purl.obolibrary.org/obo/chebi.owl> .
    ?d_c_bp_mapping mydata:defined_in <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> .
    ?dronprod mydata:transitively_materialized_dron_ingredient ?d_c_bp_mapping .
    ?dronprod mydata:bioportal_mapping ?match_rxcui .
    ?match_rxcui mydata:defined_in <http://purl.bioontology.org/ontology/RXNORM/> .
    # or materialized RxNorm    
graph mydata:classified_search_results {
?classified_search_res a obo:OBI_0001909 ;
                               mydata:prob_more_distant ?prob_more_distant ;
                               mydata:match_rxcui ?match_rxcui ;
                               mydata:source_id_uri ?source_id_uri .
    }
    filter( ?prob_more_distant < 0.06 )
    bind(replace(str(?source_id_uri), "http://example.com/resource/source_med_id/", "") as ?source_med_id)
}
```

In addition to using two BioPortal mappings, traversing from DrOn to RxNorm over materialized_rxcui is currently another solution. I may remove that graph and the materialized CUI denotations in the future,  since the BioPortal mappings have good coverage and are semantically simplest. 

On the other hand, setting up the BioPortal Virtual Machine is one of the more complex steps in TMM.

Note that the materialized CUI denotations don't provide links to DrOn or ChEBI, only between ULS components like RxNorm, ATC and NDF-RT.

Also, chains of RxNorm relations can relate a RxNorm ingredient to the RxNorm products that are usually the match end of the classification process, analogously to the transitively materialized DrOn ingredient relations. The RxNorm chains  are highly variable in composition and length. I haven't yet determined which offers better coverage.
