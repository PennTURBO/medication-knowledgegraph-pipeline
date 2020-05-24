## How can we tag entities in the TURBO medication mapping graph based on their employment, or the way that they participate in paths?



### 'Ingredients' & 'Products' according to DrOn

*DrOn RxCUI assertions may be outdated up to 50% of the time*

might be useful to think about

- does it have a mass? multiple predicates..
- does it have a formula
- does it bear or inherit some role? from what parent role?

DrOn asserts ingredient relationships with OWL expressions like

**Cisplatin Injectable Solution**, Term IRI: http://purl.obolibrary.org/obo/DRON_00025299

subClassOf 

- [drug solution](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00000020)
- [has_proper_part](http://www.ontobee.org/ontology/DRON?iri=http://www.obofoundry.org/ro/ro.owl%23has_proper_part) some ([scattered molecular aggregate](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/OBI_0000576) and ([is bearer of](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000053) some [active ingredient](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00000028)) and ([has granular part](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000071) some [Cisplatin](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/CHEBI_27899))

Which can be discovered with SPARQL like

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
?dron_prod ?acting 
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?dron_prod rdfs:subClassOf ?r .
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting_intersection .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting_intersection rdf:first ?acting_first ;
                             rdf:rest rdf:nil .
        ?acting_first  a owl:Restriction ;
                       owl:onProperty obo:BFO_0000071 ;
                       owl:someValuesFrom ?acting .
    }
}
```



### Product hierarchies look like this

**has_RxCUI:** 376433

Thing

- entity
  - continuant
    - independent continuant
      - material entity
        - object
          - portion of mixture
            - portion of solution
              - \+ [drug solution](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00000020)

The things acting as ingredients might come from ChEBI or from DrOn native terms.

**Cisplatin**, Term IRI: http://purl.obolibrary.org/obo/CHEBI_27899

Thing

- entity
  - continuant
    - independent continuant
      - material entity
        - chemical entity
          - molecular entity
            - \+ [polyatomic entity](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/CHEBI_36357)

*Etc.!*

**Rosuvastatin calcium 20 MG Oral Tablet [Crestor]**, Term IRI: http://purl.obolibrary.org/obo/DRON_00081389

- **has_RxCUI:** 859753

Class Hierarchy

- Thing
  - entity
    - continuant
      - independent continuant
        - material entity
          - object
            - drug tablet
              - rosuvastatin Oral Tablet
                - Rosuvastatin calcium 20 MG Oral Tablet
                  - \- [Rosuvastatin calcium 20 MG Oral Tablet [Crestor\]](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00081389)

**rosuvastatin Oral Tablet**, Term IRI: http://purl.obolibrary.org/obo/DRON_00027869

[has_proper_part](http://www.ontobee.org/ontology/DRON?iri=http://www.obofoundry.org/ro/ro.owl%23has_proper_part) some ([scattered molecular aggregate](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/OBI_0000576) and ([is bearer of](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000053) some [active ingredient](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00000028)) and ([has granular part](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000071) some [rosuvastatin](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00018679)))

**Rosuvastatin calcium 20 MG Oral Tablet**, Term IRI: http://purl.obolibrary.org/obo/DRON_00059154

- **has_RxCUI:** 859751

- [has_proper_part](http://www.ontobee.org/ontology/DRON?iri=http://www.obofoundry.org/ro/ro.owl%23has_proper_part) some ([scattered molecular aggregate](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/OBI_0000576) and ([is bearer of](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000053) some [active ingredient](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00000028)) and ([is bearer of](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000053) some ([mass](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/PATO_0000125) and ([has measurement unit label](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/IAO_0000039) value [milligram](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/UO_0000022)) and ([has specified value](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/OBI_0001937) value ))) and ([has granular part](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/BFO_0000071) some [rosuvastatin](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/DRON_00018679)))

**rosuvastatin**, Term IRI: http://purl.obolibrary.org/obo/DRON_00018679

- **has_RxCUI:** 301542

Thing

- entity
  - continuant
    - independent continuant
      - material entity
        - \+ [processed material](http://www.ontobee.org/ontology/DRON?iri=http://purl.obolibrary.org/obo/OBI_0000047)

## Worked discovery task

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
#*
?g (count(distinct ?r) as ?count)
where {
    graph ?g {
        ?r a owl:Restriction ;
           owl:onProperty ?op ;
           owl:someValuesFrom ?valsource .
    }
}
group by ?g
```



>  Showing results from 1 to 6 of 6. Query took 1.6s, moments ago.



| **g**                                                        | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | 41     |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 302    |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | 520    |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | 775    |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 81459  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 301585 |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
#*
?op (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ?op ;
           owl:someValuesFrom ?valsource .
    }
}
group by ?op
```



> Showing results from 1 to 3 of 3. Query took 1.2s, moments ago.



| **op**                                                       | **count**             |
| ------------------------------------------------------------ | --------------------: |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  (IBO) | 114885 |
| [ro:has_proper_part](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.obofoundry.org%2Fro%2Fro.owl%23has_proper_part) | 93350  |
| [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071)  (HGP) | 93350  |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
?first_blank ?rest_blank (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first ?hpp_first ;
                          rdf:rest ?hpp_rest .
        bind(isblank( ?hpp_first ) as ?first_blank)
        bind(isblank( ?hpp_rest ) as ?rest_blank)
    }
}
group by ?first_blank ?rest_blank
```



> Showing results from 1 to 1 of 1. Query took 1s, moments ago.

All `rdf:rest`s blank, no `rdf:first`s blank (all [obo:OBI_0000576](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FOBI_0000576))



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
?sma_intersection_first_op ?sma_intersection_first_valsource (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                          rdf:rest ?sma_intersection_rest .
        ?sma_intersection_first a owl:Restriction ;
           owl:onProperty ?sma_intersection_first_op ;
           owl:someValuesFrom ?sma_intersection_first_valsource .
    }
}
group by ?sma_intersection_first_op ?sma_intersection_first_valsource
```



> Showing results from 1 to 2 of 2. Query took 1.5s, moments ago.



| **sma_intersection_first_op**                                | **sma_intersection_first_valsource**                         | **count**            |
| ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------: |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  HRole | [obo:DRON_00000028](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FDRON_00000028)  (HAI) | 48786 |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) | [obo:DRON_00000029](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FDRON_00000029)  (HExcip) | 44564 |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
?first_nil ?rest_nil (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting   rdf:first ?acting_first ;
                  rdf:rest ?acting_rest .
        bind((?acting_first = rdf:nil ) as ?first_nil)
        bind((?acting_rest  = rdf:nil ) as ?rest_nil)
    }
}
group by ?first_nil ?rest_nil
```



> Showing results from 1 to 2 of 2. Query took 2.2s, moments ago.



| **first_nil**        | **rest_nil**         | **count**            |
| -------------------- | -------------------- | -------------------: |
| false | true  | 27498 |
| false | false | 21288 |



`false`/`false` when the dosage is known?

When defined, `?acting_rest_rest_op` is always `obo:BFO_0000071`, has granular part



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
?acting_first_op  (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting   rdf:first ?acting_first ;
                  rdf:rest ?acting_rest .
        ?acting_first  a owl:Restriction ;
                       owl:onProperty ?acting_first_op ;
                       owl:someValuesFrom ?acting_first_valsource .
        optional {
            ?acting_rest  rdf:first ?acting_rest_rest .
            ?acting_rest_rest  a owl:Restriction ;
                               owl:onProperty ?acting_rest_rest_op ;
                               owl:someValuesFrom ?acting_rest_rest_valsource .
        }
    }
}
group by ?acting_first_op
```

> Showing results from 1 to 2 of 2. Query took 6.2s, moments ago.

| **acting_first_op**                                          | **count**            |
| ------------------------------------------------------------ | -------------------: |
| [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071)  HGP | 27498 |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  HRole | 21288 |



If `?acting_first_op` is `obo:BFO_0000071`, then there is no `?acting_rest_rest` at all

~~Multiple active ingredients?~~ **Mass/dosage modeling?**

If `?acting_first_op` is `obo:BFO_0000053`, then the value source is an intersection. The first part of the intersection is always `obo:PATO_0000125`, 'mass'

In those cases, shouldn't there be a parent, massless class? So just pursue `?acting_first_op` = `obo:BFO_0000071` case?



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
?g ?t (count(distinct ?acting) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting_intersection .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting_intersection rdf:first ?acting_first ;
                             rdf:rest rdf:nil .
        ?acting_first  a owl:Restriction ;
                       owl:onProperty obo:BFO_0000071 ;
                       owl:someValuesFrom ?acting .
    }
    graph ?g {
        ?acting a ?t .
    }
}
group by ?g ?t
```



> Showing results from 1 to 4 of 4. Query took 1.7s, moments ago.

| **g**                                                        | **t**                                                        | **count**           |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------: |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | 4872 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | 795  |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | 52   |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | 3    |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
?defining_graph (count(distinct ?acting) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting_intersection .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting_intersection rdf:first ?acting_first ;
                             rdf:rest rdf:nil .
        ?acting_first  a owl:Restriction ;
                       owl:onProperty obo:BFO_0000071 ;
                       owl:someValuesFrom ?acting .
    }
    {
        graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> as ?defining_graph)
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/chebi.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/chebi.owl> as ?defining_graph)
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/dron/dron-hand.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-hand.owl> as ?defining_graph)
        } 
    }  
}
group by ?defining_graph
```

> Showing results from 1 to 3 of 3. Query took 11s, moments ago.



| **defining_graph**                                           | **count**           |
| ------------------------------------------------------------ | ------------------: |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 4872 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 795  |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 52   |



#### Now materialize that!

- Anything that's an `rdfs:subClassOf*` an (active, DrOn/ChEBI) ingredient as tagged above is an ingredient
- Anything that's an `rdfs:subClassOf*`  a DrOn product as tagged above is a product
  - distinguish brand from generic?
- Include defining graph context? As an `owl:Axiom`?



**Don't forget to add it to R script `med_mapping_load_materialize_project.R` (?)**



## Ingredient count reality check



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
?acting_count (count(distinct ?dron_prod) as ?prod_count)
where 
{
    {
        select 
        ?dron_prod (count(distinct ?acting) as ?acting_count)
        where {
            graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
                ?dron_prod rdfs:subClassOf ?r .
                ?r a owl:Restriction ;
                   owl:onProperty ro:has_proper_part ;
                   owl:someValuesFrom ?hpp_valsource .
                ?hpp_valsource owl:intersectionOf ?hpp_intersection .
                ?hpp_intersection rdf:first obo:OBI_0000576 ;
                                  rdf:rest ?sma_intersection .
                ?sma_intersection  rdf:first ?sma_intersection_first ;
                                   rdf:rest ?acting_intersection .
                ?sma_intersection_first a owl:Restriction ;
                                        owl:onProperty obo:BFO_0000053 ;
                                        owl:someValuesFrom obo:DRON_00000028 .
                ?acting_intersection rdf:first ?acting_first ;
                                     rdf:rest rdf:nil .
                ?acting_first  a owl:Restriction ;
                               owl:onProperty obo:BFO_0000071 ;
                               owl:someValuesFrom ?acting .
            }
        }
        group by ?dron_prod
    }
}
group by ?acting_count 
order by asc (?acting_count)
```

> Showing results from 1 to 23 of 23. Query took 2.7s, moments ago.

| **acting_count**  | **prod_count**       |
| ----------------- | -------------------: |
| 1  | 10788 |
| 2  | 4290  |
| 3  | 1462  |
| 4  | 398   |
| 5  | 88    |
| 6  | 35    |
| 7  | 18    |
| 8  | 9     |
| 9  | 11    |
| 10 | 9     |
| 11 | 7     |
| 12 | 3     |
| 13 | 9     |
| 14 | 7     |
| 15 | 12    |
| 16 | 11    |
| 17 | 2     |
| 18 | 6     |
| 19 | 5     |
| 20 | 2     |
| 21 | 2     |
| 22 | 3     |
| 23 | 2     |



----



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX mydata: <http://example.com/resource/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
insert {
    graph mydata:employment {
        ?dronprod mydata:employment mydata:product .
        #        ?prod_annotation_axiom a owl:Axiom ;
        #                               owl:annotatedSource ?dronprod ;
        #                               owl:annotatedProperty mydata:employment ;
        #                               owl:annotatedTarget mydata:product ;
        #                               oboInOwl:hasDbXref ?defining_graph .
        ?subacting mydata:employment mydata:active_ingredient .
#        ?acting_annotation_axiom a owl:Axiom ;
#                                 owl:annotatedSource ?subacting ;
#                                 owl:annotatedProperty mydata:employment ;
#                                 owl:annotatedTarget mydata:active_ingredient ;
#                                 oboInOwl:hasDbXref ?acting_defining_graph .
    }
}
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        ?hpp_valsource owl:intersectionOf ?hpp_intersection .
        ?hpp_intersection rdf:first obo:OBI_0000576 ;
                          rdf:rest ?sma_intersection .
        ?sma_intersection  rdf:first ?sma_intersection_first ;
                           rdf:rest ?acting_intersection .
        ?sma_intersection_first a owl:Restriction ;
                                owl:onProperty obo:BFO_0000053 ;
                                owl:someValuesFrom obo:DRON_00000028 .
        ?acting_intersection rdf:first ?acting_first ;
                             rdf:rest rdf:nil .
        ?acting_first  a owl:Restriction ;
                       owl:onProperty obo:BFO_0000071 ;
                       owl:someValuesFrom ?acting .
    }
    {
        graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> as ?acting_defining_graph)
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/chebi.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/chebi.owl> as ?acting_defining_graph)
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/dron/dron-hand.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-hand.owl> as ?acting_defining_graph)
        } 
    }  
    ?dronprod rdfs:subClassOf* ?r .
    ?subacting rdfs:subClassOf* ?acting .
    # bind(uuid() as ?prod_annotation_axiom )    
    # bind(uuid() as ?acting_annotation_axiom )
}
```

> Added 118037 statements. Update took 1m 30s, minutes ago.



### Update Notes

- `owl:Axiom`s are asserted for each appearance of an active ingredient in a product. Do we need to assert the graph in which we determined that something was a product or ingredient? We already have `defined_in` triples?
- Product `employment` tag doesn't distinguish between brand and generic. RxNorm TTYs do.

- Nothing for RxNorm yet. Intentionally holding off on NDF-RT and A.TC




```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select 
#* 
?t (count(distinct ?acting) as ?count)
where {
    graph mydata:employment {
        ?acting mydata:employment mydata:active_ingredient .
    }
    graph mydata:bioportal_mappings {
        ?acting mydata:bioportal_mapping ?mappee .
    }
    graph mydata:defined_in {
        ?mappee mydata:defined_in rxnorm:
    }
    graph <http://example.com/resource/rxn_tty/> {
        ?mappee a ?t
    }
}
group by ?t
```

> Showing results from 1 to 2 of 2. Query took 0.1s, moments ago.

*Maybe shouldn't be using `ref:type` and my data:employment... just pick one?*

| **t**                                                        | **count**           |
| ------------------------------------------------------------ | ------------------: |
| [mydata:rxn_tty/IN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FIN) | 4550 |
| [mydata:rxn_tty/PIN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FPIN) | 58   |

**Nice!**

Similar table for ```mydata:employment mydata:product```

> Showing results from 1 to 3 of 3. Query took 0.5s, moments ago.

| **t**                                                        | **count**            |
| ------------------------------------------------------------ | -------------------: |
| [mydata:rxn_tty/SCD](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCD) | 17856 |
| [mydata:rxn_tty/SCDF](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCDF) | 7774  |
| [mydata:rxn_tty/SBD](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSBD) | 4721  |



### Review: what RxNorm term types are mentioned in PDS orders?



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select 
#* 
?rxnt (count(distinct ?s) as ?count)
where {
    graph mydata:reference_medications {
        ?s rdf:type obo:PDRO_0000024  
    }
    graph mydata:defined_in
    {
        ?s mydata:defined_in mydata:reference_medications .
    }
    graph mydata:elected_mapping {
        ?s mydata:elected_mapping ?rxn_anything .
    }
    graph mydata:defined_in
    {
        ?rxn_anything mydata:defined_in rxnorm: .
    }
    graph <http://example.com/resource/rxn_tty/> {
        ?rxn_anything a ?rxnt
    }
}
group by ?rxnt 
order by desc (count(distinct ?s))
```

> Showing results from 1 to 14 of 14. Query took 0.7s, minutes ago.

| **rxnt**                                                     | **count**            |
| ------------------------------------------------------------ | -------------------: |
| [mydata:rxn_tty/SCD](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCD) | 24029 |
| [mydata:rxn_tty/SBD](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSBD) | 8808  |
| [mydata:rxn_tty/IN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FIN) | 8454  |
| [mydata:rxn_tty/SCDF](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCDF) | 3449  |
| [mydata:rxn_tty/PIN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FPIN) | 2294  |
| [mydata:rxn_tty/SBDF](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSBDF) | 2104  |
| [mydata:rxn_tty/BN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FBN) | 1676  |
| [mydata:rxn_tty/SCDC](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCDC) | 1314  |
| [mydata:rxn_tty/MIN](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FMIN) | 1273  |
| [mydata:rxn_tty/SBDC](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSBDC) | 753   |
| [mydata:rxn_tty/BPCK](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FBPCK) | 439   |
| [mydata:rxn_tty/GPCK](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FGPCK) | 165   |
| [mydata:rxn_tty/SCDG](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSCDG) | 158   |
| [mydata:rxn_tty/SBDG](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Frxn_tty%2FSBDG) | 1     |



## What roles are borne by the ChEBI ingredients?

### What predicates are present in ChEBI restrictions on ingredients?

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
#* 
?op (count(distinct ?r) as ?count)
where {
    graph mydata:employment {
        ?s mydata:employment mydata:active_ingredient .
    }
    graph mydata:defined_in {
        ?s mydata:defined_in obo:chebi.owl .
    }
    graph obo:chebi.owl {
        ?s rdfs:subClassOf ?r .
        ?r a owl:Restriction ;
           owl:onProperty ?op ;
           owl:someValuesFrom ?valsource .
    }
}
group by ?op 
order by desc(count(distinct ?r))
```

> Showing results from 1 to 8 of 8. Query took 0.6s, minutes ago.

|                              op                              |        count        |
| :----------------------------------------------------------: | :-----------------: |
| [obo:RO_0000087](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0000087) | 3038 |
| [obo:chebi#has_functional_parent](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23has_functional_parent) | 260  |
| [obo:chebi#is_conjugate_acid_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_conjugate_acid_of) | 182  |
| [obo:chebi#is_conjugate_base_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_conjugate_base_of) | 158  |
| [obo:chebi#is_enantiomer_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_enantiomer_of) | 145  |
| [obo:BFO_0000051](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000051) | 126  |
| [obo:chebi#has_parent_hydride](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23has_parent_hydride) | 62  |
| [obo:chebi#is_tautomer_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_tautomer_of) | 39  |



***Currently ignoring all of those relationships besides `obo:RO_0000087`,  "has role"***

ChEBI synonym type and authority assertions? 

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
select 
?annsource ?l ?annprop ?dbxr ?syntype ?anntarg 
where {
    graph obo:chebi.owl {
        values ?anntarg {
            "Tylenol" 
        }
        ?restr a owl:Axiom ;
               owl:annotatedTarget ?anntarg ;
               owl:annotatedSource ?annsource ;
               owl:annotatedProperty ?annprop ;
               oboInOwl:hasDbXref ?dbxr ;
               oboInOwl:hasSynonymType ?syntype .
        ?annsource rdfs:label ?l .
    }
}
```



> Showing results from 1 to 1 of 1. Query took 0.1s, minutes ago.

|                          annsource                           |      l      |                           annprop                            |   dbxr    |                           syntype                            | anntarg |
| :----------------------------------------------------------: | :---------: | :----------------------------------------------------------: | :-------: | :----------------------------------------------------------: | :-----: |
| [obo:CHEBI_46195](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_46195) | paracetamol | [oboInOwl:hasRelatedSynonym](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasRelatedSynonym) | KEGG_DRUG | [obo:chebi#BRAND_NAME](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23BRAND_NAME) | Tylenol |

### Direct role assignments



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
#* 
?valsource ?rolelab (count(distinct ?s) as ?count)
where {
    graph mydata:employment {
        ?s mydata:employment mydata:active_ingredient .
    }
    graph mydata:defined_in {
        ?s mydata:defined_in obo:chebi.owl .
    }
    graph obo:chebi.owl {
        ?s rdfs:subClassOf ?r ;
           rdfs:label ?inglab .
        ?r a owl:Restriction ;
           owl:onProperty obo:RO_0000087 ;
           owl:someValuesFrom ?valsource .
        ?valsource rdfs:label ?rolelab .
    }
}
group by ?valsource ?rolelab
order by desc(count(distinct ?s))
```

Showing results from 1 to 509 of 509. Query took 0.3s, minutes ago.

|                          valsource                           |               rolelab               |       count        |
| :----------------------------------------------------------: | :---------------------------------: | :----------------: |
| [obo:CHEBI_75771](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_75771) |          mouse metabolite           | 119 |
| [obo:CHEBI_76971](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_76971) |     Escherichia coli metabolite     | 97  |
| [obo:CHEBI_77746](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_77746) |          human metabolite           | 96  |
| [obo:CHEBI_75772](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_75772) | Saccharomyces cerevisiae metabolite | 88  |
| [obo:CHEBI_35703](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_35703) |             xenobiotic              | 85  |
| [obo:CHEBI_78298](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_78298) |      environmental contaminant      | 80  |
| [obo:CHEBI_35610](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_35610) |        antineoplastic agent         | 76  |
| [obo:CHEBI_76924](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_76924) |          plant metabolite           | 55  |
| [obo:CHEBI_36047](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_36047) |         antibacterial drug          | 50  |
| [obo:CHEBI_88188](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_88188) |            drug allergen            | 49  |

#### Signal to noise isn't that great

*Include parent roles and then work down from there.*

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
#* 
?superrole ?superlab (count(distinct ?s) as ?count)
where {
    graph mydata:employment {
        ?s mydata:employment mydata:active_ingredient .
    }
    graph mydata:defined_in {
        ?s mydata:defined_in obo:chebi.owl .
    }
    graph obo:chebi.owl {
        ?s rdfs:subClassOf ?r ;
           rdfs:label ?inglab .
        ?r a owl:Restriction ;
           owl:onProperty obo:RO_0000087 ;
           owl:someValuesFrom ?valsource .
        ?valsource rdfs:label ?rolelab .
        ?valsource rdfs:subClassOf* ?superrole .
        ?superrole rdfs:label ?superlab .
    }
}
group by ?superrole ?superlab
order by desc (count(distinct ?s))
```

Showing results from 1 to 690 of 690. Query took 3.2s, minutes ago.

See `parent_roles_of_chebi_actings.csv`

Merge in background role bearer count.

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
#* 
?supersource ?l (count(distinct ?s2) as ?count2)
where {
    graph obo:chebi.owl {
        ?r2 a owl:Restriction ;
            owl:onProperty obo:RO_0000087 ;
            owl:someValuesFrom ?valsource .
        ?s2 rdfs:subClassOf ?r2 .
        ?valsource rdfs:subClassOf* ?supersource .
        ?supersource rdfs:label ?l .
    }
}
group by ?supersource ?l
#order by desc (count(distinct ?s))
```

Add direct role assignments from above back in

`parent_roles_of_chebi_actings.csv` is an aggregated, curated report.

Here's a way to find some relevant subroles from the hand-curated superroles found on active ingredients:



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
distinct ?role ?rolelab
where {
    values ?valsource  {
        obo:CHEBI_130181 obo:CHEBI_131699 obo:CHEBI_131770 obo:CHEBI_131787 obo:CHEBI_139503 obo:CHEBI_22333 obo:CHEBI_22586 obo:CHEBI_23018 obo:CHEBI_23354 obo:CHEBI_23357 obo:CHEBI_23366 obo:CHEBI_23888 obo:CHEBI_24020 obo:CHEBI_24621 obo:CHEBI_24869 obo:CHEBI_25435 obo:CHEBI_25491 obo:CHEBI_25728 obo:CHEBI_27026 obo:CHEBI_27314 obo:CHEBI_33229 obo:CHEBI_33280 obo:CHEBI_35195 obo:CHEBI_35221 obo:CHEBI_35522 obo:CHEBI_35530 obo:CHEBI_35544 obo:CHEBI_35569 obo:CHEBI_35660 obo:CHEBI_35856 obo:CHEBI_35941 obo:CHEBI_36413 obo:CHEBI_37153 obo:CHEBI_37670 obo:CHEBI_37699 obo:CHEBI_37700 obo:CHEBI_37733 obo:CHEBI_37886 obo:CHEBI_37887 obo:CHEBI_37890 obo:CHEBI_37955 obo:CHEBI_37956 obo:CHEBI_37961 obo:CHEBI_38157 obo:CHEBI_38161 obo:CHEBI_38215 obo:CHEBI_38234 obo:CHEBI_38324 obo:CHEBI_38325 obo:CHEBI_38462 obo:CHEBI_38623 obo:CHEBI_38632 obo:CHEBI_38633 obo:CHEBI_38637 obo:CHEBI_38706 obo:CHEBI_38808 obo:CHEBI_38809 obo:CHEBI_39000 obo:CHEBI_47958 obo:CHEBI_48001 obo:CHEBI_48279 obo:CHEBI_48561 obo:CHEBI_48578 obo:CHEBI_48873 obo:CHEBI_48876 obo:CHEBI_48878 obo:CHEBI_49020 obo:CHEBI_49103 obo:CHEBI_49159 obo:CHEBI_49200 obo:CHEBI_50103 obo:CHEBI_50112 obo:CHEBI_50113 obo:CHEBI_50114 obo:CHEBI_50137 obo:CHEBI_50183 obo:CHEBI_50188 obo:CHEBI_50218 obo:CHEBI_50276 obo:CHEBI_50390 obo:CHEBI_50502 obo:CHEBI_50509 obo:CHEBI_50510 obo:CHEBI_50566 obo:CHEBI_50568 obo:CHEBI_50629 obo:CHEBI_50630 obo:CHEBI_50683 obo:CHEBI_50696 obo:CHEBI_50745 obo:CHEBI_50750 obo:CHEBI_50781 obo:CHEBI_50790 obo:CHEBI_50837 obo:CHEBI_50844 obo:CHEBI_50902 obo:CHEBI_50904 obo:CHEBI_50905 obo:CHEBI_50908 obo:CHEBI_50910 obo:CHEBI_51060 obo:CHEBI_51065 obo:CHEBI_51373 obo:CHEBI_52209 obo:CHEBI_52210 obo:CHEBI_52290 obo:CHEBI_53559 obo:CHEBI_53756 obo:CHEBI_55322 obo:CHEBI_59282 obo:CHEBI_59517 obo:CHEBI_59826 obo:CHEBI_59897 obo:CHEBI_60186 obo:CHEBI_60311 obo:CHEBI_60605 obo:CHEBI_60606 obo:CHEBI_60643 obo:CHEBI_60798 obo:CHEBI_60807 obo:CHEBI_60832 obo:CHEBI_61015 obo:CHEBI_61016 obo:CHEBI_61115 obo:CHEBI_61908 obo:CHEBI_61951 obo:CHEBI_62488 obo:CHEBI_62872 obo:CHEBI_64571 obo:CHEBI_64909 obo:CHEBI_64911 obo:CHEBI_65023 obo:CHEBI_65259 obo:CHEBI_68495 obo:CHEBI_68563 obo:CHEBI_70727 obo:CHEBI_70781 obo:CHEBI_71232 obo:CHEBI_73240 obo:CHEBI_73263 obo:CHEBI_73333 obo:CHEBI_73913 obo:CHEBI_74213 obo:CHEBI_74234 obo:CHEBI_76779 obo:CHEBI_76797 obo:CHEBI_76932 obo:CHEBI_77194 obo:CHEBI_77255 obo:CHEBI_77402 obo:CHEBI_77748 obo:CHEBI_78444 obo:CHEBI_85234 obo:CHEBI_86385 obo:CHEBI_90414 obo:CHEBI_90415 obo:CHEBI_91079
    }
    graph obo:chebi.owl {
?role rdfs:subClassOf* ?valsource ;
                     rdfs:label ?rolelab .
    }
}

```



and materialize 



```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
insert {
    graph mydata:employment {
        ?role mydata:employment mydata:curated_role
    }
}
where {
    values ?valsource  {
        obo:CHEBI_130181 obo:CHEBI_131699 obo:CHEBI_131770 obo:CHEBI_131787 obo:CHEBI_139503 obo:CHEBI_22333 obo:CHEBI_22586 obo:CHEBI_23018 obo:CHEBI_23354 obo:CHEBI_23357 obo:CHEBI_23366 obo:CHEBI_23888 obo:CHEBI_24020 obo:CHEBI_24621 obo:CHEBI_24869 obo:CHEBI_25435 obo:CHEBI_25491 obo:CHEBI_25728 obo:CHEBI_27026 obo:CHEBI_27314 obo:CHEBI_33229 obo:CHEBI_33280 obo:CHEBI_35195 obo:CHEBI_35221 obo:CHEBI_35522 obo:CHEBI_35530 obo:CHEBI_35544 obo:CHEBI_35569 obo:CHEBI_35660 obo:CHEBI_35856 obo:CHEBI_35941 obo:CHEBI_36413 obo:CHEBI_37153 obo:CHEBI_37670 obo:CHEBI_37699 obo:CHEBI_37700 obo:CHEBI_37733 obo:CHEBI_37886 obo:CHEBI_37887 obo:CHEBI_37890 obo:CHEBI_37955 obo:CHEBI_37956 obo:CHEBI_37961 obo:CHEBI_38157 obo:CHEBI_38161 obo:CHEBI_38215 obo:CHEBI_38234 obo:CHEBI_38324 obo:CHEBI_38325 obo:CHEBI_38462 obo:CHEBI_38623 obo:CHEBI_38632 obo:CHEBI_38633 obo:CHEBI_38637 obo:CHEBI_38706 obo:CHEBI_38808 obo:CHEBI_38809 obo:CHEBI_39000 obo:CHEBI_47958 obo:CHEBI_48001 obo:CHEBI_48279 obo:CHEBI_48561 obo:CHEBI_48578 obo:CHEBI_48873 obo:CHEBI_48876 obo:CHEBI_48878 obo:CHEBI_49020 obo:CHEBI_49103 obo:CHEBI_49159 obo:CHEBI_49200 obo:CHEBI_50103 obo:CHEBI_50112 obo:CHEBI_50113 obo:CHEBI_50114 obo:CHEBI_50137 obo:CHEBI_50183 obo:CHEBI_50188 obo:CHEBI_50218 obo:CHEBI_50276 obo:CHEBI_50390 obo:CHEBI_50502 obo:CHEBI_50509 obo:CHEBI_50510 obo:CHEBI_50566 obo:CHEBI_50568 obo:CHEBI_50629 obo:CHEBI_50630 obo:CHEBI_50683 obo:CHEBI_50696 obo:CHEBI_50745 obo:CHEBI_50750 obo:CHEBI_50781 obo:CHEBI_50790 obo:CHEBI_50837 obo:CHEBI_50844 obo:CHEBI_50902 obo:CHEBI_50904 obo:CHEBI_50905 obo:CHEBI_50908 obo:CHEBI_50910 obo:CHEBI_51060 obo:CHEBI_51065 obo:CHEBI_51373 obo:CHEBI_52209 obo:CHEBI_52210 obo:CHEBI_52290 obo:CHEBI_53559 obo:CHEBI_53756 obo:CHEBI_55322 obo:CHEBI_59282 obo:CHEBI_59517 obo:CHEBI_59826 obo:CHEBI_59897 obo:CHEBI_60186 obo:CHEBI_60311 obo:CHEBI_60605 obo:CHEBI_60606 obo:CHEBI_60643 obo:CHEBI_60798 obo:CHEBI_60807 obo:CHEBI_60832 obo:CHEBI_61015 obo:CHEBI_61016 obo:CHEBI_61115 obo:CHEBI_61908 obo:CHEBI_61951 obo:CHEBI_62488 obo:CHEBI_62872 obo:CHEBI_64571 obo:CHEBI_64909 obo:CHEBI_64911 obo:CHEBI_65023 obo:CHEBI_65259 obo:CHEBI_68495 obo:CHEBI_68563 obo:CHEBI_70727 obo:CHEBI_70781 obo:CHEBI_71232 obo:CHEBI_73240 obo:CHEBI_73263 obo:CHEBI_73333 obo:CHEBI_73913 obo:CHEBI_74213 obo:CHEBI_74234 obo:CHEBI_76779 obo:CHEBI_76797 obo:CHEBI_76932 obo:CHEBI_77194 obo:CHEBI_77255 obo:CHEBI_77402 obo:CHEBI_77748 obo:CHEBI_78444 obo:CHEBI_85234 obo:CHEBI_86385 obo:CHEBI_90414 obo:CHEBI_90415 obo:CHEBI_91079
    }
    graph obo:chebi.owl {
        ?role rdfs:subClassOf* ?valsource ;
                             rdfs:label ?rolelab .
    }
}
```

> Added 662 statements. Update took 0.6s, moments ago.

#### This doesn't assert which ingredients or structural classes have those roles

See also [mydata:transitive_massless_rolebearer](http://example.com/resource/transitive_massless_rolebearer) ... an attempt to find structural classes with inheritable roles. They're assumed to be classes is the everyday sense, not ingredients, as they have no mass. Need to check for additional mass and formula properties. Just mass and monoisotopic mass? Apparently, no average mass.

What does `?s mydata:transitive_massless_rolebearer ?s` mean?

And why aren't macrolide antibiotics in the massless role bearers?

What roles have been asserted in/with mydata:transitive_role_of_class, but not with an employment, and vice versa?



#### Review... what are the most common predicates taking IRI objects?



```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#*
?p (count(?s) as ?count)
where {
    graph obo:chebi.owl {
        ?s ?p ?o .
        filter(isuri(?o))
    }
} 
group by ?p 
order by desc (count(?s))
```

> Showing results from 1 to 13 of 13. Query took 3.2s, moments ago.

|                              p                               |         count         |
| :----------------------------------------------------------: | :-------------------: |
| [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 636234 |
| [owl:annotatedProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedProperty) | 420116 |
| [owl:annotatedSource](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedSource) | 420116 |
| [rdfs:subClassOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23subClassOf) | 180700 |
| [oboInOwl:inSubset](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23inSubset) | 116167 |
| [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 81459  |
| [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 81459  |
| [oboInOwl:hasSynonymType](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasSynonymType) | 53504  |
| [obo:IAO_0000231](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FIAO_0000231) HOR | 18385  |
| [obo:IAO_0100001](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FIAO_0100001) TRB | 18385  |
| [rdfs:subPropertyOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23subPropertyOf) | 6    |
| [owl:inverseOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23inverseOf) | 1    |
| [owl:versionIRI](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23versionIRI) | 1    |

Literals?

Showing results from 1 to 25 of 25. Query took 2.9s, moments ago.

|                              p                               |         count         |
| :----------------------------------------------------------: | :-------------------: |
| [oboInOwl:hasDbXref](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasDbXref) | 508884 |
| [owl:annotatedTarget](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedTarget) | 420116 |
| [rdfs:label](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label) | 273064 |
| [oboInOwl:hasRelatedSynonym](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasRelatedSynonym) | 200762 |
| [oboInOwl:hasOBONamespace](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasOBONamespace) | 116235 |
| [oboInOwl:id](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23id) | 116235 |
| [chebi:formula](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Fformula) | 105647 |
| [chebi:charge](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Fcharge) | 104889 |
| [chebi:mass](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Fmass) | 104111 |
| [chebi:monoisotopicmass](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Fmonoisotopicmass) | 104045 |
| [chebi:smiles](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Fsmiles) | 101603 |
| [chebi:inchi](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Finchi) | 94410  |
| [chebi:inchikey](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%2Finchikey) | 94410  |
| [oboInOwl:hasExactSynonym](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasExactSynonym) | 60250  |
| [obo:IAO_0000115](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FIAO_0000115) (defn) | 47969  |
| [owl:deprecated](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23deprecated) | 18443  |
| [oboInOwl:hasAlternativeId](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasAlternativeId) | 18385  |
| [oboInOwl:is_cyclic](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23is_cyclic) | 10   |
| [oboInOwl:is_transitive](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23is_transitive) | 8    |
| [rdfs:comment](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23comment) | 8    |
| [oboInOwl:shorthand](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23shorthand) | 2    |
| [oboInOwl:date](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23date) | 1    |
| [oboInOwl:default-namespace](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23default-namespace) | 1    |
| [oboInOwl:hasOBOFormatVersion](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasOBOFormatVersion) | 1    |
| [oboInOwl:saved-by](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23saved-by) | 1    |

Blank nodes? 81,459 `rdfs:subClassOf`s. No `owl:equivalentClass`es!

What kinds of things are blank? What predicates do they take?

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#*
?g ?t ?p (count(?s) as ?count)
where {
    graph ?g {
        ?s a ?t ;
           ?p ?o .
        filter(isblank(?s))
        filter(?g != <https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl>)
    }
} 
group by ?g ?t ?p
order by ?g ?t ?p desc (count(?s))
```

Showing results from 1 to 31 of 31. Query took 12s, moments ago.

|                              g                               |                              t                               |                              p                               |         count         |
| :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :-------------------: |
| [mydata:reference_medications](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Freference_medications) | [owl:Ontology](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Ontology) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 1    |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [oboInOwl:hasDbXref](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasDbXref) | 263302 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [oboInOwl:hasSynonymType](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasSynonymType) | 53504  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 420116 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [rdfs:label](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label) | 156814 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedProperty) | 420116 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedSource](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedSource) | 420116 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedTarget](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedTarget) | 420116 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 81459  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 81459  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 81459  |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 775   |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 775   |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 775   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 143   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [owl:intersectionOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23intersectionOf) | 143   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 302   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 302   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 302   |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 114638 |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [owl:intersectionOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23intersectionOf) | 114638 |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 344161 |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:hasValue](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23hasValue) | 42576  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 344161 |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 301585 |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 27   |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Class](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Class) | [owl:intersectionOf](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23intersectionOf) | 27   |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [rdf:type](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23type) | 42   |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:allValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23allValuesFrom) | 1    |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | 42   |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:someValuesFrom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23someValuesFrom) | 41   |

There's only 1 `owl:allValuesFrom` anywhere, in DrOn

#### Details about Axioms and Restrictions



```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select 
#*
?g ?t ?p ?o (count(?s) as ?count)
where {
    graph ?g {
        values (?t ?p) { ( owl:Axiom owl:annotatedProperty ) ( owl:Restriction owl:onProperty )}
        ?s a ?t ;
           ?p ?o .
        filter(isblank(?s))
        filter(?g != <https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl>)
    }
} 
group by ?g ?t ?p ?o
order by ?g ?t ?p ?o desc (count(?s))
```

> Showing results from 1 to 27 of 27. Query took 2.4s, moments ago.

|                              g                               |                              t                               |                              p                               |                              o                               |         count         |
| :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :-------------------: |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedProperty) | [oboInOwl:hasDbXref](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasDbXref) | "156814"^^xsd:integer |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedProperty) | [oboInOwl:hasExactSynonym](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasExactSynonym) | "61226"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Axiom](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Axiom) | [owl:annotatedProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23annotatedProperty) | [oboInOwl:hasRelatedSynonym](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.geneontology.org%2Fformats%2FoboInOwl%23hasRelatedSynonym) | "202076"^^xsd:integer |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000051](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000051) has part |  "3712"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:RO_0000087](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0000087) has role | "38606"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#has_functional_parent](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23has_functional_parent) | "16234"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#has_parent_hydride](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23has_parent_hydride) |  "1605"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#is_conjugate_acid_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_conjugate_acid_of) |  "7922"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#is_conjugate_base_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_conjugate_base_of) |  "7922"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#is_enantiomer_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_enantiomer_of) |  "2512"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#is_substituent_group_from](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_substituent_group_from) |  "1246"^^xsd:integer  |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:chebi#is_tautomer_of](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi%23is_tautomer_of) |  "1700"^^xsd:integer  |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) |  "775"^^xsd:integer   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) |  "152"^^xsd:integer   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071) |   "75"^^xsd:integer   |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [ro:has_proper_part](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.obofoundry.org%2Fro%2Fro.owl%23has_proper_part) |   "75"^^xsd:integer   |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) | "114885"^^xsd:integer |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071) | "93350"^^xsd:integer  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:IAO_0000039](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FIAO_0000039) | "21288"^^xsd:integer  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:OBI_0001937](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FOBI_0001937) | "21288"^^xsd:integer  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [ro:has_proper_part](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.obofoundry.org%2Fro%2Fro.owl%23has_proper_part) | "93350"^^xsd:integer  |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000051](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000051) |   "2"^^xsd:integer    |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) |   "22"^^xsd:integer   |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:BFO_0000054](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000054) |   "1"^^xsd:integer    |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:RO_0000052](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0000052) |   "2"^^xsd:integer    |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [obo:RO_0000057](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0000057) |   "4"^^xsd:integer    |
| [obo:dron/dron-upper.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-upper.owl) | [owl:Restriction](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23Restriction) | [owl:onProperty](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23onProperty) | [ro:has_proper_part](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.obofoundry.org%2Fro%2Fro.owl%23has_proper_part) |   "11"^^xsd:integer   |

#### Reminder: currently ignoring all ChEBI axioms unless they take "has role" as their ontological property. Should eventually look into "has part" and the various molecular relationships.



#### Massless role bearer starting point

Look into what roles they bear. May not be the same as the resent curated role employment

Are they any use if there's only one thing assigned to the class?



```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select 
#*
?structclassQ ?l  (count(distinct ?s) as ?count)
where {
    graph mydata:transitive_massless_rolebearer {
        ?s mydata:transitive_massless_rolebearer ?structclassQ .
    }
    graph obo:chebi.owl {
        ?structclassQ rdfs:label ?l
    }
} 
group by ?structclassQ ?l 
```



#### How are the mass and formula relationships used? See other predicates taking literals above.



```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX chebi: <http://purl.obolibrary.org/obo/chebi/>
select 
#*
?mbound ?mmbound ?fbound (count(distinct ?s) as ?count)
where {
    graph obo:chebi.owl {
        ?s rdfs:subClassOf* obo:CHEBI_23367 .
        optional {
            ?s chebi:mass ?m .
        }
        optional {
            ?s chebi:monoisotopicmass ?mm .
        }
        optional {
            ?s chebi:formula ?f .
        }
        bind(bound( ?m ) as ?mbound)
        bind(bound( ?mm) as ?mmbound)
        bind(bound( ?f ) as ?fbound)
    }
}
group by ?mbound ?mmbound ?fbound
```

Showing results from 1 to 8 of 8. Query took 15s, minutes ago.

|        mbound        |       mmbound        |        fbound        |         count         |
| :------------------: | :------------------: | :------------------: | :-------------------: |
| "true"^^xsd:boolean  | "true"^^xsd:boolean  | "true"^^xsd:boolean  | "101018"^^xsd:integer |
| "false"^^xsd:boolean | "false"^^xsd:boolean | "false"^^xsd:boolean |  "8843"^^xsd:integer  |
| "false"^^xsd:boolean | "false"^^xsd:boolean | "true"^^xsd:boolean  |  "816"^^xsd:integer   |
| "true"^^xsd:boolean  | "false"^^xsd:boolean | "true"^^xsd:boolean  |   "44"^^xsd:integer   |
| "true"^^xsd:boolean  | "false"^^xsd:boolean | "false"^^xsd:boolean |   "12"^^xsd:integer   |
| "false"^^xsd:boolean | "true"^^xsd:boolean  | "false"^^xsd:boolean |   "2"^^xsd:integer    |
| "true"^^xsd:boolean  | "true"^^xsd:boolean  | "false"^^xsd:boolean |   "2"^^xsd:integer    |
| "false"^^xsd:boolean | "true"^^xsd:boolean  | "true"^^xsd:boolean  |   "2"^^xsd:integer    |



#### How to find individual cases? (slow... 15 seconds each, but easy to edit)

Note sometimes the mass is 0!

```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX chebi: <http://purl.obolibrary.org/obo/chebi/>
select 
*
where {
    graph obo:chebi.owl {
        ?s rdfs:subClassOf* obo:CHEBI_23367 ;
                          rdfs:label ?l .
        optional {
            ?s chebi:mass ?m .
        }
        optional {
            ?s chebi:monoisotopicmass ?mm .
        }
        optional {
            ?s chebi:formula ?f .
        }
        filter(!bound( ?m ))
        filter(bound( ?mm))
        filter(bound( ?f ))
    }
}
```

Haven’t examined TFT thoroughly or FFT at all... but still comfortable using mass as a discriminator between compounds and structural classes. Remember, ChEBI give all of them the rdf:type owl:Class.



### Let's delete `?s mydata:transitive_massless_rolebearer ?s`

```SPARQL
PREFIX mydata: <http://example.com/resource/>
delete {
    graph mydata:transitive_massless_rolebearer {
        ?s mydata:transitive_massless_rolebearer ?o .
    }
} where {
    graph mydata:transitive_massless_rolebearer {
        ?s mydata:transitive_massless_rolebearer ?o .
    }
    filter (?s = ?o)
}
```

> Removed 213 statements. Update took 0.1s, moments ago.



### Also delete classes with one member

```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
delete {
    graph mydata:transitive_massless_rolebearer {
        ?x mydata:transitive_massless_rolebearer ?structclassQ
    }
} where {
    ?x mydata:transitive_massless_rolebearer ?structclassQ
    {
        select * where {
            {
                select 
                ?structclassQ ?l  (count(distinct ?s) as ?count)
                where {
                    graph mydata:transitive_massless_rolebearer {
                        ?s mydata:transitive_massless_rolebearer ?structclassQ .
                    }
                    graph obo:chebi.owl {
                        ?structclassQ rdfs:label ?l
                    }
                } 
                group by ?structclassQ ?l 
            }
            filter (?count = 1)
        }
    }
}
```

> Removed 11 statements. Update took 0.1s, moments ago.

The remaining massless role bearers are OK. They include some roles that might not be clinically relevant. Tannins are astringents. Polycyclic arenes are (cancer causers). Phthalates are endocrine disrupters.

What about macrolide antibiotics? They pass though antimicrobial agent, which isn't a **drug** role, so didn't get included in the original construction of this graph. What other structural class/roles are in the same situation?

- beta lactam (heterocyclic) just too convoluted
- Fibrate? chebi doesn’t recognize as a class
- thiazide doesn't bear a role
- Steroid (too broad?)

#### ~~attempt to retrieve antimicrobial agent bearers that are also drug subclass bearers~~

```SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
select * where {
    graph obo:chebi.owl {
        ?r1 a owl:Restriction;
            owl:onProperty obo:RO_0000087 ;
            owl:someValuesFrom obo:CHEBI_33281 .
        ?subrole rdfs:subClassOf* obo:CHEBI_23888 .
        ?r2 a owl:Restriction;
            owl:onProperty obo:RO_0000087 ;
            owl:someValuesFrom ?subrole .
        ?s rdfs:subClassOf*  ?r1 .
        ?s rdfs:subClassOf*  ?r2 .
    }
}
```

Give up. ATC is just way better at this. https://en.wikipedia.org/wiki/ATC_code_J01

No good BioPortal mappings between ATC and ChEBI roles

Maybe just manually assert a few?

#### Review employments

```SPARQL
PREFIX mydata: <http://example.com/resource/>
select 
?o (count(distinct ?s ) as ?count) 
where {
    graph mydata:employment {
        ?s mydata:employment ?o .
    }
}
group by ?o
```

> Showing results from 1 to 3 of 3. Query took 0.2s, minutes ago.

|                              o                               |         count         |
| :----------------------------------------------------------: | :-------------------: |
| [mydata:curated_role](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcurated_role) |  "662"^^xsd:integer   |
| [mydata:active_ingredient](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Factive_ingredient) |  "5445"^^xsd:integer  |
| [mydata:product](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fproduct) | "112592"^^xsd:integer |



## Now, populate definers and employment into Solr

### Are there any employees with more than one employment?

```SPARQL
PREFIX mydata: <http://example.com/resource/>
select 
?iri_for_solr  (count( ?employment ) as ?count ) 
where {
    graph mydata:employment {
        ?iri_for_solr mydata:employment ?employment .
    }
}
group by ?iri_for_solr 
order by desc (count( ?employment))
limit 1
```

> Showing results from 1 to 1 of 1. Query took 0.5s, minutes ago.

| iri_for_solr |      count       |
| :----------: | :--------------: |
| _:node100004 | "1"^^xsd:integer |

#### No, but why are there blank nodes in there?

```SPARQL
PREFIX mydata: <http://example.com/resource/>
select 
?employment ?blankstatus (count( ?iri_for_solr ) as ?count)
where {
    graph mydata:employment {
        ?iri_for_solr mydata:employment ?employment .
    }
    bind(isblank( ?iri_for_solr  ) as ?blankstatus)
}
group by ?employment ?blankstatus 

```

>  Showing results from 1 to 4 of 4. Query took 0.3s, minutes ago.

|                          employment                          |       blankstatus       |        count         |
| :----------------------------------------------------------: | :---------------------: | :------------------: |
| [mydata:active_ingredient](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Factive_ingredient) |  "false"^^xsd:boolean   | "5445"^^xsd:integer  |
| [mydata:product](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fproduct) |  "false"^^xsd:boolean   | "85094"^^xsd:integer |
| [mydata:curated_role](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fcurated_role) |  "false"^^xsd:boolean   |  "662"^^xsd:integer  |
| [mydata:product](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fexample.com%2Fresource%2Fproduct) | "**true**"^^xsd:boolean | "27498"^^xsd:integer |

Some of the product employees are blank nodes. Todo: address later

### combine newish employments with older RxNorm TTYs



```SPARQL
PREFIX mydata: <http://example.com/resource/>
select 
?employment (count(?iri_for_solr) as ?count)
#?iri_for_solr ?employment
where {
    {
        {
            # for ChEBI and DrOn
            # this should be conslidated
            graph mydata:employment {
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
        } union {
            # RxNrom
            graph <http://example.com/resource/rxn_tty/> {
                ?iri_for_solr a ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/rxn_tty/", "") as ?employment)
            }
        }
    }
    filter(isiri( ?iri_for_solr  ))
}
group by ?employment
```

>  Showing results from 1 to 17 of 17. Query took 1.2s, minutes ago.

|    employment     |        count         |
| :---------------: | :------------------: |
| active_ingredient | "5445"^^xsd:integer  |
|        BN         | "12101"^^xsd:integer |
|       BPCK        |  "685"^^xsd:integer  |
|   curated_role    |  "662"^^xsd:integer  |
|       GPCK        |  "621"^^xsd:integer  |
|        IN         | "12454"^^xsd:integer |
|        MIN        | "3813"^^xsd:integer  |
|        PIN        | "2928"^^xsd:integer  |
|      product      | "85094"^^xsd:integer |
|        SBD        | "22758"^^xsd:integer |
|       SBDC        | "18986"^^xsd:integer |
|       SBDF        | "14576"^^xsd:integer |
|       SBDG        | "20791"^^xsd:integer |
|        SCD        | "36927"^^xsd:integer |
|       SCDC        | "26808"^^xsd:integer |
|       SCDF        | "14451"^^xsd:integer |
|       SCDG        | "15855"^^xsd:integer |

### there should still br only one employment per employee

```SPARQL
PREFIX mydata: <http://example.com/resource/>
select 
?iri_for_solr (count(?employment) as ?count)
#?iri_for_solr ?employment
where {
    {
        {
            # for ChEBI and DrOn
            # this should be conslidated
            graph mydata:employment {
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
        } union {
            # RxNrom
            graph <http://example.com/resource/rxn_tty/> {
                ?iri_for_solr a ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/rxn_tty/", "") as ?employment)
            }
        }
    }
    filter(isiri( ?iri_for_solr  ))
}
group by ?iri_for_solr
order by desc (count( ?employment_iri ))
limit 1

```

Showing results from 1 to 1 of 1. Query took 4.5s, moments ago.

|      |                         iri_for_solr                         |      count       |
| :--: | :----------------------------------------------------------: | :--------------: |
|  1   | [rxnorm:1000000](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F1000000) | "1"^^xsd:integer |

### where do the labels come from? don't want duplicate preferred labels. would ahve to clean up offline

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select 
#*
#?iri_for_solr (count(?employment) as ?count)
#?iri_for_solr ?employment
?g (count(?iri_for_solr) as ?count)
where {
    {
        # only dron chebi and rxnorm are included in this result at this point
        {
            # for ChEBI and DrOn
            # this should be conslidated
            graph mydata:employment {
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
            graph ?g {
                ?iri_for_solr rdfs:label ?l .
            }
        } union {
            # RxNrom
            graph <http://example.com/resource/rxn_tty/> {
                ?iri_for_solr a ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/rxn_tty/", "") as ?employment)
            }
            graph ?g {
                ?iri_for_solr skos:prefLabel ?l .
            }
        }
    }
    filter(isiri( ?iri_for_solr  ))
}
group by ?g 

```



Showing results from 1 to 5 of 5. Query took 1.7s, minutes ago.

|                              g                               |         count         |
| :----------------------------------------------------------: | :-------------------: |
| [https://raw.githubusercontent.com/PennTURBO/Turbo-Ontology/master/ontologies/turbo_merged.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=https%3A%2F%2Fraw.githubusercontent.com%2FPennTURBO%2FTurbo-Ontology%2Fmaster%2Fontologies%2Fturbo_merged.owl) |   "3"^^xsd:integer    |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) |  "2029"^^xsd:integer  |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) |  "4881"^^xsd:integer  |
| [obo:dron-rxnorm.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron-rxnorm.owl) | "85094"^^xsd:integer  |
| [rxnorm:](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FRXNORM%2F) | "112303"^^xsd:integer |

ChEBI always desireable for ingredients and roles

​	dron-ingredient it the only source of labels for dron native ingredients. It aslo has additional, slightly different labels for the same IRIs

Dron-rxnorm is teh only source of labels for dron products

rxnorm is the only source of labels for all rxnorm entities. there is semantic overlap with chebi ingredient, dron ingredient and dron products, but no shared IRIs

```SPARQL
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select (?iri_for_solr as ?mediri) ?definedin ?employment ?labelpred (lcase(str(?l)) as ?medlabel)
#*
where {
    {
        # only chebi, rxnorm and dron (subontologies) are included in this result at this point
        # skipping
        #    <http://purl.obolibrary.org/obo/dron/dron-upper.owl> (contains dispositions... but just a few)
        #    <http://purl.obolibrary.org/obo/dron/dron-hand.owl> some more dispositions and some products
        # done iri, employment, single definer, single rdfs:label/skos:prefLabel with value and predicate
        # assuming that, in a given graph from a given definer) each term will ahve only one rdfs:label or skos:prefLabel
        # todo (concatenated?) alternative labelS, preferably only if they are case-insentivie differnt rom the preferred label
        #    only from RxNorm... seperate query, merge in R?
        # todo (concatenated?) synonyms with dbxref and type, as above
        #    only in ChEBI? ... seperate query, merge in R?
        # who hase obo:IAO_0000118 alternative terms? just turbo, dron hand and dron upper
        {
            # for ChEBI ingredietns and roles
            # chebi has synonms with sources and types (sometimes)
            # rosuvastatin not in here because emplyment creation didn't consider bioportal mappings
            graph mydata:employment {
                values ?employment_iri {
                    mydata:active_ingredient
                    mydata:curated_role
                }
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
            values ?defined_in {
                obo:chebi.owl            
            }
            values ?labelpred {
                rdfs:label 
            }
            graph ?defined_in {
                ?iri_for_solr ?labelpred ?l .
            }
        } union {
            # for DrOn products
            graph mydata:employment {
                values ?employment_iri {
                    mydata:product 
                }
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
            # the obo rxnomr graph name is liable to change (due to a typo in teh yaml config from MAM)
            values ?defined_in {
                obo:dron-rxnorm.owl <http://purl.obolibrary.org/obo/dron/dron-hand.owl>
            }
            values ?labelpred {
                rdfs:label 
            }
            graph ?defined_in {
                ?iri_for_solr ?labelpred ?l .
            }
        } union {
            # for DrOn native ingredients
            graph mydata:employment {
                values ?employment_iri {
                    mydata:active_ingredient 
                }
                ?iri_for_solr mydata:employment ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/", "") as ?employment)
            }
            # the obo rxnomr graph name is liable to change (due to a typo from MAM)
            values ?defined_in {
                <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl>
            }
            values ?labelpred {
                rdfs:label 
            }
            graph ?defined_in {
                ?iri_for_solr ?labelpred ?l .
            }
            minus {
                graph obo:chebi.owl {
                    ?iri_for_solr a owl:Class .
                }
            }
        } union {
            # RxNrom
            # BioPortal RxNorm RDF does have some alternative terms
            # but not as many as the NLM files/tables ?
            graph <http://example.com/resource/rxn_tty/> {
                ?iri_for_solr a ?employment_iri .
                bind(replace(str( ?employment_iri  ), "http://example.com/resource/rxn_tty/", "") as ?employment)
            }
            values ?defined_in {
                rxnorm:
            }
            values ?labelpred {
                skos:prefLabel 
            }
            graph rxnorm: {
                ?iri_for_solr ?labelpred  ?l .
            }
        }
    }
    filter(isiri( ?iri_for_solr  ))
    #    filter(lcase(str(?l)) = 'amitriptyline tablet')
}
```



```SPARQL
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
select ?mediri ?labelpred ?medlabel
#(group_concat(distinct lcase(str(?rawlab)) ;  SEPARATOR = "|") as ?medlabel)
# are ther any cases in which we would want to keep case sensitiity?
# saVe that (and unique concatenationor listifying ) for R?
where {
    graph rxnorm: {
        values ?labelpred {
            skos:altLabel
        }
        ?mediri  ?labelpred ?rawlab .
        bind(lcase(str(?rawlab)) as ?medlabel)
    }
}
#group by ?mediri ?labelpred
```



```SPARQL
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX mydata: <http://example.com/resource/>
select 
(?annsource as ?mediri) ?l (?annprop as ?synstrength) (?dbxr as ?synsource) ?syntype (?anntarg as ?synval) (strlen( ?anntarg ) as ?synlen)
where {
    graph mydata:employment {
        ?annsource mydata:employment mydata:active_ingredient
    }
    graph obo:chebi.owl {
        #        values ?anntarg {
        #            "Tylenol" 
        #        }
        values ?annprop {
            oboInOwl:hasExactSynonym oboInOwl:hasRelatedSynonym 
        }
        ?restr a owl:Axiom ;
               owl:annotatedSource ?annsource ;
               owl:annotatedProperty ?annprop ;
               owl:annotatedTarget ?anntarg .
        ?annsource rdfs:label ?l .
        filter( ?syntype != <http://purl.obolibrary.org/obo/chebi#IUPAC_NAME> )
        filter( lcase(str(?l)) != lcase(str(?anntarg)) )
        optional {
            ?restr oboInOwl:hasDbXref ?dbxr .
        }        
        optional {
            ?restr  oboInOwl:hasSynonymType ?syntype .
        }
    }
}
```

