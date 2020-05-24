## New but not necessarily complete


- [x] what's the distribution of ranks & scores for accepted classifications. (Final, in graph).
  - requires classified search results to still be present! could always load back in from ttl file.
    - analyze categoricals with tables
    - mydata:match_rank
    - mydata:match_sab
    - mydata:match_tty
      - that's the TTY of the string match, not the TTY of the RxCUI that bears the string as a label
    - mydata:override_classification
    - mydata:rf_classification

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select 
?p ?monitored (count(distinct ?sourcemed ) as ?count)
where {
    graph mydata:elected_mapping {
        ?sourcemed mydata:elected_mapping ?matchrxn .
    }
    graph mydata:defined_in {
        ?sourcemed mydata:defined_in mydata:reference_medications .
        ?matchrxn mydata:defined_in rxnorm:
    }
    graph mydata:classified_search_results {
        values ?p { mydata:match_rank }
        ?class_search_res mydata:source_id_uri ?sourcemed ;
                          mydata:match_rxcui ?matchrxn ;
                          ?p ?monitored .
    }
}
group by ?p ?monitored 
order by desc (count(distinct ?sourcemed ))
```

  - analyze continuous variables with a histogram or something similar
    - mydata:match_score
    - mydata:prob_identical
    - mydata:prob_more_distant

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select 
?monitored
where {
    graph mydata:elected_mapping {
        ?sourcemed mydata:elected_mapping ?matchrxn .
    }
    graph mydata:defined_in {
        ?sourcemed mydata:defined_in mydata:reference_medications .
        ?matchrxn mydata:defined_in rxnorm:
    }
    graph mydata:classified_search_results {
        values ?p { mydata:match_score }
        ?class_search_res mydata:source_id_uri ?sourcemed ;
                          mydata:match_rxcui ?matchrxn ;
                          ?p ?monitored .
    }
}
```

- [x] what's the distribution of match RxCUI employments?

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
?employment (count(distinct ?sourcemed ) as ?count)
where {
    graph mydata:elected_mapping {
        ?sourcemed mydata:elected_mapping ?matchrxn .
    }
    graph mydata:defined_in {
        ?sourcemed mydata:defined_in mydata:reference_medications .
        ?matchrxn mydata:defined_in rxnorm:
    }
    graph mydata:employment {
        ?matchrxn mydata:employment ?employment .
    }
}
group by ?employment
order by desc (count(distinct ?sourcemed ))
```

