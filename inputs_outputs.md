## pds_r_medication_sql_select.R

- **Notes**: sample script for creating a dataframe of source medication strings. As is, only relevant to PennMedicine. 
  Inputs: pds_r_medication_sql_select.R requires a connection to PDS, which is defined with the following settings, which must be kept **secret**: 
  - `config$oracle.jdbc.path`
  - `config$pds.host`
  - `config$pds.port
  - config$pds.database`
- **Output**: a list, containing the medication string dataframe and some version metadata. Serialized as an `.Rdata` file whose path & name are specified by `config$source.medications.Rdata.path`. There are several advantages and some disadvantages to using the `.Rdata` format.
- **Date/versioning**:
  - The date on which the script was run (and therefore date of database contents) is reflected with property <http://purl.org/dc/terms/created> on subject http://example.com/resource/reference_medications
    The release tag of the pipeline software that retrieved and serialized the medication string dataframe is reflected with property `owl:versionInfo`. Alternatively, the GitHub release URL could be reflected with `owl:versionIRI`

## rxnav_med_mapping_proximity_training_no_tuning.R

- **Notes**: 
- **Inputs**: requires HTTP and MySQL connections to a locally running RxNav container. MySQL is not exposed as part of the public RxNav endpoint, and even the Docker implementation requires the addition of an expose statement in the `rxnav-db` section of the `docker-compose.yml` file. The database connection is defined with the four setting and the REST API connection is defined with two settings: 
  - `config$rxnav.mysql.address`
  - `config$rxnav.mysql.port`
  - `config$rxnav.mysql.user`
  - `config$rxnav.mysql.pw`
  - `config$rxnav.api.address`
  - `config$rxnav.api.port`
- **Output**: a list, containing a random forest classifier, some version metadata, and metadata about the performance of the classifier. Serialized as an `.Rdata` file whose path & name are specified by `config$rf.model.path`.

## rxnav_med_mapping_proximity_classifier.R

- **Notes**: This script uses the robot Java application, via system calls, to generate triples about the classified medications strings. The `robot .bat` or `.sh` wrapper script and the `robot .jar` file must be present on the system executing the scripts, in the same folder, and on the system path. Also, the GraphDB repository is cleared at the beginning of this script.
- **Inputs**: 
  - requires HTTP and MySQL connections to RxNav, as described above. 
  - RxNorm data is also inserted into a GraphDB triplestore, so that any RxCUIs processed by the script can be checked for presence in the current RxNorm RDF model. (There are other ways to do that, such as opening the RxNorm RDF model into an in-memory model within the R session, but performance would likely be much slower.)   The database connection is defined with the following secret settings: 
    - `config$my.graphdb.base`
    - `config$my.graphdb.username`
    - `config$my.graphdb.pw`
    - `config$my.selected.repo`
  - A `.csv`-formatted normalization file specified by config$normalization.file. A template is provided.
  - The medication string dataframe specified by `config$source.medications.Rdata.path`
  - The random forest model specified by `config$rf.model.path`
  - A local RxNORM RDF file, whose location and format are determined by the config$my.import.files entry with the key 'http://purl.bioontology.org/ontology/RXNORM/'
  - A `.csv`-formatted file with specifications for creating robot input files, specified by `config$per.task.columns`. One could argue that these settings could go in the `YAML` configuration file, but I have found it very convenient to edit them with a spreadsheet application. This file indicates which columns from the `classification.res.tidied` dataframe should go into which robot input files, how the columns should be identified, etc.
- **Outputs**: 
  - the R logic in this script writes tab delimited files whose prefixes can be found in `config$tasks`, and whose suffixes are "for_robot.tsv". Turtle annotation files are also created by the `build.source.med.classifications.annotations()` function, with the same prefixes and the "_ontology_annotations.ttl" suffix.
  - Subsequently, the R script invokes robot to convert the `.tsv` and `.ttl` files into files with triples about the medication mapping knowledge. The output files have a "_from_robot.ttl" extension. Zip archives are also created.

## get_bioportal_mappings.R

- **Notes**: 
- **Inputs**: requires a connection to a GraphDB triplestore, as described above, and a network connection to a BioPortal/OntoPortal system. Historically, we used a OntoPortal VM running under full virtualization (like VirtualBox or VMWare). However, the amount of transfer to and from the BioPortal system has been dramatically decreased in recent versions of the pipeline, such that it can now be comfortable performed against the public BioPortal. In either case, a username and API key are required.
  - `config$my.source.ontolgies` determines which ontologies will be mapped against one another
  - `config$my.bioportal.api.base` determines the address of the BioPortal server
  - `config$my.apikey` is required for authentication. I have been using one assigned to me as a person and consider it **secret**. I haven't determined whether the NCBO issues keys under a service account model
- **Outputs**: this script saves an RDF model of the BioPortal mappings to a file specified as `config$bioportal.triples.destination`. It also posts the triples to a GraphDB triplestore, and uses most of the settings mentioned in the documentation for `rxnav_med_mapping_proximity_classifier.R`. In this case, the GraphDB user and password are passed individually, not as part of the `saved.authentication` object.This upload is also governed by these additional settings:
  - `config$my.mappings.format`
  - `config$bioportal.mapping.graph.name`

## rxnav_med_mapping_load_materialize_etc.R

- **Notes**: In addition to populating a GraphDB triplestore, this step also extracts data (labels and IDs etc. for ingredients, products, roles, etc.) from the triplestore, for a Solr document database. It might make more sense to move that code to `rxnav_med_mapping_solr_upload_post_test.R`.
- **Inputs**: 
  - requires a connection to a GraphDB triplestore, as described above
  - requires HTTP and MySQL connections to RxNav, as described above 
  - Loads remote ontology content from URLs specified by `config$my.import.urls`. PMACS/DART may feed these requests through some kind of firewall/proxy/content filter, so it may be necessary to request having the URLs added to a whitelist.
  - Loads local ontology from files specified by `config$my.import.files`. The files include any created by previous steps in the pipeline, as well as content that is available to the pubic, but which can not be automatically interpreted by GraphDB.
    Several SPARQL updates are run. The statements are defined in `config$materializastion.projection.sparqls`
- **Outputs**: This script inserts semantic content into a GraphDB triplestore and prepares data for Solr.
  - Semantic output: triples which are inserted into GraphDB as described above. That includes knowledge about the semantic types associated with RxCUIs, which is first locally serialized in the file specified by `config$rxcui_ttys.fp` and then loaded into the 'employment' named graph
  - For Solr: several SPARQL queries, specified in several config objects, are run against the triplestore. They are aggregated, converted to JSON, and saved with the filename specified by `config$json.for.solr`, under the directory specified by `config$json.source`

## rxnav_med_mapping_solr_upload_post_test.R

- **Notes**: Solr config
- **Inputs**: 
  - requires a connection to a Solr database, specified with
    - `config$med.map.kb.solr.host`
    - `config$med.map.kb.solr.port`
    - `config$med.map.kb.solr.core`
  - Requires an password-less (key-based) ssh connection to the computer that is running Solr, specified with
    - `config$ssh.user`
    - `config$ssh.host` (could possibly be different from `config$med.map.kb.solr.host` but I haven't pursued that yet. I have not found `POST`ing a large JSON file to Solr to work well between my laptop and our TURBO Solr server.)
  - Downloads the TMM ontology from (hardcoded) https://raw.githubusercontent.com/PennTURBO/medication-knowledgegraph-pipeline/master/ontology/tmm_ontology.ttl into the client's `temp` directory and then reads into an in-memory RDF model. This could probably be improved by using the same triples in the GraphDB repo. 
- **Outputs**
  - Populates the Solr core described above
  - The TMM ontology contains templated Solr queries and expected results. The queries are submitted to the medication mapping Solr, and status including any "failures" are printed to standard output. Zero failures is informal evidence that all components of the medication mapping pipeline ran as expected. 
  
See also the [readme.md](readme.md), which narrates what tasks the scripts perform.
