## User is interested in patients with orders for "antitussive" cough medications



### Solr search

http://<solraddress>:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:antiussive~&rows=3

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



One route, in unoptimized SPARQL, for finding medication orders that include an ingredient with an **antitussive role**, according to ChEBI:



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



The same query can be easily modified to look for orders including a known **anittussive ingredient** (via a ChEBI IRI like  [Codeine, CHEBI:16714](http://purl.obolibrary.org/obo/CHEBI_16714)



*what about macrolides?*

## User is interested in patients with orders for drugs in the "barbiturates" class



http://<solraddress>:8983/solr/med_mapping_kb_labels/select?fl=mediri,labelpred,medlabel,score&q=medlabel:(barbiturate%20antibiotic~)&rows=3

```json
{
  "responseHeader":{
    "status":0,
    "QTime":7,
    "params":{
      "q":"medlabel:(barbiturate~)",
      "fl":"mediri,labelpred,medlabel,score",
      "rows":"3"}},
  "response":{"numFound":22,"start":0,"maxScore":16.18434,"docs":[
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_29745"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["barbiturate"],
        "score":16.18434},
      {
        "mediri":["http://purl.bioontology.org/ontology/NDFRT/N0000175693"],
        "labelpred":["http://www.w3.org/2004/02/skos/core#altLabel"],
        "medlabel":["barbiturate"],
        "score":16.18434},
      {
        "mediri":["http://purl.obolibrary.org/obo/CHEBI_22693"],
        "labelpred":["http://www.w3.org/2000/01/rdf-schema#label"],
        "medlabel":["barbiturates"],
        "score":14.713037}]
  }}
```



```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
select 
distinct ?source_med_id ?prob_more_distant ?match_rxcui ?bioportal_mapping ?dron_chebi_ing ?drugclass
where {
    values ?drugclass {
        <http://purl.obolibrary.org/obo/CHEBI_22693>
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