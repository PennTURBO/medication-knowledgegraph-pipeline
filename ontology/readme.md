The Turbo Medication Mapper (TMM) Ontology documents the Turbo Medication Mapper software and provides knowledge relevant for querying and validating the output (an RDF repository) and a corresponding Solr collection. We currently use the TMM ontology in production for two functions:

**1) Validating a Solr collection**

The query below can be run against the TMM ontology to retrieve a list of example Solr search terms and the corresponding results that should be present in the list returned by the Solr service. This information is helpful for ensuring that a given Solr collection will be sufficient for use alongside a Medication Knowledge Graph produced by TMM. Note that in both the "keywords" and "expected" variables, results may be returned as pipe-delimited lists.

```
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
?solrQueryExample (group_CONCAT(distinct ?solrKeyword;
        SEPARATOR="|") as ?keywords) (group_CONCAT(distinct str( ?expectedSolrResult) ;
        SEPARATOR="|") as ?expected)
where {
    ?solrQueryExample a <http://transformunify.org/ontologies/TURBO_0022059> ;
                      rdfs:seeAlso ?applicable_emp ;
                      rdfs:label ?qlab ;
                      <http://transformunify.org/ontologies/TURBO_0022062> ?solrKeyword ;
                      <http://transformunify.org/ontologies/TURBO_0022061> ?expectedSolrResult .
    ?applicable_emp a ?t .
    optional {
        ?applicable_emp rdfs:label ?apemplab .
    }
    ?t rdfs:subClassOf <http://transformunify.org/ontologies/TURBO_0022023> .
}
group by ?solrQueryExample
```

**2) Selecting queries based on employment**

The query below can be run against the TMM ontology to retrieve a list of employments of medication terms and the corresponding query that can be used to retrieve results for that employment against a Medication Knowledge Graph. A Solr instance that returns employment as a string that matches the strings present in the "notation" variable of this query should be used. Then the proper knowledge graph query can be selected based on the employment string returned from Solr and the results of this query.

```
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select
?notation ?employment ?query
where {
        ?SPARQL a <http://transformunify.org/ontologies/TURBO_0022058> ;
           <http://purl.org/dc/dcam/domainIncludes> ?employment ;
           <http://transformunify.org/ontologies/TURBO_0022020> ?query .
        ?employment skos:notation ?notation
}
```
           
