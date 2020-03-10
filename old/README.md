# PennTURBO medication mapping

## Benefits:

- Can attempt mapping against any vocabulary that can be linked to RxNorm by any method, such as shared CUIs, BioPortal mappings, or DrOn assertions
- Can use vocabularies as soon as they're released...  don't have to wait for CLAMP, MedEx etc. to catch up.  (Relevance to MetaMap, CTAKES, etc?)
- Can map to vocabularies that aren't really about drugs.  FULL_NAMEs are contaminated with tests, procedures, nutrition, devices...
- Provides an "expansion" accounts for systematic differences between source (PDS) word usage (PO tabs) and target vocabulary word usage (oral tablet).  Examining provided differential word usage tables provides guidance on creating expansion rules.
- No negative training or marked-up text needed, just *a little* positive training data
- Predicts semantic proximity between Solr hit and input term.  Also provides numerical confidence.
- Understands that orders are atomic... doesn't try to parse out multiple medications per line, or span across lines (like you prefer for scanning clinical notes)

----

The PennTURBO medication mapping approach searches the string representations of medication orders (like R_MEDICATION.FULL_NAMEs from PDS) against a Solr collection of the labels for terms from drug-oriented linked datasets, like DrOn, ChEBI, RxNorm, and various other subsets of UMLS.

Because a small subset of the R_MEDICATIONs are already tagged with RxNorm values in PDS, a random forest can be trained to classify the Solr search results according to their semantic proximity to the correct RxNorm term.

For many of the linked data sets that were loaded into Solr, mappings are available between the data sets' native terms and RxNorm terms.  Those mappings can come from DrOn, UMLS, or the BioPortal mapping service.

Therefore, for any R_MEDICATION.FULL_NAME, PennTURBO medication mapping can frequently identify an RxNorm term that is semantically within two hops of the theoretically correct RxNorm term.

All of the data discussed above is also present in a Medication Mapping RDF graph.  That means that the relationships between these entities can be visualized.  It also make the R_MEDICATIONs search-able by rote/form, and frequently by ChEBI drug roles.

*MAM:  done with direct ChEBI to RxNorm role projection and single-link inheritance.  Still working on two-hop RxNorm role inheritance.  Haven't started materialized role closure.*

This GitHub repository does not include all of the dependencies of the medication mapping pipeline.

Assumptions: 
- a Ontotext GraphDB repository has already been populated with several data an knowledge collections in the predetermined RDF format.  ***MAM move more documentation here***
    - EHR medication records, with some existing RxNorm classifications for training
    - RDF/linked data drug data sets, including ChEBI (owl:versionIRI	obo:chebi/174/chebi.owl), DrOn (owl:versionInfo	2019-02-15), RxNorm (and other UMLS components... 2018AA, except for MDDB from 2017AA).  UMLS content has to be exported with MetaMorphoSys, imported into a MySQL database, and then converted to RDF with umls2rdf.py from NCBO.)
    - mappings between the various terms, retrieved from the NCBO BioPortal mapping service
- A Solr collection has been populated from the RDF linked data sets.  `turbo_med_mapping_prep.R` dumps the necessary data to a 276 MB CSV file, which can be bulk posted into Solr..  
- the R code will be executed on the same computer as the Solr process and the GraphDB process.  The host name settings in the scripts could obviously be changed from localhost to something else, but there is one step that requires that the R script can write to GraphDB's "import" folder, even if it is a network share.


Also not included in in this GitHub repo: 

- the random forest model, like `turbo_med_mapping_rf_classifier_no_nddf_alt.Rdata`, whose file size is greater than 1 GB. 
    - Where could that be stored?  Zenodo?  Can be recreated with `turbo_med_mapping_train.R`
    
The training is not thoroughly commented yet and was probaly not written for optimal efficiency.  We run it on a dedicated 64 or 128 GB server.

### Previous report `PDS_meds_to_turbo_terms_and_roles_17col.csv`

Intended to contain one row per R_MEDICATION.  It had the following columns:

- ~~PK_MEDICATION_ID~~
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
- ***doseform_turbo***
- ~~analgesic_role_turbo~~
- ~~antiarrhythmic_role_turbo~~
- ~~antiemetic_role_turbo~~
- ~~antipsychotic_role_turbo~~

Column key:
- Inputs into and output from the medication mapping pipeline.  Included in newest report.
- ~~Omitted in newest report, generally because it is dependent on knowledge pulled from EPIC (not PDS) and was intended as an early sanity check.~~
- ***To be included in newest report?  Requires additional linking thorough RxNorm.***

*MAM: still working on different levels of aggregation for best terms and all-term-concatenation*

### Old output from earlier medication mapping runs

Look in graph http://example.com/resource/pds_solr_res_best_preds in GraphDB repository epic_mdm_ods_20180918?

See also graphs http://example.com/resource/rxn_role_materializations and http://example.com/resource/role_inheritance and possibly repo backtrack_and_document

FULL_NAME associated with misclassification in earlier medication mapping campaing:
- .Morphine Liq Oral 20 mg/5 mL-HUP

