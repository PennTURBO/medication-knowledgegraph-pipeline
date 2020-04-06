## User is interested in patients with orders for "antitussive" cough medications



### Solr search

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:antiussive~&rows=3

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
_Here's one route, in unoptimized SPARQL, for finding medication orders that include an ingredient with an **antitussive role**, according to ChEBI_

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

_RxCUI associations with source medications have already gone through one round of quality filtering, but it's not uncommon for a source medication to still have multiple RxCUI associations. All of those RxCUI associations may have the same RxCUI value, but occasionally there are multiple associated RxCUI values. Even then, they seem to be semantically very close. Nonetheless,  I'm still thinking of finding additionally ways to get a single consensus RxCUI, and to build a direct relationship between the source/reference medication and the RxCUI. That would eliminate the need for traversing the classified search result entities._

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

Note: I'm not using the fuzzy spelling `~` operator with the row limit of 3 here. It brings terms like "nystatin oral capsule [bio-statin]", with multiple `*statin*` tokens, up to the top. In that case, "statin" CHEBI:87631 appears 8th in the list.

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:(statin)&rows=3

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

#### why didn't I get any orders for 'macrolide antibiotic's with the Q3 query style?

-  macrolide antibiotic = http://purl.obolibrary.org/obo/CHEBI_25105
- No mass is asserted for that term (good in this case). 
- It's a subclass of [macrolide, CHEBI:25106 ](http://purl.obolibrary.org/obo/CHEBI_25106) and the role restriction below (required in this case)
- CHEBI:2682, "amphotericin B" is a subclass of macrolide (structurally streaking)
- CHEBI is an indirect subclass of [obo:CHEBI_33281](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_33281)  [antimicrobial agent](http://purl.obolibrary.org/obo/CHEBI_33281) via CHEBI:87113 - antibiotic antifungal drug
- Maybe there's no explicit chain of statements that amphotericin B is a macrolide antibiotic? Requires OWL reasoning?



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

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:(rosuvastatin)&rows=10

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

#### Q4: User asks for ChEBI ingredient, but DrOn models that ingredient with its own DrOn-native term. Connect them with additional BioPortal mappings.

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

Also, chains of RxNorm relations can relate a RxNorm ingredient to a RxNorm product, which is usually the match end of the classification process, as an alternative to the transitively materialized DrOn ingredient relations. However, the RxNorm chains  are highly variable in composition and length. I haven't yet determined which offers better coverage.



#### Opportunity: replace DrOn ingredients with ChEBI ingredients mapped by BioPortal

#### Related: Check validity of RxNorm terms asserted by DrOn



## User interested in patients with orders for serotonin and norepinephrine reuptake inhibitors. Searches for `SNRI`.

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,prefLabel,score&q=medlabel:(SNRI~)&rows=10

Several hits are available from NDF-RT, but not from ChEBI. (Roles like SNRI aren't expected in DrOn or RxNorm.) Do they all have the same meaning? 

Here we also retrieve the `prefLabel` to help the user see that SNRI can be interpreted in at least two ways. The user would presumably choose NDFRT:N0000175749

```json
{
  "responseHeader":{
    "status":0,
    "QTime":10,
    "params":{
      "q":"medlabel:(SNRI~)",
      "fl":"mediri,labelpred,medlabel,prefLabel,score",
      "rows":"10"}},
  "response":{"numFound":839,"start":0,"maxScore":10.892033,"docs":[
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175749"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["snri"],
        "prefLabel":["serotonin and norepinephrine reuptake inhibitor [epc]"],
        "score":10.892033},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175695"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["snri"],
        "prefLabel":["norepinephrine reuptake inhibitor [epc]"],
        "score":10.892033},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175696"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["ssri"],
        "prefLabel":["serotonin reuptake inhibitor [epc]"],
        "score":8.169024},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175464"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["hiv-1 nnrti and nrti"],
        "prefLabel":["human immunodeficiency virus 1 non-nucleoside and nucleoside analog reverse transcriptase inhibitor [epc]"],
        "score":7.623132},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/220049"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["stri-dex"],
        "score":7.3780704},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175749"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["serotonin and norepinephrine reuptake inhibitor (snri)"],
        "prefLabel":["serotonin and norepinephrine reuptake inhibitor [epc]"],
        "score":7.0910897},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/220050"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["stri-dex clear gel"],
        "score":6.1811156},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/1295895"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["stri-dex soap product"],
        "score":6.1811156},
      {
        "mediri":["http://purl.bioontology.org/ontology/RXNORM/1296422"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#prefLabel"],
        "medlabel":["stri-dex topical product"],
        "score":6.1811156},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175696"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["serotonin reuptake inhibitor (ssri)"],
        "prefLabel":["serotonin reuptake inhibitor [epc]"],
        "score":6.1811156}]
  }}
```



### Q5: NDF-RT role (established pharmaceutical class)

```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
distinct ?ndfrt_class ?source_id_uri ?source_med_id ?prob_more_distant ?match_rxcui ?ndfrt_ing ?chebi_ing ?dron_prod
where {
    values ?ndfrt_class {
        <http://purl.bioontology.org/ontology/NDFRT/N0000175749>
    }
    graph <http://purl.bioontology.org/ontology/NDFRT/> {
        ?ndfrt_ing rdfs:subClassOf ?ndfrt_class .
    }
    graph mydata:bioportal_mappings {
        ?ndfrt_ing mydata:bioportal_mapping ?chebi_ing
    }
    # or could require that it's defined in obo:chebi.owl
    # see RxNorm example below
    # these improve performance
    graph obo:chebi.owl {
        ?chebi_ing a owl:Class
    }
    graph <http://example.com/resource/transitively_materialized_dron_ingredient> {
        ?dron_prod mydata:transitively_materialized_dron_ingredient ?chebi_ing .
    }
    graph mydata:bioportal_mappings {
        ?dron_prod mydata:bioportal_mapping ?match_rxcui .
    }
    graph mydata:defined_in {
        ?match_rxcui mydata:defined_in <http://purl.bioontology.org/ontology/RXNORM/>
    }
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


*With more logical ordering and named-graph constraints,  this query is written better than the previous ones.*



### Opiates

The formal RDF & OWL semantics through ChEBI, DrOn and RxNorm are pretty simple here. The sample SPARQL queries above can be used to connect the relevant roles and classes to the relevant source medication orders.

Helping the user do a fruitful Solr search for roles and classes will be more of a challenge here, so a little background information may be helpful in designing positive and negative test cases for the software. 

The terms opiate, opioid, and narcotic are related but not completely interchangeable. Clinicians, pharmacologists and regulatory agencies frequently favor one term over the others. 

According to Wikipedia

- an opiate is a compound that can be derived from opium, which is extracted from the opium poppy 

- an opioid is any substance that can bind to opioid receptor proteins, like you would find on the surface of human neurons


The term "narcotic" has the most ambiguous meaning.

Opioids can agonize opioid receptors, which could lead to euphoria and analgesia, or they can block/antagonize the receptors. Naloxone is used as a blocker to reverse the respiratory depression associated with overdose.

Some pharmacological authorities focus on the subtype of opioid receptor that a compound predominantly binds to. Compounds agonizing mu receptors are especially useful for analgesia. Compounds binding to kappa receptors also cause analgesia, but have hallucinations or even dysphoria as possible side effects.

Analgesia is not the only medicinal use of opioids: the compound loperamide is used orally to treat diarrhea, without causing euphoria.

The meaning of "opiate", "opioid" or "narcotic" is clearer when combined with an  application or mechanism. This Solr query

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score,source&q=medlabel:(opiate opioid narcotic analgesic -non)

gives a good score to "opioid analgesic" (CHEBI:35482 and NDFRT:N0000175440), and also to "narcotic antitussive" (NDFRT:N0000175795, like codeine), but not to CHEBI:35481, "non-narcotic analgesic". CHEBI:35482 could be used in a Q1 style SPARQL query, and NDFRT:N0000175440 could be used in a Q5 query.

#### Older style

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
distinct 
?drugrole ?chebi_ing ?dron_prod ?match_rxcui ?prob_more_distant ?source_id_uri ?source_med_id  ?source_med_id 
where {
    values ?drugrole {
        <http://purl.obolibrary.org/obo/CHEBI_35482>
    }
    graph mydata:transitive_role_of_class {
        ?chebi_ing mydata:transitive_role_of_class ?drugrole .
    }
    graph mydata:transitively_materialized_dron_ingredient {
        ?dron_prod mydata:transitively_materialized_dron_ingredient ?chebi_ing .
    }
    graph mydata:bioportal_mappings {
        ?match_rxcui mydata:bioportal_mapping ?dron_prod .
    }
    graph <http://purl.bioontology.org/ontology/RXNORM/> {
        ?match_rxcui a owl:Class
    }
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



#### New style as of 2020-04-06: materialized source med IDs & direct links to RxCUIs

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select 
distinct 
?drugrole ?chebi_ing ?dron_prod ?match_rxcui ?source_med  ?source_med_id
where {
    values ?drugrole {
        obo:CHEBI_35482
    }
    graph mydata:transitive_role_of_class {
        ?chebi_ing mydata:transitive_role_of_class ?drugrole .
    }
    graph mydata:transitively_materialized_dron_ingredient {
        ?dron_prod mydata:transitively_materialized_dron_ingredient ?chebi_ing .
    }
    graph mydata:bioportal_mappings {
        ?match_rxcui mydata:bioportal_mapping ?dron_prod .
    }
    graph rxnorm: {
        ?match_rxcui a owl:Class
    }
    graph mydata:elected_mapping {
        ?source_med mydata:elected_mapping ?match_rxcui
    }
    #    filter( ?prob_more_distant < 0.06 )
    graph <http://example.com/resource/source_med_id/> {
        ?source_med skos:notation ?source_med_id
    }
}
```



Different Solr queries

> http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score,source&q=medlabel:(opiod agonists)

picks up some additional NDF-RT classes.

http://`<`solraddress`>`:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score,source&q=medlabel:(mu binding)

picks up DRON:00000036, "function-inhibiting mu receptor binding disposition". I haven't provided any examples of traversing over DrOn dispositions yet because DrOn only contains ~ 35 as of April 2020.



```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
distinct ?s (lcase(str(?l)) as ?label)
where {
    values ?g {
        <http://purl.obolibrary.org/obo/dron/dron-hand.owl> 
        <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl>
        <http://purl.obolibrary.org/obo/dron/dron-upper.owl>
        
    }
    graph ?g {
        ?s rdfs:subClassOf* obo:BFO_0000016
    }
    ?s rdfs:label ?l .
}
```



## User interested in patients with orders for "z-drugs"

A class with the right members, (indirectly) like obo:CHEBI_10125 "zolpidem", exists: 

http://purl.bioontology.org/ontology/UATC/N05CF "benzodiazepine related hypnotics and sedatives"

But it can’t be found with Solr (or any text search engine for that matter)

If the user searched for "benzodiazepine related hypnotics and sedatives" and ticked off ATC:N05CF, the following SPARQL query would find source orders

### This goes from the ATC class to ingredient orders

Subsequent example queries will go to products (generic or branded)

```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX atc: <http://purl.bioontology.org/ontology/UATC/>
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select * where {
    values ?atcclass {
        atc:N05CF 
    }
    graph <http://purl.bioontology.org/ontology/ATC/> {
        ?atcing rdfs:subClassOf ?atcclass
    }
    graph mydata:bioportal_mappings {
        ?atcing mydata:bioportal_mapping ?rxning .
    }
    graph mydata:defined_in {
        ?rxning mydata:defined_in rxnorm:
    }
    graph mydata:elected_mapping {
        ?source_med mydata:elected_mapping ?rxning
    }
    graph <http://example.com/resource/source_med_id/> {
        ?source_med skos:notation ?source_med_id
    }
} limit 100
```



#### Opportunity: 

- add a "z-drugs" synonym for UATC:N05CF in the Solr collection (uncoupled from the TURBO ontology?!)
- assert a synonym in a TURBO named graph
- create a disposition in DrOn and add the synonym "z-drug"
- use something like RxNav's "classes that contain" feature to discover a class by example



Related/also potentially uncoupled from ontology: adding mappings to BioPortal VM
