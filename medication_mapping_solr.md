- # Medication Mapping Solr

-  

- We are currently using Solr standalone mode, not cloud mode

-  

- ssh to `turbo-prd-app02`

- `sudo -u turbo -s`

-   

- The Solr package in in `/opt/solr`

- The Solr cores are in `/var/solr/data/`

-  

- Using Classic `schema.xml` mode, not schema-less mode or managed schema mode

- Trying to index input that uses fields that are unspecified in schema.xml will fail

- Not using any dynamic "_str" fields. Tthey search for perfect substring matches with no permutations or partial token matching.

- Not creating an allText copy field.

- 

- We also have 

- "tablet,tablets" in `synonyms.txt`

-  

- See also

- http://turbo-prd-app02:8983/solr/#/medication-employment-labels-dev-acting_normalization/core-overview

-  

- See

- - https://lucene.apache.org/solr/guide/6_6/schema-factory-definition-in-solrconfig.html
  - https://lucene.apache.org/solr/guide/6_6/documents-fields-and-schema-design.html#documents-fields-and-schema-design
  - https://lucene.apache.org/solr/guide/6_6/schemaless-mode.html#schemaless-mode
  - http://www.solrtutorial.com/solrconfig-xml.html

-  

- ## Restarting Solr (should start itself on each reboot?)

- As user `turbo`

- `/opt/solr/bin/solr restart`

- Similar syntax for starting and stopping

-  

- ## Create a new core based on an existing configset

- Use a `/conf` folder from a core that is already configured well, or use 

- https://github.com/PennTURBO/medication-knowledgegraph-pipeline/tree/action-versioning/medication-employment-labels/conf

- Should merge that into master

- `/opt/solr/bin/solr create -c medication-employment-labels-dev-acting_normalization -d /home/turbo/medication_mapping_solr_conf/`

-  

- See also https://github.com/PennTURBO/medication-knowledgegraph-pipeline/issues/35

-  

- ## Removing all documents from a core

- `curl  http://localhost:8983/solr/medication-employment-labels-dev-acting_normalization/update?commit=true -X POST -H "Content-Type: text/xml" --data-binary "<delete><query>*:*</query></delete>"`

-  

- ## Deleting a core

- `/opt/solr/bin/solr delete -c medication-employment-labels-dev-acting_normalization`

-  

- ## Adding documents

- Several approaches

- I have been updating from a JSON file over REST

- `curl 'http://localhost:8983/solr/medication-employment-labels-dev-acting_normalization/update?commit=true&overwrite=false' --data-binary  @medlabels_for_chebi_for_solr.json -H 'Content-type:application/json'`

- That's embedded in https://github.com/PennTURBO/medication-knowledgegraph-pipeline/blob/master/pipeline/rxnav_med_mapping_solr_upload_post_test.R

-  

- ## Querying

- The most basic query is *:* in that it gets on page's worth of any documents, regardless of any fields contents

- http://turbo-prd-app02:8983/solr/medication-employment-labels-dev/select?q=*%3A*

- To query for some tokens in one field, regardless of order

- `medlabel:(codeine tylenol)`

- Conversely, wrapping a query in "" requires the specified ordering of tokens

- [http://turbo-prd-app02:8983/solr/medication-employment-labels-dev-acting_normalization/select?q=medlabel%3A(codeine%20tylenol)](http://turbo-prd-app02:8983/solr/medication-employment-labels-dev-acting_normalization/select?q=medlabel%3A(codeine tylenol))

- We have two fields with tokens from the labels, alternative terms, synonyms, etc.:

- - `medlabel`, which is a list of all tokens from the preferred label (`rdfs:label` for OBO content and  `skos:prefLabel` for UMLS derived content including RxNorm)

  - `tokens`: a list of all tokens  from all preferred labels, alternate terms, synonyms

  - - Noisier, but includes some tokens thst don't appear in preferred labels

  - Adding some fuzziness:

- - Synonymy can also be handled in two styles in the `synonyms.txt` file
  - Solr has sophisticated spell checking tools...
  - ... as well as the simpler fuzzy match operator `~` which can take an edit distance argument like `~2`
  - `medlabel:(codein~ tablex~)`

- But best results may come from an edismax query over the  medlabel and tokens fields

- - [http://turbo-prd-app02:8983/solr/medication-employment-labels-dev-acting_normalization/select?defType=edismax&fl=id%2Cmedlabel%2Cemployment%2Cdefinedin%2Ctokens%2Cscore&q=(codein~%20tablex~)&qf=medlabel%20tokens&stopwords=true](http://turbo-prd-app02:8983/solr/medication-employment-labels-dev-acting_normalization/select?defType=edismax&fl=id%2Cmedlabel%2Cemployment%2Cdefinedin%2Ctokens%2Cscore&q=(codein~ tablex~)&qf=medlabel tokens&stopwords=true)

- 

-  