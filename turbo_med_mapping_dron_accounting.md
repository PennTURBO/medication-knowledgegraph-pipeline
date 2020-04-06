

## What DrOn terms could be replaced by a ChEBI term

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
distinct ?dronterm ?dl ?chebiterm ?cl ?ci_identical
where {
    graph mydata:bioportal_mappings {
        ?dronterm mydata:bioportal_mapping ?chebiterm .
    }
    #    better (faster?) as union? acceptable either way in this case
    # can also check the graph in which a thing has its type (owl:Class?) asserted
    values ?drongraph {
        <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl>
        <http://purl.obolibrary.org/obo/dron/dron-hand.owl>
    }
    graph mydata:defined_in {
        ?dronterm mydata:defined_in ?drongraph .
    }
    graph mydata:defined_in {
        ?chebiterm mydata:defined_in obo:chebi.owl .
    }
    minus {
        ?dronterm mydata:defined_in obo:chebi.owl .
    }
    graph obo:chebi.owl {
        ?chebiterm rdfs:label ?cl .
    }
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?dronterm rdfs:label ?dl .
    }
    bind((lcase(str( ?dl))) = (lcase(str( ?cl))) as ?ci_identical)
}
order by ?ci_identical ?dl ?cl
```

> Showing results from 1,001 to 1,681 of **1,681**. Query took 0.8s, minutes ago.



## What's the breakdown of DrOn ingredient term sources?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select ?chebient ?dronent (count(distinct ?s) as ?count) 
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
    }
    filter(isiri(?s))
    bind(contains(str(?s), "CHEBI") as ?chebient)
    bind(contains(str(?s), "DRON") as ?dronent)
}
group by ?chebient ?dronent
```

> Showing results from 1 to 2 of 2. Query took 1.6s, minutes ago.



| **chebient** | **dronent** | **count** |
| ------------ | ----------- | --------: |
| true         | false       |       795 |
| false        | true        |      5246 |

## How many DrOn-native ingredient terms don't have a ChEBI mapping?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
?chebimapped (count(distinct ?s ) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    optional {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(bound( ?mappedterm ) as ?chebimapped)
}
group by ?chebimapped
```

> Showing results from 1 to 2 of 2. Query took 4.3s, minutes ago.



| **chebimapped** | **count** |
| --------------- | --------: |
| true            |      1677 |
| false           |      3569 |

### Oops, make sure they're active ingredients

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
?chebimapped (count(distinct ?s ) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
        ?x1 rdf:rest rdf:nil ;
            rdf:first ?r .
        ?x2 rdf:rest ?x1 ;
            rdf:first ?x3 .
        ?x3 a owl:Restriction ;
            owl:someValuesFrom obo:DRON_00000028 ;
            owl:onProperty obo:BFO_0000053 .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    optional {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(bound( ?mappedterm ) as ?chebimapped)
}
group by ?chebimapped
```

> Showing results from 1 to 2 of 2. Query took 4.4s, minutes ago.



| **chebimapped** | **count** |
| --------------- | --------: |
| true            |      1546 |
| false           |      2531 |

## What are the DrOn-native active ingredient terms that lack ChEBI mappings?

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
distinct ?s ?l ?lcl
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:someValuesFrom ?s ;
           owl:onProperty obo:BFO_0000071 .
        ?s rdfs:label ?l .
        ?x1 rdf:rest rdf:nil ;
            rdf:first ?r .
        ?x2 rdf:rest ?x1 ;
            rdf:first ?x3 .
        ?x3 a owl:Restriction ;
            owl:someValuesFrom obo:DRON_00000028 ;
            owl:onProperty obo:BFO_0000053 .
    }
    filter(isiri(?s))
    filter(contains(str(?s), "DRON"))
    minus {
        graph mydata:bioportal_mappings {
            ?s mydata:bioportal_mapping ?mappedterm .
        }
        graph mydata:defined_in {
            ?mappedterm mydata:defined_in obo:chebi.owl .
        }
    }
    bind(lcase(str(?l)) as ?lcl)
}
order by ?lcl
```

> Showing results from 1 to 1,000 of 2,531. Query took 2.5s, minutes ago.

### Common words in unmapped terms

| **count** | **dron_term_word** |
| --------: | ------------------ |
|       785 | extract            |
|       348 | allergenic         |
|       240 | pollen             |
|       129 | vaccine            |
|        85 | preparation        |
|        56 | virus              |
|        54 | a                  |
|        52 | protein            |
|        46 | human              |
|        43 | capsular           |

-----

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

> Showing results from 1 to 2 of 2. Query took 2.2s, minutes ago.

| **active** | **count** |
| ---------- | --------: |
| true       |     42108 |
| false      |     50066 |

## Should also check if some DrOn entries have more than one RxCUI assertion

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

> Showing results from 1 to 3 of 3. Query took 5.1s, moments ago.



### Could this be explained by many DrOn terms taking multiple RxCUIs? Some old and some current?

| rxcui_count | dronents |
| ----------- | -------: |
| 3           |        1 |
| 2           |        6 |
| 1           |    92167 |

