Can be run any time.  Like many other parts of this new med mapping campaign, this may not use the same semantics as before, so may need to coordinate with Hayden

```
PREFIX umls: <http://bioportal.bioontology.org/ontologies/umls/>
prefix mydata: <http://example.com/resource/>
insert {
    graph mydata:materializedCui {
        ?s mydata:materializedCui ?materializedCui .
    }
} where {
    ?s umls:cui ?o .
    bind(uri(concat("http://example.com/resource/materializedCui/", ?o)) as ?materializedCui)
}
```

> Added 683984 statements. Update took 24s, moments ago.
