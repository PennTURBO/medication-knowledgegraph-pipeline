http://54.173.154.214:8983/solr/medmappers_20181109/select/?q=*%3A*&rows=0&facet=on&facet.field=combo_likely

## OLD campaign

creating:

clearing: 
```
curl http://localhost:8983/solr/med_map_support_20180403/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
```

posting:
```
/home/ubuntu/solr-8.0.0/bin/post -c med_map_support_20180403 -params "overwrite=false" for_solr_dron_via_r.csv for_solr_rxnorm.csv for_solr_other.csv
```

#### From <http://54.173.154.214:8983/solr/medmappers_20181109/select/?q=*%3A*&rows=0&facet=on&facet.field=matchType> 
```
[
        "skos:altlabel",753964,
        "skos:preflabel",588916,
        "rdfs:label",112025,
        "01",82077,
        "2000",82077,
        "http",82077,
        "label",82077,
        "org",82077,
        "rdf",82077,
        "schema",82077,
        "www.w3",82077]
```
#### From <http://54.173.154.214:8983/solr/medmappers_20181109/select/?q=*%3A*&rows=0&facet=on&facet.field=rxnMatchMeth> 
```
[
        "na",1095470,
        "direct",176601,
        "rxnorm",176601,
        "cui",140882,
        "bp",82077,
        "dron",82077,
        "or",82077,
        "loom",41438,
        "same_uri",514]
```
#### From <http://54.173.154.214:8983/solr/medmappers_20181109/select/?q=*%3A*&rows=0&facet=on&facet.field=ontology> 
```
[
        "ontologies",1342880,
        "https",1248356,
        "bioportal.bioontology.org",1166279,
        "snomedct",937953,
        "15",176601,
        "data.bioontology.org",176601,
        "download",176601,
        "http",176601,
        "rxnorm",176601,
        "submissions",176601,
        "chebi",112025,
        "chebi_lite.owl.gz",112025,
        "databases",112025,
        "ftp",112025,
        "ftp.ebi.ac.uk",112025,
        "ontology",112025,
        "pub",112025,
        "ndfrt",109603,
        "bitbucket.org",82077,
        "dron",82077,
        "master",82077,
        "raw",82077,
        "uamsdbmi",82077,
        "rxnorm.owl",74479,
        "nddf",64994,
        "vandf",40648,
        "mddb",13081,
        "ingredient.owl",5630,
        "chebi.owl",1885,
        "hand.owl",81,
        "pro.owl",2]
```
#### From <http://54.173.154.214:8983/solr/medmappers_20181109/select/?q=*%3A*&rows=0&facet=on&facet.field=combo_likely> 
```
[
        "na",1165156,
        "false",322275,
        "true",49551]

----

could try:
anyLabel:(kodeine~ acetaminophen~ )
