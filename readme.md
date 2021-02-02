# TURBO Medication Mapping

The TURBO Medication Mapper (TMM) pipeline is a set a R scripts that take medication strings as input, learns associations to RxNorm entries, and outputs a RDF knowledge graph of associations based on the identified RxNorm entries and related entries in terminologies covering drugs and chemicals. A Solr database is made for searching the knowledge graph with the medication strings. An associated TMM Ontology provides structured documentation of the different types of entities that can be retrieved and the SPARQL queries to perform the retrieval from the knowledge graph.

The TURBO Medication Mapper is described in an ICBO 2020 paper “A Robust, Self-Training Classifier for Medication Strings, with Quantitative and Semantic Confidence Metrics” Mark A. Miller, Hayden Freedman, Christian J. Stoeckert, Jr. (supplemental files are located here).

The pipeline steps are:
1. Train a TTM model: Learn RxNorm with Random Forests. Can reuse output of this step and start at step 2. [rxnav_med_mapping_proximity_training_no_tuning.R]
   1. TMM adds features like multiple string similarity measures between the inputs and matches, rxcui.count, the semantic type of the matching RxNorm term, and the upstream source from which RxNorm obtained the match’s label or synonyms.
   2. Steps are:
      1. Submit random RxNorm labels to RxNav approximate search and get query/result pairs with scores and ranks based on the Jaccard index between the tokens in the input and those in in the matches.
      2. searches RxNorm SQL to determine the actual relationship between each pair (identical, off by one relation, or more distant)
      3. calculate string distance between each query and result, along with other features for training
      4.	train a single-label, multi-class random forest classifier to determine relationships based on RxNav score, RxNav rank, string distances, etc
2. Extract medication strings (full name, generic name), associated database primary key, associated RxNorm codes, number of patients with orders for the medication. [pds_r_medication_sql_select.R output is an .Rdata file]
   1. Filter for minimum number of patients with orders for the medication [rxnav_med_mapping_proximity_classifier.R]
   2. Normalize strings: scrub and replace tokens [rxnav_med_mapping_proximity_classifier.R]
3. Use the RxNav approximate search API to search extracted strings against all medications known to RxNav-in-a-Box [rxnav_med_mapping_proximity_classifier.R]
   1. Submit normalized string to RxNav approximate search and get query/result pairs with scores and ranks based on the Jaccard index between the tokens in the input and those in in the matches.
4. Classify medication strings with a trained TTM model [rxnav_med_mapping_proximity_classifier.R]
   1. Interpret the features as predictors of the semantic relations between searches and matches
   2. Classify matches as identical, related, more distant
5. Convert matches and classifications to RDF with ROBOT. [tmm_robot.sh]
6. Retrieve pairwise mappings between ChEBI, DrOn and RxNorm from BioPortal and save as a local RDF file. Can skip this step and reuse mappings until want to update source ontologies. [get_bioportal_mappings.R]
7. Assemble a Medication Knowledge Graph
   1. Load the classification output, the BioPortal mappings, and additional ontologies/RDF models into a Graph DB repository to create the RDF knowledge graph. [rxnav_med_mapping_load_materialize_etc.]
8. Create Solr core from with the labels and URIs of the entities in the ontologies and RDF data models. [rxnav_med_mapping_solr_upload_post_test.R]

See also [inputs_outputs.md](inputs_outputs.md), which also shows the order in which the scripts should be run the first time around.
