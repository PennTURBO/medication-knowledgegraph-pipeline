## General Graph/Ontology accounting



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



| **g**                                                        | **count** |
| ------------------------------------------------------------ | --------: |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |    636232 |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |    502504 |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) |    138159 |
| [mydata:cui](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcui) |    136044 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |    113234 |
| [obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) |     86926 |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |     36202 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) |     35165 |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) |      6362 |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |      2553 |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) |       606 |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) |       181 |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |         4 |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |         1 |



| **g**                                                        | **count** |
| ------------------------------------------------------------ | --------: |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) |      6362 |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) |       606 |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |    502504 |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) |       181 |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |      2553 |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) |    138159 |
| [mydata:cui](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcui) |    136044 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) |     35165 |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |         4 |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |     36202 |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |    636232 |
| **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)** | **86926** |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |         1 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |    113234 |



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



| **o**                                                        | **count** |
| ------------------------------------------------------------ | --------: |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) |    138158 |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |    134657 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |    113234 |
| [obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) |     86151 |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |     43705 |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |     36202 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) |     35164 |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) |      6362 |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |      1706 |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) |       161 |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) |       112 |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |         4 |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |         1 |



| **o**                                                        | **count** |
| ------------------------------------------------------------ | --------: |
| [atc:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FATC%2F) |      6362 |
| [dron:dron-hand.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) |       161 |
| [dron:dron-ingredient.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |     43705 |
| [dron:dron-upper.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) |       112 |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://pennturbo.org:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |      1706 |
| [mydata:classified_search_results](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fclassified_search_results) |    138158 |
| [mydata:reference_medications](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) |     35164 |
| [mydata:turbo_med_mapping_hand](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fturbo_med_mapping_hand) |         4 |
| [ndfrt:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FNDFRT%2F) |     36202 |
| [obo:chebi.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |    134657 |
| **[obo:dron-rxnorm.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl)** | **86151** |
| [obo:dron.owl](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron.owl) |         1 |
| [rxnorm:](http://pennturbo.org:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) |    113234 |



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


## 