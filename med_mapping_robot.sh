# source_meds.csv is currently specified in the yaml config file
robot -vvv template \
--prefix "xsd: http://www.w3.org/2001/XMLSchema#" \
--prefix "obo: http://purl.obolibrary.org/obo/"  \
--prefix  "mydata: http://example.com/resource/" \
--input minimal_templating_ontology.ttl  \
--template rxnav_medication_mapping_final_predictions.csv \
--output classification_res_tidied_no_objprops.ttl


# source_meds.csv is currently hardcoded in the R classification script
robot -vvv template \
--prefix "xsd: http://www.w3.org/2001/XMLSchema#" \
--prefix "obo: http://purl.obolibrary.org/obo/"  \
--prefix  "mydata: http://example.com/resource/" \
--input minimal_templating_ontology.ttl  \
--template source_meds.csv \
--output source_meds.ttl

