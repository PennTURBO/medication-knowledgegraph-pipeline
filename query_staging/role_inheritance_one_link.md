Do role projection first

```
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:rxn_role_projection {
        ?inheritance_uuid a mydata:rxn_role_projection ;
            mydata:rxn_from ?rxnWithRole ;
            mydata:chebi_role ?role ;
            mydata:predicate_count 1 ;
            mydata:predicate1 ?p ;
            mydata:rxn_comp ?predrxn .
    }
}
where {
    graph mydata:med_map_rf_pred {
        ?mapping rdf:type	mydata:med_map_rf_pred ;
                 mydata:rxnifavailable ?predrxn .
    }
    graph mydata:rxn_role_projection {
        ?uuid  a mydata:rxn_role_projection ;
               mydata:rxn_comp ?rxnWithRole  ;
               mydata:chebi_role ?role .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?predrxn ?p ?rxnWithRole .
        #        ?predrxn skos:prefLabel ?predrxnLab .
        #        ?rxnWithRole skos:prefLabel ?rxnWithRoleLab .
    }
    bind(uuid() as ?inheritance_uuid)
}
```

> Added 26691528 statements. Update took 8m 50s, moments ago.
