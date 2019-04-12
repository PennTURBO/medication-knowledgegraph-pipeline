# PennTURBO medication mapping

Searches strings representing medication orders against a Solr collection of the labels from semantic terms for drugs, etc.

Uses a classifier to predict the semantic proximity between search search result and the latent meaning of the string.

Not included in GitHub: 

- random forest model, like `turbo_med_mapping_rf_classifier_no_nddf_alt.Rdata`.  > 1 GB. Where to store?  Zenodo?  Can be recreated with `turbo_med_mapping_train.R`
- Solr document collection.  Serialized as a 276 MB CSV files.  Can be recreated with `turbo_med_mapping_prep.R`

Assumptions: 
- a Ontotext GraphDB repository has already been populated with content in a predetermined RDF format.  ***MAM move more documentation here***
    - EHR medication records, with some existing RxNorm classifications for training
    - Semantic drug models including ChEBI (owl:versionIRI	obo:chebi/174/chebi.owl), DrOn (owl:versionInfo	2019-02-15), RxNorm (and other UMLS components... 2018AA, except for MDDB from 2017AA).  UMLS content has to be exported with MetaMorphoSys, imported into a MySQL database, and then converted to RDF with umls2rdf.py from NCBO.)
    - mappings between the various terms, retrieved from the NCBO BioPortal mapping service
- the R code will be executed on the same computer as the Solr process and the GraphDB process.  THe host name settings in the scripts could obviously be changed from localhost to something else, but one step requires that R can write to GraphDB's "import" folder.

### Previous output `PDS_meds_to_turbo_terms_and_roles_17col.csv` had the following columns

- **PK_MEDICATION_ID**
- FULL_NAME
- SOURCE_CODE
- ~~PHARMACY_CLASS~~
- ~~PHARMACY_SUBCLASS~~
- ~~THERAPEUTIC_CLASS~~
- RXNORM_CODEs_pds
- ~~RXNORM_CODEs_emh~~
- RXNORM_CODEs_turbo
- bestterm_turbo
- best_RXNORM_CODE_turbo
- best_RXNORM_label_turbo
- **doseform_turbo**
- ~~analgesic_role_turbo~~
- ~~antiarrhythmic_role_turbo~~
- ~~antiemetic_role_turbo~~
- ~~antipsychotic_role_turbo~~

### Output in previouos GraphDB repository ... had the following graph names and triples patterns...
