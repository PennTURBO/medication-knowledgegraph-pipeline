```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
select
#*
?source (count(distinct ?s) as ?count)
where {
    values ?x {
        oboInOwl:hasRelatedSynonym oboInOwl:hasExactSynonym
    }
    # also oboInOwl:hasDbXref as an annotated property (in addition to a source-attributing predicate)
    ?s a owl:Axiom ;
       ?ap ?ao ;
       owl:annotatedProperty ?x ;
       oboInOwl:hasDbXref ?source .
} 
group by ?source
order by desc(count(distinct ?s))
```
