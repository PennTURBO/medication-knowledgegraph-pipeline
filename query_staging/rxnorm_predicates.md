```
select distinct ?p where {
    graph 
<https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> 
{
        ?s ?p ?o .
    }
    filter(isuri(?o))
} 
```

| p  |
|---------------|
| owl:imports                |
| rdf:type                   |
| rdfs:subClassOf             |
| rxnorm:consists_of            |
| rxnorm:constitutes            |
| rxnorm:contained_in           |
| rxnorm:contains               |
| rxnorm:dose_form_of           |
| rxnorm:doseformgroup_of       |
| rxnorm:form_of                |
| rxnorm:has_dose_form          |
| rxnorm:has_doseformgroup      |
| rxnorm:has_form               |
| rxnorm:has_ingredient         |
| rxnorm:has_ingredients        |
| rxnorm:has_part               |
| rxnorm:has_precise_ingredient |
| rxnorm:has_quantified_form    |
| rxnorm:has_tradename          |
| rxnorm:ingredient_of          |
| rxnorm:ingredients_of         |
| rxnorm:inverse_isa            |
| rxnorm:isa                    |
| rxnorm:part_of                |
| rxnorm:precise_ingredient_of  |
| rxnorm:quantified_form_of     |
| rxnorm:reformulated_to        |
| rxnorm:reformulation_of       |
| rxnorm:tradename_of           |
| umls:hasSTY                 |

## Resulting in the following whitelist:

    values ?pred1 {
        rxnorm:has_ingredient
        rxnorm:isa
        rxnorm:tradename_of
        rxnorm:consists_of
        rxnorm:has_precise_ingredient
        rxnorm:has_ingredients
        rxnorm:has_part
        rxnorm:form_of
        rxnorm:has_form
        rxnorm:contains
    }
