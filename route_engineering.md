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

Which can be discovered with

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

Annotations

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
| ------------------------------------------------------------ | --------------------- |
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
| ------------------------------------------------------------ | --------------------- |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  (IBO) | 114885 |
| [ro:has_proper_part](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fwww.obofoundry.org%2Fro%2Fro.owl%23has_proper_part) | 93350  |
| [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071)  (HGP) | 93350  |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select 
#*
#?op ?valsource (count(distinct ?r) as ?count)
?first_blank ?rest_blank (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        #        filter(isuri( ?valsource ))
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

All rest blank, no first blank (all [obo:OBI_0000576](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FOBI_0000576))



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#*
#?op ?valsource (count(distinct ?r) as ?count)
#?first_blank ?rest_blank (count(distinct ?r) as ?count)
#?hpp_first (count(distinct ?r) as ?count)
?sma_intersection_first_op ?sma_intersection_first_valsource (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        #        filter(isuri( ?valsource ))
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
| ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------- |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  HRole | [obo:DRON_00000028](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FDRON_00000028)  (HAI) | 48786 |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053) | [obo:DRON_00000029](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FDRON_00000029)  (HExcip) | 44564 |



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#*
#?op ?valsource (count(distinct ?r) as ?count)
?first_nil ?rest_nil (count(distinct ?r) as ?count)
#?hpp_first (count(distinct ?r) as ?count)
#?sma_intersection_first_op ?sma_intersection_first_valsource (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        #        filter(isuri( ?valsource ))
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
| -------------------- | -------------------- | -------------------- |
| false | true  | 27498 |
| false | false | 21288 |



False/false when the dosage is known?



When defined, ?acting_rest_rest_op is always obo:BFO_0000071, HGP



```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX ro: <http://www.obofoundry.org/ro/ro.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
select 
#*
#?op ?valsource (count(distinct ?r) as ?count)
?acting_first_op  (count(distinct ?r) as ?count)
#?hpp_first (count(distinct ?r) as ?count)
#?sma_intersection_first_op ?sma_intersection_first_valsource (count(distinct ?r) as ?count)
where {
    graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
        ?r a owl:Restriction ;
           owl:onProperty ro:has_proper_part ;
           owl:someValuesFrom ?hpp_valsource .
        #        filter(isuri( ?valsource ))
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
        #        filter(?acting_rest != rdf:nil )
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
| ------------------------------------------------------------ | -------------------- |
| [obo:BFO_0000071](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000071)  HGP | 27498 |
| [obo:BFO_0000053](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FBFO_0000053)  HRole | 21288 |



If ?acting_first_op is obo:BFO_0000071, then there is no ?acting_rest_rest at all

~~Multiple active ingredients?~~ **Mass/dosage modeling?**

If ?acting_first_op is obo:BFO_0000053, then the value source is an intersection. The first part of the intersection is always obo:PATO_0000125, 'mass'

In those cases, shouldn't there be a parent, massless class? So just pursue ?acting_first_op = obo:BFO_0000071 case?



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
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------- |
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
| ------------------------------------------------------------ | ------------------- |
| [obo:dron/dron-ingredient.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-ingredient.owl) | 4872 |
| [obo:chebi.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fchebi.owl) | 795  |
| [obo:dron/dron-hand.owl](http://turbo-prd-db01.pmacs.upenn.edu:7200/resource?uri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2Fdron%2Fdron-hand.owl) | 52   |



#### Now materialize that!

- Anything that's a subClassOf* an (active, DrOn/ChEBI) ingredient as tagged above is an ingredient
- Anything that's a subClassOf* a DrOn product as tagged above is a product
  - distinguish brand from generic?
- Include defining graph context? As an owl:Axiom?



**Don't forget to add it to R script XXX**



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
        #order by asc (count(distinct ?acting))
    }
}
group by ?acting_count 
order by asc (?acting_count)
```

> Showing results from 1 to 23 of 23. Query took 2.7s, moments ago.

| **acting_count**  | **prod_count**       |
| ----------------- | -------------------- |
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
        ?subacting mydata:employment mydata:active_ingredient .
#        ?annotation_axiom a owl:Axiom ;
#                          owl:annotatedSource ?x ;
#                          owl:annotatedProperty mydata:employment ;
#                          owl:annotatedTarget mydata:hasactive_ingredient ;
#                          oboInOwl:hasDbXref ?defining_graph .
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
    ?subacting rdfs:subClassOf* ?acting .
    {
        graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> as ?defining_graph)
            bind(uuid() as ?annotation_axiom )
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/chebi.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/chebi.owl> as ?defining_graph)
            bind(uuid() as ?annotation_axiom )
        } 
    } union     {
        graph <http://purl.obolibrary.org/obo/dron/dron-hand.owl> {
            ?acting a owl:Class .
            bind(<http://purl.obolibrary.org/obo/dron/dron-hand.owl> as ?defining_graph)
            bind(uuid() as ?annotation_axiom )
        } 
    }  
}
```

> Added 5445 statements. Update took 10s, minutes ago.



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



owl:Axioms are asserted for each appearance of an active ingredient in a product. Do we need to assert the graph in which we determined that something was a product or ingredient? We already have defined_in triples?



product doesn't distinguish between brand and generic

nothing for RxNorm yet. intestinally holding off on ndfrt and atc
