# Supplementary information about the Turbo Medication Mapper (TMM), 2020-05-25

* [SQL Query for Statin Drugs in our Clinical Data Warehouse (CDW)](#sql-query-for-statin-drugs-in-our-clinical-data-warehouse--cdw-)
* [Relation Between our CDW's `PHARMACY_CLASS` and `PHARMACY_SUBCLASS` Columns](#relation-between-our-cdw-s--pharmacy-class--and--pharmacy-subclass--columns)
* [Confidential Information in Single-Patient `MEDICATION` Records](#confidential-information-in-single-oatient--medication--records)
* [Factor Importance for Random Forest (RF) Training](#factor-importance-for-random-forest--rf--training)
* [Tuning of TMM RF](#tuning-of-tmm-rf)
* [Software Libraries Required for TMM's R Scripts](#software-libraries-required-for-tmm-s-r-scripts)
* [Notes on Individual Scripts & Related Files](#notes-on-individual-scripts---related-files)
  + [`defined_by` and `employment`](#-defined-by--and--employment-)
* [Solr Query for Finding URLs in TMM, Representing Terms that are Meaningful to a Clinician or Researcher](#solr-query-for-finding-urls-in-tmm--representing-terms-that-are-meaningful-to-a-clinician-or-researcher)
* [SPARQL Queries from any term with an employment to medications in the CDW](#sparql-queries-from-any-term-with-an-employment-to-medications-in-the-cdw)
* [Medications from our CDW that are Classified as "statins"](#medications-from-our-cdw-that-are-classified-as--statins-)

## SQL Query for Statin Drugs in our Clinical Data Warehouse (CDW)

*Also checks that they have been ordered for at least two unique patients. The schema and table name have been obscured.*

```sql
SELECT
 rm.PK_MEDICATION_ID,
    rm.FULL_NAME ,
    COUNT(DISTINCT pe.EMPI) AS empicount
FROM
    <MEDICATION TABLE> rm
LEFT JOIN ORDER_MED om ON
    rm.PK_MEDICATION_ID = om.FK_MEDICATION_ID
LEFT JOIN PATIENT_ENCOUNTER pe ON
    om.FK_PATIENT_ENCOUNTER_ID = pe.PK_PATIENT_ENCOUNTER_ID
WHERE
    (LOWER(FULL_NAME) LIKE '%statin%'
    OR LOWER(GENERIC_NAME) LIKE '%statin%'
    OR LOWER(FULL_NAME) LIKE '%lipitor%'
    OR LOWER(FULL_NAME) LIKE '%baycol%'
    OR LOWER(FULL_NAME) LIKE '%lescol%'
    OR LOWER(FULL_NAME) LIKE '%mevacor%'
    OR LOWER(FULL_NAME) LIKE '%livalo%'
    OR LOWER(FULL_NAME) LIKE '%pravachol%'
    OR LOWER(FULL_NAME) LIKE '%crestor%'
    OR LOWER(FULL_NAME) LIKE '%zypitamag%'
    OR LOWER(FULL_NAME) LIKE '%zocor%')
    AND LOWER(FULL_NAME) NOT LIKE '%leustatin%'
    AND LOWER(FULL_NAME) NOT LIKE '%cilastatin%'
    AND LOWER(FULL_NAME) NOT LIKE '%cholestatin%'
    AND LOWER(FULL_NAME) NOT LIKE '%sandostatin%'
    AND LOWER(FULL_NAME) NOT LIKE '%pentostatin%'
    AND LOWER(FULL_NAME) NOT LIKE '%nystatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%leustatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%cilastatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%cholestatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%sandostatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%pentostatin%'
    AND LOWER(GENERIC_NAME) NOT LIKE '%nystatin%'
GROUP BY
    PK_MEDICATION_ID,
    FULL_NAME
HAVING
    COUNT(DISTINCT pe.EMPI) > 1
```



## Relation Between our CDW's `PHARMACY_CLASS` and `PHARMACY_SUBCLASS` Columns

*We show `PHARMACY_SUBCLASS`es for statins in our paper and mention `PHARMACY_CLASS` and `THERAPEUTIC_CLASS`. Here's a table that shows single-inheritance relationships from `PHARMACY_CLASS` to `PHARMACY_SUBCLASS`es  with analgesics as an example.*

|        PHARMACY_CLASS        |              PHARMACY_SUBCLASS              | MEDICATIONs |
| :--------------------------: | :-----------------------------------------: | ----------: |
|    Analgesics-nonnarcotic    |           Analgesic Combinations            |        1178 |
|    Analgesics-nonnarcotic    |              Analgesics Other               |        1610 |
|    Analgesics-nonnarcotic    |     Analgesics-Peptide Channel Blockers     |          11 |
|        Anti-rheumatic        | Analgesics - Anti-inflammatory Combinations |          68 |
|        Dermatological        |            Analgesics - Topical             |         382 |
| Misc. genitourinary products |             Urinary Analgesics              |         136 |
|             Otic             |               Otic Analgesics               |          27 |



## Confidential Information in Single-Patient `MEDICATION` Records

There are 1,464 `MEDICATION`s in our CDW whose `FULL_NAME` contains the substring “william'' and have been ordered for 0 or 1 patients, but 0 “william” orders that have been ordered for 2 or more patients. The same pattern holds for the substring “karen”.



## Factor Importance for Random Forest (RF) Training

*RxNav’s `rank` and `score` were both retained, along with the `rxcui.count` relevance measure. The RxCUI `frequency` and the `count`s and `frequencies` of the highly granular RxNorm atoms were dropped due to low importance and/or > 0.95 correlation with `rxcui.count`. The largely orthogonal `qgram`, `jaccard`, `jw` and `cosine` string similarities are retrained, but `lcs` and `lv` were not.*

|     feature     | Mean Decrease Gini | Relative importance |
| :-------------: | -----------------: | ------------------: |
|      score      |            14713.6 |               1.000 |
|      qgram      |             4837.0 |               0.329 |
|   rxcui.count   |             2668.4 |               0.181 |
| ~~rxcui.freq~~  |         ~~2581.6~~ |           ~~0.175~~ |
|     ~~lcs~~     |         ~~2370.5~~ |           ~~0.161~~ |
|     jaccard     |             2325.7 |               0.158 |
|       jw        |             2297.0 |               0.156 |
|     q.char      |             2272.3 |               0.154 |
|      rank       |             2092.0 |               0.142 |
|     q.words     |             1815.1 |               0.123 |
|     sr.char     |             1707.1 |               0.116 |
|     cosine      |             1630.3 |               0.111 |
|     TTY.sr      |             1577.5 |               0.107 |
|     ~~lv~~      |         ~~1437.0~~ |           ~~0.098~~ |
|    sr.words     |             1083.0 |               0.074 |
|     SAB.sr      |              736.8 |               0.050 |
| ~~rxaui.freq~~  |          ~~247.8~~ |           ~~0.017~~ |
| ~~rxaui.count~~ |          ~~245.7~~ |           ~~0.017~~ |



## Tuning of TMM RF

![img](https://lh6.googleusercontent.com/WUVinK_Gdn2NOCZw0nPE2-JwPonbCBTabiqUz3tR2SjqShjWzvZ98D0HS-sd-n1rI8Q6UM5qo5RkXepEJztC97zt3ZCZY0GoSUtv2zLjfcHH_6-WcVfv2ykxr158QqCpsGaViEs2)

## Software Libraries Required for TMM's R Scripts

These may have further dependencies on other R libraries or even system software. Installing with R's `install.packages` function will generally resolve the R library dependency tree. `RJDBC` depends on `rJava`, which in turn requires Java to be installed on the system.

- RJDBC
- ROCR
- caret
- config
- dplyr
- fields
- ggplot2 (optional)
- httr
- jsonlite
- plyr
- randomForest
- rdflib
- readr
- solrium
- splitstackshape
- stringdist
- stringr
- tibble
- tidyr
- uuid



## Notes on Individual Scripts & Related Files

All of TMM's R scripts first source `rxnav_med_mapping_setup.R`, which reads `rxnav_med_mapping.yaml` into a list called `config`. 

The training and prediction scripts require that RxNav-in-a-box is running and that `docker-compose.yml` has been modified to expose the MySQL/MariaDB port outside of the Docker environment, like this 

```yaml
ports:
  - "3307:3306"
```

The RF model, created by `rxnav_med_mapping_proximity_training_no_tuning.R`, is saved as `rxnav_med_mapping_rf.Rdata`. The number of random medications submitted to RxNav, and then used for training, is set with `config$approximate.row.count` and should be set in the  thousands. Bioinformaticians may find the process of searching RxNorm terms against other RxNorm terms, via RxNav, similar to all-vs-all BLASTs. The maximum number of search results returned (`maxEntries`) is currently set to 50 in two functions in `rxnav_med_mapping_setup.R`:  `approximateTerm` and `bulk.approximateTerm`. These will become parameters in `rxnav_med_mapping.yaml` by the next release.

RxNav’s `approximateTerm` REST endpoint returns RxNorm concept unique identifiers (CUIs), along with RxNorm atom unique identifiers (AUIs), and scores. The results are returned in score-ranked order. The RxAUIs are included because RxNorm aggregates drug names from multiple upstream sources. Each atom can have its own string value, but those are not included in the search results.

The TMM GitHub repository includes an RF tuning script, `rxnav_med_mapping_tuneup_followon.R`. It is included to show methods that can be used iteratively to tune the RF, in terms of factor correlation and importance, number of trees trained (`ntree`), and number of simultaneous predictors included in each tree (`mtry`). It is intended for use in an interactive environment like RStudio, not to be run from beginning to end from the command line. Tuning over a wide range of parameters with a large input set can take several hours.

`rxnav_med_mapping_proximity_classifier.R` performs the classification of medication strings from a CDW, etc. `MEDICATION` `FULL_NAME`s are always taken as input, as are `GENERIC_NAME`s, which are available for 21.3% of the MEDICATIONs, our CDW.



In order to load those results into a triplestore, the script saves them in a format compatible with [ROBOT](http://robot.obolibrary.org/). `med_mapping_robot.sh` is provided to save the user from typing in the two long ROBOT commands that generate the RDF. At this point, the expected input and output file names are hard-coded into the shell script.

TMM does not parse medication text inputs, so is not able to arithmetically compare concentrations like “10 mg in 50 ml” and “0.2 mg/ml”. Frequently both versions are in RxNorm’s list of synonyms. However, we have not compared how well TMM performs in this area compared to other solutions.

TMM scripts such as `rxnav_med_mapping_load_materialize_etc.R` will load public RDF files into the GraphDB repository, optimally from public web locations. Otherwise, users can pre-download those files to their local system and configure `my.import.urls` and `my.import.files` in `rxnav_med_mapping.yaml` accordingly.

The number of BioPortal mappings from `serialize_bioportal_mappings.R` is much smaller than the number of classified search results from `rxnav_med_mapping_proximity_classifier.R`, so the RDF conversion is performed in  `rxnav_med_mapping_load_materialize_etc.R`, instead of using ROBOT. 

### `defined_by` and `employment`

`rxnav_med_mapping_load_materialize_etc.R` also makes two kinds of convenience assertions, for use at query time:

- the `definedin` predicate is used to state which ontologies assert that a given term is an  `owl:Class`. This determination is made possible by the fact that TMM loads each pubic ontology and RDF knowledgebase into its own named graph.
- the `employment` predicate is used to state the general way in which a term is useful to TMM. 
  - The employment of each RxNorm term is identical to its RxNorm term type TTY). 
  - `active_ingredient` is asserted for ChEBI and DrOn molecular entities and `product` is asserted for DrOn entities when there are patterns like this relation between the `product` 'Acetaminophen Oral Tablet', `DRON:00020450` and the active_ingredient 'Acetaminophen' or 'Paracetamol' `CHEBI:46195` : `has_proper_part some (scattered molecular aggregate and (is bearer of some active ingredient) and (has granular part some Acetaminophen))`
  - The employment of selected roles borne by ChEBI `active_ingredients`, transitively up to 'role', `CHEBI:50906`, is asserted as `curated_role`. The selected roles were bootstrapped by hand examining those that are common among the `active_ingredients` in `products` that are present in our CDW.
  - ChEBI classes that bear one of the  `curated_role`s and have subClasses of their own, like 'statin', `CHEBI:87631` are assigned the employment `clinrel_structclass`, or clinically relevant structural classes.



## Solr Query for Finding URLs in TMM, Representing Terms that are Meaningful to a Clinician or Researcher

`http://<solr host:port>/solr/med_mapping_kb_labels_exp/select?defType=edismax&q=hmg%20co%20reductase%20inhibitor&qf=medlabel%20tokens`

Solr will likely return several matches, some additional application logic would be required to gather the user's choices. Logic like this is being present in the TURBO team's Carnival command-line tool and is being built into the TURBO/Carnival web interface.

## SPARQL Queries from any term with an employment to medications in the CDW

These queries could start with a term obtained with Solr (see above). The SPARQL queries can be found in  [TMM's GitHub repository](https://github.com/PennTURBO/med_mapping/tree/master/cohort_building_medmap_traversals). Those queries may travers ChEBI and DrOn, but they report the CDW medications as RxNorm terms.



## Medications from our CDW that are Classified as "statins"

[Back to top](#supplementary-information-about-the-turbo-medication-mapper--tmm---2020-05-25)

| order_id | source_full_name                                             | source_generic_name                                         | unique patient count | false positive for statins |
| -------- | ------------------------------------------------------------ | ----------------------------------------------------------- | -------------------- | -------------------------- |
| 48383    | ATORVASTATIN CALCIUM 40 MG PO TABS                           | Atorvastatin Calcium Tab 40 MG (Base Equivalent)            | 62112                |                            |
| 34696    | ATORVASTATIN CALCIUM 20 MG PO TABS                           | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 55500                |                            |
| 89834    | SIMVASTATIN 20 MG PO TABS                                    | Simvastatin Tab 20 MG                                       | 53133                |                            |
| 35539    | ATORVASTATIN CALCIUM 10 MG PO TABS                           | Atorvastatin Calcium Tab 10 MG (Base Equivalent)            | 47572                |                            |
| 90622    | SIMVASTATIN 40 MG PO TABS                                    | Simvastatin Tab 40 MG                                       | 43852                |                            |
| 123016   | atorvastatin -                                               |                                                             | 40937                |                            |
| 122503   | simvastatin -                                                |                                                             | 38931                |                            |
| 22785    | LIPITOR 10 MG PO TABS                                        | Atorvastatin Calcium Tab 10 MG (Base Equivalent)            | 32226                |                            |
| 124205   | ATORVASTATIN CALCIUM 80 MG PO TABS                           | Atorvastatin Calcium Tab 80 MG (Base Equivalent)            | 31949                |                            |
| 23905    | LIPITOR 20 MG PO TABS                                        | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 26600                |                            |
| 89316    | PRAVASTATIN SODIUM 40 MG PO TABS                             | Pravastatin Sodium Tab 40 MG                                | 23914                |                            |
| 88879    | SIMVASTATIN 10 MG PO TABS                                    | Simvastatin Tab 10 MG                                       | 20088                |                            |
| 132720   | ROSUVASTATIN CALCIUM 10 MG PO TABS                           | Rosuvastatin Calcium Tab 10 MG                              | 18654                |                            |
| 131985   | CRESTOR 10 MG PO TABS                                        | Rosuvastatin Calcium Tab 10 MG                              | 18320                |                            |
| 44225    | LIPITOR 40 MG PO TABS                                        | Atorvastatin Calcium Tab 40 MG (Base Equivalent)            | 18146                |                            |
| 88053    | PRAVASTATIN SODIUM 20 MG PO TABS                             | Pravastatin Sodium Tab 20 MG                                | 17872                |                            |
| 130978   | ROSUVASTATIN CALCIUM 20 MG PO TABS                           | Rosuvastatin Calcium Tab 20 MG                              | 16917                |                            |
| 121539   | rosuvastatin -                                               |                                                             | 14492                |                            |
| 133031   | ROSUVASTATIN CALCIUM 5 MG PO TABS                            | Rosuvastatin Calcium Tab 5 MG                               | 13846                |                            |
| 68253    | .Atorvastatin Tablet                                         |                                                             | 13752                |                            |
| 66007    | ZOCOR 20 MG PO TABS                                          | Simvastatin Tab 20 MG                                       | 13389                |                            |
| 131986   | CRESTOR 5 MG PO TABS                                         | Rosuvastatin Calcium Tab 5 MG                               | 12206                |                            |
| 132772   | CRESTOR 20 MG PO TABS                                        | Rosuvastatin Calcium Tab 20 MG                              | 11353                |                            |
| 67497    | ZOCOR 40 MG PO TABS                                          | Simvastatin Tab 40 MG                                       | 11074                |                            |
| 81895    | .Atorvastatin Tablet 20 mg                                   |                                                             | 10904                |                            |
| 123251   | pravastatin -                                                |                                                             | 10163                |                            |
| 2166555  | simvastatin 20 mg oral tablet                                | simvastatin 20 mg tablet                                    | 10033                |                            |
| 2164796  | atorvastatin 40 mg oral tablet                               | atorvastatin 40 mg tablet                                   | 9397                 |                            |
| 106690   | .Simvastatin Tablet                                          |                                                             | 9260                 |                            |
| 2161567  | simvastatin 40 mg oral tablet                                | simvastatin 40 mg tablet                                    | 9055                 |                            |
| 80287    | SIMVASTATIN 80 MG PO TABS                                    | Simvastatin Tab 80 MG                                       | 8650                 |                            |
| 2188242  | atorvastatin 80 mg oral tablet                               | atorvastatin 80 mg tablet                                   | 8405                 |                            |
| 131934   | ROSUVASTATIN CALCIUM 40 MG PO TABS                           | Rosuvastatin Calcium Tab 40 MG                              | 7676                 |                            |
| 83800    | LOVASTATIN 40 MG PO TABS                                     | Lovastatin Tab 40 MG                                        | 7619                 |                            |
| 43247    | .Simvastatin Tablet 40 mg                                    |                                                             | 7562                 |                            |
| 87639    | PRAVASTATIN SODIUM 10 MG PO TABS                             | Pravastatin Sodium Tab 10 MG                                | 7429                 |                            |
| 2162801  | atorvastatin 20 mg oral tablet                               | atorvastatin 20 mg tablet                                   | 7235                 |                            |
| 123949   | LIPITOR 80 MG PO TABS                                        | Atorvastatin Calcium Tab 80 MG (Base Equivalent)            | 7185                 |                            |
| 75088    | .Atorvastatin Tablet 10 mg                                   |                                                             | 6922                 |                            |
| 82845    | LOVASTATIN 20 MG PO TABS                                     | Lovastatin Tab 20 MG                                        | 6360                 |                            |
| 74267    | ZOCOR 10 MG PO TABS                                          | Simvastatin Tab 10 MG                                       | 6004                 |                            |
| 46756    | PRAVACHOL 40 MG PO TABS                                      | Pravastatin Sodium Tab 40 MG                                | 5711                 |                            |
| 127498   | PRAVASTATIN SODIUM 80 MG PO TABS                             | Pravastatin Sodium Tab 80 MG                                | 5632                 |                            |
| 2161803  | atorvastatin 10 mg oral tablet                               | atorvastatin 10 mg tablet                                   | 5496                 |                            |
| 40132    | .Simvastatin Tablet 20 mg                                    |                                                             | 5385                 |                            |
| 45981    | PRAVACHOL 20 MG PO TABS                                      | Pravastatin Sodium Tab 20 MG                                | 5232                 |                            |
| 5370012  | LIPITOR PO                                                   | Atorvastatin Calcium                                        | 5172                 |                            |
| 5368734  | SIMVASTATIN PO                                               | Simvastatin                                                 | 5105                 |                            |
| 133030   | CRESTOR 40 MG PO TABS                                        | Rosuvastatin Calcium Tab 40 MG                              | 4892                 |                            |
| 134805   | VYTORIN 10-40 MG PO TABS                                     | Ezetimibe-Simvastatin Tab 10-40 MG                          | 4778                 |                            |
| 133849   | VYTORIN 10-20 MG PO TABS                                     | Ezetimibe-Simvastatin Tab 10-20 MG                          | 4055                 |                            |
| 2183393  | pravastatin 40 mg oral tablet                                | pravastatin 40 mg tablet                                    | 3617                 |                            |
| 5354001  | CRESTOR PO                                                   | Rosuvastatin Calcium                                        | 3541                 |                            |
| 2160809  | Lipitor 40 mg oral tablet                                    | atorvastatin 40 mg tablet                                   | 3410                 |                            |
| 50035    | .Atorvastatin Tablet 80 mg                                   |                                                             | 3402                 |                            |
| 2187242  | Lipitor 20 mg oral tablet                                    | atorvastatin 20 mg tablet                                   | 3401                 |                            |
| 27255    | IMDUR 60 MG PO TAB SR 24HR                                   | Isosorbide Mononitrate Tab ER 24HR 60 MG                    | 3303                 | TRUE                       |
| 2186082  | simvastatin 10 mg oral tablet                                | simvastatin 10 mg tablet                                    | 3299                 |                            |
| 2161881  | Crestor 10 mg oral tablet                                    | rosuvastatin 10 mg tablet                                   | 3221                 |                            |
| 2183254  | Lipitor 10 mg oral tablet                                    | atorvastatin 10 mg tablet                                   | 3218                 |                            |
| 161474   | LIPITOR OR                                                   | Atorvastatin Calcium                                        | 2916                 |                            |
| 168351   | SIMVASTATIN OR                                               | Simvastatin                                                 | 2741                 |                            |
| 5354378  | ATORVASTATIN CALCIUM PO                                      | Atorvastatin Calcium                                        | 2741                 |                            |
| 2168029  | pravastatin 20 mg oral tablet                                | pravastatin 20 mg tablet                                    | 2733                 |                            |
| 80288    | ZOCOR 80 MG PO TABS                                          | Simvastatin Tab 80 MG                                       | 2422                 |                            |
| 88880    | SIMVASTATIN 5 MG PO TABS                                     | Simvastatin Tab 5 MG                                        | 2421                 |                            |
| 42662    | .Rosuvastatin Tablet                                         |                                                             | 2338                 |                            |
| 2166870  | Crestor 20 mg oral tablet                                    | rosuvastatin 20 mg tablet                                   | 2295                 |                            |
| 81861    | LOVASTATIN 10 MG PO TABS                                     | Lovastatin Tab 10 MG                                        | 2196                 |                            |
| 2160572  | simvastatin 80 mg oral tablet                                | simvastatin 80 mg tablet                                    | 2149                 |                            |
| 2165798  | Lipitor 80 mg oral tablet                                    | atorvastatin 80 mg tablet                                   | 2098                 |                            |
| 5359555  | PRAVASTATIN SODIUM PO                                        | Pravastatin Sodium                                          | 2003                 |                            |
| 44522    | PRAVACHOL 10 MG PO TABS                                      | Pravastatin Sodium Tab 10 MG                                | 1957                 |                            |
| 75753    | .Pravastatin Tablet 40 mg                                    |                                                             | 1829                 |                            |
| 2184287  | Crestor 5 mg oral tablet                                     | rosuvastatin 5 mg tablet                                    | 1812                 |                            |
| 113764   | .Simvastatin Tablet 10 mg                                    |                                                             | 1722                 |                            |
| 156265   | CRESTOR OR                                                   | Rosuvastatin Calcium                                        | 1671                 |                            |
| 135591   | VYTORIN 10-10 MG PO TABS                                     | Ezetimibe-Simvastatin Tab 10-10 MG                          | 1666                 |                            |
| 64510    | .Pravastatin Tablet 20 mg                                    |                                                             | 1551                 |                            |
| 128453   | PRAVACHOL 80 MG PO TABS                                      | Pravastatin Sodium Tab 80 MG                                | 1527                 |                            |
| 2183093  | Zocor 20 mg oral tablet                                      | simvastatin 20 mg tablet                                    | 1519                 |                            |
| 171459   | ZOCOR OR                                                     | Simvastatin                                                 | 1484                 |                            |
| 2160574  | Zocor 40 mg oral tablet                                      | simvastatin 40 mg tablet                                    | 1468                 |                            |
| 135592   | VYTORIN 10-80 MG PO TABS                                     | Ezetimibe-Simvastatin Tab 10-80 MG                          | 1457                 |                            |
| 125368   | LESCOL XL 80 MG PO TAB SR 24HR                               | Fluvastatin Sodium Tab ER 24 HR 80 MG (Base Equivalent)     | 1402                 |                            |
| 2186383  | Pravachol 40 mg oral tablet                                  | pravastatin 40 mg tablet                                    | 1369                 |                            |
| 2187081  | simvastatin tablet 40 mg                                     | simvastatin 40 mg tablet                                    | 1358                 |                            |
| 2174122  | lovastatin 40 mg oral tablet                                 | lovastatin 40 mg tablet                                     | 1352                 |                            |
| 87518    | .Pravastatin Tablet                                          |                                                             | 1331                 |                            |
| 2190281  | rosuvastatin 10 mg oral tablet                               | rosuvastatin 10 mg tablet                                   | 1277                 |                            |
| 2189374  | Pravachol 20 mg oral tablet                                  | pravastatin 20 mg tablet                                    | 1242                 |                            |
| 5373773  | ZOCOR PO                                                     | Simvastatin                                                 | 1199                 |                            |
| 2165877  | rosuvastatin 20 mg oral tablet                               | rosuvastatin 20 mg tablet                                   | 1179                 |                            |
| 2184286  | Crestor 40 mg oral tablet                                    | rosuvastatin 40 mg tablet                                   | 1165                 |                            |
| 2167513  | pravastatin 80 mg oral tablet                                | pravastatin 80 mg tablet                                    | 1126                 |                            |
| 3600044  | simvastatin 40 mg tablet                                     | simvastatin 40 mg tablet                                    | 1117                 |                            |
| 2186083  | simvastatin tablet 20 mg                                     | simvastatin 20 mg tablet                                    | 1104                 |                            |
| 134807   | EZETIMIBE-SIMVASTATIN 10-40 MG PO TABS                       | Ezetimibe-Simvastatin Tab 10-40 MG                          | 1040                 |                            |
| 2187433  | lovastatin 20 mg oral tablet                                 | lovastatin 20 mg tablet                                     | 1040                 |                            |
| 3600043  | simvastatin 20 mg tablet                                     | simvastatin 20 mg tablet                                    | 1019                 |                            |
| 133851   | EZETIMIBE-SIMVASTATIN 10-20 MG PO TABS                       | Ezetimibe-Simvastatin Tab 10-20 MG                          | 985                  |                            |
| 2179233  | simvastatin 40 mg oral tablet                                |                                                             | 969                  |                            |
| 2186382  | pravastatin 10 mg oral tablet                                | pravastatin 10 mg tablet                                    | 946                  |                            |
| 66850    | .Rosuvastatin Tablet 10 mg                                   |                                                             | 900                  |                            |
| 2178240  | simvastatin 20 mg oral tablet                                |                                                             | 875                  |                            |
| 42641    | .Niacin Tablet SR                                            |                                                             | 820                  | TRUE                       |
| 171316   | VYTORIN OR                                                   | Ezetimibe-Simvastatin                                       | 809                  |                            |
| 133488   | AMLODIPINE-ATORVASTATIN 10-10 MG PO TABS                     | Amlodipine Besylate-Atorvastatin Calcium Tab 10-10 MG       | 806                  |                            |
| 2189276  | rosuvastatin 5 mg oral tablet                                | rosuvastatin 5 mg tablet                                    | 757                  |                            |
| 1636001  | LIVALO 2 MG PO TABS                                          | Pitavastatin Calcium Tab 2 MG                               | 749                  |                            |
| 32851    | MEVACOR 20 MG PO TABS                                        | Lovastatin Tab 20 MG                                        | 746                  |                            |
| 1634004  | PITAVASTATIN CALCIUM 2 MG PO TABS                            | Pitavastatin Calcium Tab 2 MG                               | 744                  |                            |
| 2175727  | Lipitor tablet 20 mg                                         | atorvastatin                                                | 740                  |                            |
| 160604   | LOVASTATIN OR                                                | Lovastatin                                                  | 732                  |                            |
| 74268    | ZOCOR 5 MG PO TABS                                           | Simvastatin Tab 5 MG                                        | 725                  |                            |
| 2162036  | Lipitor tablet 10 mg                                         | atorvastatin                                                | 710                  |                            |
| 33793    | MEVACOR 40 MG PO TABS                                        | Lovastatin Tab 40 MG                                        | 691                  |                            |
| 129606   | LOVASTATIN ER 40 MG PO TAB SR 24HR                           | Lovastatin Tab ER 24HR 40 MG                                | 691                  |                            |
| 2165876  | rosuvastatin 40 mg oral tablet                               | rosuvastatin 40 mg tablet                                   | 685                  |                            |
| 61468    | .Ezetimibe-Simvastatin Tablet 10-20 mg                       |                                                             | 667                  |                            |
| 97251    | LESCOL 20 MG PO CAPS                                         | Fluvastatin Sodium Cap 20 MG (Base Equivalent)              | 656                  |                            |
| 98206    | LESCOL 40 MG PO CAPS                                         | Fluvastatin Sodium Cap 40 MG (Base Equivalent)              | 652                  |                            |
| 2163797  | atorvastatin tablet 80 mg                                    | atorvastatin 80 mg tablet                                   | 604                  |                            |
| 165531   | PRAVASTATIN SODIUM OR                                        | Pravastatin Sodium                                          | 601                  |                            |
| 3599050  | atorvastatin 80 mg tablet                                    | atorvastatin 80 mg tablet                                   | 600                  |                            |
| 3605054  | atorvastatin 40 mg tablet                                    | atorvastatin 40 mg tablet                                   | 572                  |                            |
| 2169387  | Vytorin 10 mg-40 mg oral tablet                              | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 565                  |                            |
| 2187079  | simvastatin tablet 80 mg                                     | simvastatin 80 mg tablet                                    | 556                  |                            |
| 2177883  | Zocor tablet 40 mg                                           | simvastatin                                                 | 555                  |                            |
| 5369648  | VYTORIN PO                                                   | Ezetimibe-Simvastatin                                       | 547                  |                            |
| 5362148  | LOVASTATIN PO                                                | Lovastatin                                                  | 545                  |                            |
| 2189074  | Zocor 10 mg oral tablet                                      | simvastatin 10 mg tablet                                    | 539                  |                            |
| 63347    | .Rosuvastatin Tablet 20 mg                                   |                                                             | 537                  |                            |
| 2189236  | Lipitor tablet 10 mg                                         | atorvastatin 10 mg tablet                                   | 525                  |                            |
| 2161039  | Lipitor tablet 40 mg                                         | atorvastatin                                                | 516                  |                            |
| 2160811  | Lipitor tablet 20 mg                                         | atorvastatin 20 mg tablet                                   | 510                  |                            |
| 61781    | .Pravastatin Tablet 10 mg                                    |                                                             | 488                  |                            |
| 135229   | AMLODIPINE-ATORVASTATIN 5-10 MG PO TABS                      | Amlodipine Besylate-Atorvastatin Calcium Tab 5-10 MG        | 488                  |                            |
| 2168393  | Vytorin 10 mg-20 mg oral tablet                              | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 473                  |                            |
| 130747   | LOVASTATIN ER 20 MG PO TAB SR 24HR                           | Lovastatin Tab ER 24HR 20 MG                                | 466                  |                            |
| 1631001  | PITAVASTATIN CALCIUM 1 MG PO TABS                            | Pitavastatin Calcium Tab 1 MG                               | 463                  |                            |
| 128397   | ADVICOR 500-20 MG PO TAB SR 24HR                             | Niacin-Lovastatin Tab ER 24HR 500-20 MG                     | 446                  |                            |
| 2161804  | atorvastatin tablet 20 mg                                    | atorvastatin 20 mg tablet                                   | 446                  |                            |
| 2185247  | Lipitor tablet 40 mg                                         | atorvastatin 40 mg tablet                                   | 443                  |                            |
| 2162799  | atorvastatin tablet 40 mg                                    | atorvastatin 40 mg tablet                                   | 429                  |                            |
| 133524   | CADUET 5-10 MG PO TABS                                       | Amlodipine Besylate-Atorvastatin Calcium Tab 5-10 MG        | 427                  |                            |
| 2159255  | Zocor tablet 20 mg                                           | simvastatin                                                 | 414                  |                            |
| 1633007  | PITAVASTATIN CALCIUM 4 MG PO TABS                            | Pitavastatin Calcium Tab 4 MG                               | 409                  |                            |
| 2160046  | Lipitor tablet 80 mg                                         | atorvastatin                                                | 378                  |                            |
| 133525   | CADUET 10-20 MG PO TABS                                      | Amlodipine Besylate-Atorvastatin Calcium Tab 10-20 MG       | 375                  |                            |
| 5358552  | PRAVACHOL PO                                                 | Pravastatin Sodium                                          | 374                  |                            |
| 43540    | .Rosuvastatin Tablet 5 mg                                    |                                                             | 367                  |                            |
| 134480   | CADUET 10-10 MG PO TABS                                      | Amlodipine Besylate-Atorvastatin Calcium Tab 10-10 MG       | 367                  |                            |
| 2166027  | atorvastatin                                                 | atorvastatin                                                | 361                  |                            |
| 2183679  | Pravachol 80 mg oral tablet                                  | pravastatin 80 mg tablet                                    | 360                  |                            |
| 3601038  | atorvastatin 20 mg tablet                                    | atorvastatin 20 mg tablet                                   | 357                  |                            |
| 2166792  | atorvastatin tablet 10 mg                                    | atorvastatin 10 mg tablet                                   | 346                  |                            |
| 2189275  | Crestor tablet 10 mg                                         | rosuvastatin 10 mg tablet                                   | 346                  |                            |
| 3681014  | pravastatin 40 mg tablet                                     | pravastatin 40 mg tablet                                    | 341                  |                            |
| 135593   | EZETIMIBE-SIMVASTATIN 10-10 MG PO TABS                       | Ezetimibe-Simvastatin Tab 10-10 MG                          | 340                  |                            |
| 135267   | CADUET 5-20 MG PO TABS                                       | Amlodipine Besylate-Atorvastatin Calcium Tab 5-20 MG        | 337                  |                            |
| 2183092  | simvastatin tablet 10 mg                                     | simvastatin 10 mg tablet                                    | 335                  |                            |
| 98134    | FLUVASTATIN SODIUM 20 MG PO CAPS                             | Fluvastatin Sodium Cap 20 MG (Base Equivalent)              | 326                  |                            |
| 2163560  | Zocor 80 mg oral tablet                                      | simvastatin 80 mg tablet                                    | 323                  |                            |
| 164744   | PRAVACHOL OR                                                 | Pravastatin Sodium                                          | 322                  |                            |
| 2180877  | simvastatin tablet 40 mg                                     | simvastatin                                                 | 311                  |                            |
| 1632003  | LIVALO 4 MG PO TABS                                          | Pitavastatin Calcium Tab 4 MG                               | 304                  |                            |
| 2172017  | pravastatin tablet 40 mg                                     | pravastatin 40 mg tablet                                    | 300                  |                            |
| 1638001  | LIVALO 1 MG PO TABS                                          | Pitavastatin Calcium Tab 1 MG                               | 298                  |                            |
| 3601056  | simvastatin 10 mg tablet                                     | simvastatin 10 mg tablet                                    | 297                  |                            |
| 2183094  | simvastatin 5 mg oral tablet                                 | simvastatin 5 mg tablet                                     | 294                  |                            |
| 2159254  | simvastatin                                                  | simvastatin                                                 | 288                  |                            |
| 2184087  | Zocor tablet 40 mg                                           | simvastatin 40 mg tablet                                    | 287                  |                            |
| 2180241  | simvastatin 80 mg oral tablet                                |                                                             | 286                  |                            |
| 2162800  | Lipitor tablet 80 mg                                         | atorvastatin 80 mg tablet                                   | 284                  |                            |
| 2164561  | Zocor tablet 20 mg                                           | simvastatin 20 mg tablet                                    | 271                  |                            |
| 2166038  | lipitor                                                      |                                                             | 270                  |                            |
| 2183592  | ezetimibe-simvastatin 10 mg-40 mg oral tablet                | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 268                  |                            |
| 2185385  | Pravachol 10 mg oral tablet                                  | pravastatin 10 mg tablet                                    | 267                  |                            |
| 135268   | CADUET 10-40 MG PO TABS                                      | Amlodipine Besylate-Atorvastatin Calcium Tab 10-40 MG       | 262                  |                            |
| 134444   | AMLODIPINE-ATORVASTATIN 10-20 MG PO TABS                     | Amlodipine Besylate-Atorvastatin Calcium Tab 10-20 MG       | 261                  |                            |
| 127864   | LOVASTATIN ER 60 MG PO TAB SR 24HR                           | Lovastatin Tab ER 24HR 60 MG                                | 259                  |                            |
| 2170536  | pravastatin 40 mg oral tablet                                |                                                             | 259                  |                            |
| 2143113  | Lipitor 40 mg oral tablet                                    |                                                             | 257                  |                            |
| 2171014  | lovastatin 10 mg oral tablet                                 | lovastatin 10 mg tablet                                     | 257                  |                            |
| 2129764  | atorvastatin 80 mg oral tablet                               |                                                             | 256                  |                            |
| 3601037  | atorvastatin 10 mg tablet                                    | atorvastatin 10 mg tablet                                   | 256                  |                            |
| 126155   | FLUVASTATIN SODIUM ER 80 MG PO TAB SR 24HR                   | Fluvastatin Sodium Tab ER 24 HR 80 MG (Base Equivalent)     | 255                  |                            |
| 2156287  | simvastatin 10 mg oral tablet                                |                                                             | 255                  |                            |
| 2182878  | simvastatin tablet 20 mg                                     | simvastatin                                                 | 245                  |                            |
| 2143112  | Lipitor 20 mg oral tablet                                    |                                                             | 244                  |                            |
| 2160223  | Pravachol tablet 20 mg                                       | pravastatin                                                 | 233                  |                            |
| 2176720  | atorvastatin tablet 20 mg                                    | atorvastatin                                                | 229                  |                            |
| 875032   | .ezetimibe-simvastatin 10-20 mg -                            |                                                             | 227                  |                            |
| 172203   | SIMCOR 500-20 MG PO TAB SR 24HR                              | Niacin-Simvastatin Tab ER 24HR 500-20 MG                    | 226                  |                            |
| 2188580  | ezetimibe-simvastatin 10 mg-20 mg oral tablet                | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 224                  |                            |
| 96813    | FLUVASTATIN SODIUM 40 MG PO CAPS                             | Fluvastatin Sodium Cap 40 MG (Base Equivalent)              | 223                  |                            |
| 2162047  | Lipitor 10 mg oral tablet                                    |                                                             | 223                  |                            |
| 135594   | EZETIMIBE-SIMVASTATIN 10-80 MG PO TABS                       | Ezetimibe-Simvastatin Tab 10-80 MG                          | 220                  |                            |
| 3615023  | Crestor 10 mg tablet                                         | rosuvastatin 10 mg tablet                                   | 220                  |                            |
| 2134765  | atorvastatin 40 mg oral tablet                               |                                                             | 218                  |                            |
| 2181714  | atorvastatin tablet 10 mg                                    | atorvastatin                                                | 217                  |                            |
| 2189075  | Zocor 20 mg tablet oral                                      | simvastatin 20 mg tablet                                    | 217                  |                            |
| 15835938 | SIMVASTATIN 10 MG PO TABLET - CCH                            | Simvastatin Tab 10 MG                                       | 216                  |                            |
| 58984    | .Sodium Hypochlorite Soln0.13% (1/4 Stg)                     |                                                             | 215                  | TRUE                       |
| 133487   | AMLODIPINE-ATORVASTATIN 5-20 MG PO TABS                      | Amlodipine Besylate-Atorvastatin Calcium Tab 5-20 MG        | 212                  |                            |
| 2174017  | Pravachol tablet 40 mg                                       | pravastatin 40 mg tablet                                    | 211                  |                            |
| 135231   | AMLODIPINE-ATORVASTATIN 10-40 MG PO TABS                     | Amlodipine Besylate-Atorvastatin Calcium Tab 10-40 MG       | 208                  |                            |
| 3630069  | Lipitor 20 mg tablet                                         | atorvastatin 20 mg tablet                                   | 207                  |                            |
| 3601059  | Lipitor 10 mg tablet                                         | atorvastatin 10 mg tablet                                   | 204                  |                            |
| 5364133  | LIVALO PO                                                    | Pitavastatin Calcium                                        | 198                  |                            |
| 3648035  | Lipitor 40 mg tablet                                         | atorvastatin 40 mg tablet                                   | 196                  |                            |
| 2156837  | Zocor 40 mg oral tablet                                      |                                                             | 192                  |                            |
| 2140078  | Crestor 10 mg oral tablet                                    |                                                             | 191                  |                            |
| 2165034  | Lipitor                                                      | atorvastatin                                                | 191                  |                            |
| 2127596  | atorvastatin 20 mg oral tablet                               |                                                             | 188                  |                            |
| 2186245  | Lipitor 20 mg tablet oral                                    | atorvastatin 20 mg tablet                                   | 188                  |                            |
| 2172381  | Vytorin tablet 10 mg-40 mg                                   | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 187                  |                            |
| 2163798  | Lipitor 10 mg tablet oral                                    | atorvastatin 10 mg tablet                                   | 186                  |                            |
| 2169128  | lovastatin tablet 40 mg                                      | lovastatin 40 mg tablet                                     | 185                  |                            |
| 2181613  | Zocor 20 mg oral tablet                                      |                                                             | 184                  |                            |
| 5353101  | AMLODIPINE-ATORVASTATIN PO                                   | amLODIPine-Atorvastatin                                     | 184                  |                            |
| 127442   | ADVICOR 1000-20 MG PO TAB SR 24HR                            | Niacin-Lovastatin Tab ER 24HR 1000-20 MG                    | 182                  |                            |
| 3670024  | pravastatin 20 mg tablet                                     | pravastatin 20 mg tablet                                    | 176                  |                            |
| 2178238  | simvastatin                                                  |                                                             | 166                  |                            |
| 134481   | CADUET 5-40 MG PO TABS                                       | Amlodipine Besylate-Atorvastatin Calcium Tab 5-40 MG        | 164                  |                            |
| 2182715  | atorvastatin tablet 40 mg                                    | atorvastatin                                                | 163                  |                            |
| 136185   | AMLODIPINE-ATORVASTATIN 2.5-10 MG PO TABS                    | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-10 MG      | 160                  |                            |
| 2187281  | Crestor tablet 20 mg                                         | rosuvastatin 20 mg tablet                                   | 159                  |                            |
| 3617015  | Crestor 20 mg tablet                                         | rosuvastatin 20 mg tablet                                   | 159                  |                            |
| 151994   | CADUET OR                                                    | amLODIPine-Atorvastatin                                     | 156                  |                            |
| 2181640  | Vytorin tablet 10 mg-40 mg                                   | ezetimibe-simvastatin                                       | 156                  |                            |
| 2185386  | Pravachol tablet 20 mg                                       | pravastatin 20 mg tablet                                    | 156                  |                            |
| 2167387  | Vytorin 10 mg-80 mg oral tablet                              | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 155                  |                            |
| 2172541  | pravastatin 20 mg oral tablet                                |                                                             | 154                  |                            |
| 2183294  | Crestor tablet 5 mg                                          | rosuvastatin 5 mg tablet                                    | 152                  |                            |
| 2187380  | pravastatin tablet 20 mg                                     | pravastatin 20 mg tablet                                    | 152                  |                            |
| 2148110  | Lipitor 80 mg oral tablet                                    |                                                             | 150                  |                            |
| 2164249  | Zocor tablet 80 mg                                           | simvastatin                                                 | 150                  |                            |
| 43939    | .Ezetimibe-Simvastatin Tablet 10-10 mg                       |                                                             | 148                  |                            |
| 2190579  | Vytorin 10 mg-10 mg oral tablet                              | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 148                  |                            |
| 3603059  | Pravachol 40 mg tablet                                       | pravastatin 40 mg tablet                                    | 146                  |                            |
| 60597    | .Simvastatin Tablet 5 mg                                     |                                                             | 143                  |                            |
| 15056067 | PRAVASTATIN SODIUM 20 MG PO TABLET - CCH                     | Pravastatin Sodium Tab 40 MG                                | 134                  |                            |
| 2138862  | Crestor 20 mg oral tablet                                    |                                                             | 133                  |                            |
| 3610033  | pravastatin 80 mg tablet                                     | pravastatin 80 mg tablet                                    | 133                  |                            |
| 65219    | .Sodium Hypochlorite Soln0.263%(1/2 Stg)                     |                                                             | 132                  | TRUE                       |
| 2159039  | atorvastatin tablet 80 mg                                    | atorvastatin                                                | 132                  |                            |
| 2184439  | lovastatin tablet 20 mg                                      | lovastatin 20 mg tablet                                     | 132                  |                            |
| 2132582  | atorvastatin 10 mg oral tablet                               |                                                             | 131                  |                            |
| 2166791  | Lipitor 40 mg tablet oral                                    | atorvastatin 40 mg tablet                                   | 130                  |                            |
| 2179846  | pravastatin                                                  | pravastatin                                                 | 127                  |                            |
| 134443   | AMLODIPINE-ATORVASTATIN 5-40 MG PO TABS                      | Amlodipine Besylate-Atorvastatin Calcium Tab 5-40 MG        | 126                  |                            |
| 2164066  | Crestor                                                      | rosuvastatin                                                | 126                  |                            |
| 2166214  | lovastatin 40 mg oral tablet                                 |                                                             | 126                  |                            |
| 31895    | MEVACOR 10 MG PO TABS                                        | Lovastatin Tab 10 MG                                        | 122                  |                            |
| 3636012  | simvastatin 80 mg tablet                                     | simvastatin 80 mg tablet                                    | 121                  |                            |
| 3604044  | Zocor 40 mg tablet                                           | simvastatin 40 mg tablet                                    | 120                  |                            |
| 3604046  | Lipitor 80 mg tablet                                         | atorvastatin 80 mg tablet                                   | 120                  |                            |
| 2162069  | Crestor tablet 10 mg                                         | rosuvastatin                                                | 119                  |                            |
| 2176618  | zocor                                                        |                                                             | 119                  |                            |
| 171946   | SIMCOR 1000-20 MG PO TAB SR 24HR                             | Niacin-Simvastatin Tab ER 24HR 1000-20 MG                   | 118                  |                            |
| 2173366  | Lescol XL 80 mg oral tablet, extended release                | fluvastatin 80 mg tablet, extended release                  | 118                  |                            |
| 2166205  | Pravachol tablet 40 mg                                       | pravastatin                                                 | 117                  |                            |
| 3717012  | Crestor 5 mg tablet                                          | rosuvastatin 5 mg tablet                                    | 117                  |                            |
| 2164248  | simvastatin tablet 80 mg                                     | simvastatin                                                 | 115                  |                            |
| 2138863  | Crestor 5 mg oral tablet                                     |                                                             | 113                  |                            |
| 2186084  | Zocor 40 mg tablet oral                                      | simvastatin 40 mg tablet                                    | 113                  |                            |
| 3603040  | Zocor 20 mg tablet                                           | simvastatin 20 mg tablet                                    | 112                  |                            |
| 3607036  | lovastatin 40 mg tablet                                      | lovastatin 40 mg tablet                                     | 108                  |                            |
| 2182853  | pravastatin tablet 40 mg                                     | pravastatin                                                 | 105                  |                            |
| 2189574  | ezetimibe-simvastatin 10 mg-80 mg oral tablet                | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 105                  |                            |
| 2178880  | Zocor tablet 10 mg                                           | simvastatin                                                 | 104                  |                            |
| 2179634  | Vytorin tablet 10 mg-20 mg                                   | ezetimibe-simvastatin                                       | 104                  |                            |
| 2165561  | Zocor tablet 80 mg                                           | simvastatin 80 mg tablet                                    | 103                  |                            |
| 160458   | LESCOL OR                                                    | Fluvastatin Sodium                                          | 102                  |                            |
| 2169548  | pravastatin 80 mg oral tablet                                |                                                             | 101                  |                            |
| 2174540  | Pravachol 40 mg oral tablet                                  |                                                             | 100                  |                            |
| 2184585  | Vytorin tablet 10 mg-20 mg                                   | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 100                  |                            |
| 2136858  | crestor                                                      |                                                             | 98                   |                            |
| 2170502  | pravastatin tablet 80 mg                                     | pravastatin 80 mg tablet                                    | 95                   |                            |
| 76684    | .Ezetimibe-Simvastatin Tablet                                |                                                             | 86                   |                            |
| 2174501  | lovastatin 40 mg oral tablet, extended release               | lovastatin 40 mg tablet, extended release                   | 86                   |                            |
| 3637004  | Crestor 40 mg tablet                                         | rosuvastatin 40 mg tablet                                   | 86                   |                            |
| 2160573  | Zocor tablet 10 mg                                           | simvastatin 10 mg tablet                                    | 83                   |                            |
| 3645011  | Pravachol 20 mg tablet                                       | pravastatin 20 mg tablet                                    | 83                   |                            |
| 2164797  | Lipitor 80 mg tablet oral                                    | atorvastatin 80 mg tablet                                   | 81                   |                            |
| 5369358  | ROSUVASTATIN CALCIUM PO                                      | Rosuvastatin Calcium                                        | 81                   |                            |
| 2142857  | Crestor 40 mg oral tablet                                    |                                                             | 80                   |                            |
| 134482   | CADUET 10-80 MG PO TABS                                      | Amlodipine Besylate-Atorvastatin Calcium Tab 10-80 MG       | 79                   |                            |
| 164117   | NIACIN (ANTIHYPERLIPIDEMIC) OR                               | Niacin (Antihyperlipidemic)                                 | 78                   | TRUE                       |
| 2159186  | lovastatin tablet 40 mg                                      | lovastatin                                                  | 78                   |                            |
| 3604074  | Livalo 2 mg oral tablet                                      | pitavastatin 2 mg tablet                                    | 78                   |                            |
| 140629   | ADVICOR 1000-40 MG PO TAB SR 24HR                            | Niacin-Lovastatin Tab ER 24HR 1000-40 MG                    | 77                   |                            |
| 2159881  | Crestor tablet 40 mg                                         | rosuvastatin 40 mg tablet                                   | 77                   |                            |
| 2176858  | pravastatin tablet 20 mg                                     | pravastatin                                                 | 77                   |                            |
| 3731011  | lovastatin 20 mg tablet                                      | lovastatin 20 mg tablet                                     | 77                   |                            |
| 5355853  | CADUET PO                                                    | amLODIPine-Atorvastatin                                     | 77                   |                            |
| 2147141  | lovastatin 20 mg oral tablet                                 |                                                             | 73                   |                            |
| 3822015  | rosuvastatin 10 mg tablet                                    | rosuvastatin 10 mg tablet                                   | 72                   |                            |
| 5360301  | NIACIN (ANTIHYPERLIPIDEMIC) PO                               | Niacin (Antihyperlipidemic)                                 | 72                   | TRUE                       |
| 2176883  | simvastatin tablet 10 mg                                     | simvastatin                                                 | 71                   |                            |
| 2161566  | Zocor 10 mg tablet oral                                      | simvastatin 10 mg tablet                                    | 69                   |                            |
| 15835951 | INVESTIGATIONAL PITAVASTATIN 4 MG PO TABS OR PLACEBO         |                                                             | 69                   |                            |
| 133691   | ALTOPREV 60 MG PO TAB SR 24HR                                | Lovastatin Tab ER 24HR 60 MG                                | 67                   |                            |
| 2171510  | Pravachol tablet 80 mg                                       | pravastatin 80 mg tablet                                    | 65                   |                            |
| 2199017  | rosuvastatin 10 mg oral tablet                               |                                                             | 63                   |                            |
| 2185667  | lovastatin 20 mg oral tablet, extended release               | lovastatin 20 mg tablet, extended release                   | 61                   |                            |
| 151215   | ADVICOR OR                                                   |                                                             | 60                   |                            |
| 172287   | SIMCOR OR                                                    |                                                             | 60                   |                            |
| 133489   | AMLODIPINE-ATORVASTATIN 10-80 MG PO TABS                     | Amlodipine Besylate-Atorvastatin Calcium Tab 10-80 MG       | 59                   |                            |
| 2170359  | fluvastatin 80 mg oral tablet, extended release              | fluvastatin 80 mg tablet, extended release                  | 59                   |                            |
| 2189573  | ezetimibe-simvastatin 10 mg-10 mg oral tablet                | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 59                   |                            |
| 2171542  | Pravachol 20 mg oral tablet                                  |                                                             | 58                   |                            |
| 2187379  | Pravachol tablet 10 mg                                       | pravastatin 10 mg tablet                                    | 58                   |                            |
| 2175627  | Zocor 80 mg oral tablet                                      |                                                             | 57                   |                            |
| 2181548  | Vytorin 10 mg-40 mg oral tablet                              |                                                             | 57                   |                            |
| 3811013  | rosuvastatin 20 mg tablet                                    | rosuvastatin 20 mg tablet                                   | 57                   |                            |
| 2155164  | rosuvastatin 20 mg oral tablet                               |                                                             | 56                   |                            |
| 2163180  | lovastatin                                                   | lovastatin                                                  | 56                   |                            |
| 2178615  | Zocor 10 mg oral tablet                                      |                                                             | 56                   |                            |
| 2190661  | Altoprev 20 mg oral tablet, extended release                 | lovastatin 20 mg tablet, extended release                   | 55                   |                            |
| 5358829  | LESCOL PO                                                    | Fluvastatin Sodium                                          | 55                   |                            |
| 2149871  | pravastatin 10 mg oral tablet                                |                                                             | 54                   |                            |
| 2183392  | pravastatin tablet 10 mg                                     | pravastatin 10 mg tablet                                    | 53                   |                            |
| 2185702  | fluvastatin 40 mg oral capsule                               | fluvastatin 40 mg capsule                                   | 53                   |                            |
| 2190082  | Zocor 5 mg oral tablet                                       | simvastatin 5 mg tablet                                     | 53                   |                            |
| 2178550  | vytorin                                                      |                                                             | 52                   |                            |
| 873032   | .ezetimibe-simvastatin 10-10 mg -                            |                                                             | 50                   |                            |
| 132561   | CORAL CALCIUM 500 MG PO CAPS                                 | Coral Calcium Cap 500 MG (187.5 MG Elemental Ca)            | 48                   |                            |
| 2171381  | amlodipine-atorvastatin 10 mg-20 mg oral tablet              | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 48                   |                            |
| 2185440  | Mevacor 40 mg oral tablet                                    | lovastatin 40 mg tablet                                     | 48                   |                            |
| 2185586  | Vytorin tablet 10 mg-80 mg                                   | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 48                   |                            |
| 6537016  | pitavastatin 2 mg oral tablet                                | pitavastatin 2 mg tablet                                    | 48                   |                            |
| 2143152  | lovastatin                                                   |                                                             | 47                   |                            |
| 2127770  | atorvastatin                                                 |                                                             | 46                   |                            |
| 2175845  | lovastatin tablet 20 mg                                      | lovastatin                                                  | 46                   |                            |
| 136183   | CADUET 2.5-10 MG PO TABS                                     | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-10 MG      | 45                   |                            |
| 2155868  | Vytorin tablet 10 mg-80 mg                                   | ezetimibe-simvastatin                                       | 45                   |                            |
| 2162251  | Zocor                                                        | simvastatin                                                 | 45                   |                            |
| 3611029  | Pravachol 10 mg tablet                                       | pravastatin 10 mg tablet                                    | 45                   |                            |
| 2168390  | amlodipine-atorvastatin 5 mg-20 mg oral tablet               | amLODIPine-atorvastatin 5 mg-20 mg tablet                   | 44                   |                            |
| 2169384  | amLODIPine-atorvastatin 10 mg-10 mg oral tablet              | amLODIPine-atorvastatin 10 mg-10 mg tablet                  | 44                   |                            |
| 2185087  | simvastatin 40 mg tablet oral                                | simvastatin 40 mg tablet                                    | 44                   |                            |
| 2185287  | rosuvastatin tablet 10 mg                                    | rosuvastatin 10 mg tablet                                   | 44                   |                            |
| 10674488 | atorvastatin 80 mg oral tablet                               | atorvastatin                                                | 44                   |                            |
| 2190380  | Pravachol 20 mg tablet oral                                  | pravastatin 20 mg tablet                                    | 43                   |                            |
| 3705012  | pravastatin 10 mg tablet                                     | pravastatin 10 mg tablet                                    | 43                   |                            |
| 133690   | ALTOPREV 40 MG PO TAB SR 24HR                                | Lovastatin Tab ER 24HR 40 MG                                | 42                   |                            |
| 2150868  | pravastatin                                                  |                                                             | 42                   |                            |
| 2157164  | rosuvastatin 5 mg oral tablet                                |                                                             | 42                   |                            |
| 2159566  | Zocor 80 mg tablet oral                                      | simvastatin 80 mg tablet                                    | 42                   |                            |
| 2170533  | pravachol                                                    |                                                             | 42                   |                            |
| 4167015  | rosuvastatin 40 mg tablet                                    | rosuvastatin 40 mg tablet                                   | 42                   |                            |
| 4490076  | Livalo 4 mg oral tablet                                      | pitavastatin 4 mg tablet                                    | 42                   |                            |
| 57953    | BAYCOL TABS 0.3 MG OR                                        | Cerivastatin Sodium Tab 0.3 MG                              | 41                   |                            |
| 2188381  | pravastatin 20 mg tablet oral                                | pravastatin 20 mg tablet                                    | 41                   |                            |
| 128398   | NIACIN-LOVASTATIN ER 500-20 MG PO TAB SR 24HR                | Niacin-Lovastatin Tab ER 24HR 500-20 MG                     | 40                   |                            |
| 2178667  | Lescol XL tablet, extended release 80 mg                     | fluvastatin                                                 | 40                   |                            |
| 2184386  | Pravachol 40 mg tablet oral                                  | pravastatin 40 mg tablet                                    | 40                   |                            |
| 2161072  | Crestor tablet 5 mg                                          | rosuvastatin                                                | 39                   |                            |
| 2161216  | Pravachol tablet 10 mg                                       | pravastatin                                                 | 39                   |                            |
| 2162213  | Pravachol                                                    | pravastatin                                                 | 39                   |                            |
| 2164876  | rosuvastatin tablet 20 mg                                    | rosuvastatin 20 mg tablet                                   | 39                   |                            |
| 2170116  | Mevacor 20 mg oral tablet                                    | lovastatin 20 mg tablet                                     | 39                   |                            |
| 2190242  | atorvastatin 20 mg tablet oral                               | atorvastatin 20 mg tablet                                   | 39                   |                            |
| 3670014  | Zocor 10 mg tablet                                           | simvastatin 10 mg tablet                                    | 39                   |                            |
| 178638   | CVS CALCIUM ALGINATE 4"X4" EX MISC                           | Calcium Alginate Wound Dressing                             | 38                   | TRUE                       |
| 2179542  | Vytorin 10 mg-20 mg oral tablet                              |                                                             | 38                   |                            |
| 3628069  | Pravachol 80 mg tablet                                       | pravastatin 80 mg tablet                                    | 38                   |                            |
| 3636007  | Vytorin 10 mg-40 mg tablet                                   | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 38                   |                            |
| 2152947  | Lescol capsule 40 mg                                         | fluvastatin                                                 | 37                   |                            |
| 2184380  | lovastatin tablet 10 mg                                      | lovastatin 10 mg tablet                                     | 37                   |                            |
| 2186699  | Lescol 40 mg oral capsule                                    | fluvastatin 40 mg capsule                                   | 37                   |                            |
| 4160082  | rosuvastatin 5 mg tablet                                     | rosuvastatin 5 mg tablet                                    | 37                   |                            |
| 5372740  | SIMCOR PO                                                    |                                                             | 37                   |                            |
| 133526   | CADUET 5-80 MG PO TABS                                       | Amlodipine Besylate-Atorvastatin Calcium Tab 5-80 MG        | 36                   |                            |
| 2160233  | Pravachol tablet 80 mg                                       | pravastatin                                                 | 36                   |                            |
| 172202   | NIACIN-SIMVASTATIN ER 500-20 MG PO TAB SR 24HR               | Niacin-Simvastatin Tab ER 24HR 500-20 MG                    | 35                   |                            |
| 2173378  | amlodipine-atorvastatin 10 mg-40 mg oral tablet              | amLODIPine-atorvastatin 10 mg-40 mg tablet                  | 35                   |                            |
| 8773061  | INVESTIGATIONAL ATORVASTATIN 40 MG TABS                      | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 35                   |                            |
| 2167386  | ezetimibe-simvastatin tablet 10 mg-20 mg                     | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 34                   |                            |
| 2176839  | lovastatin tablet, extended release 40 mg                    | lovastatin                                                  | 34                   |                            |
| 2188380  | Pravachol 10 mg tablet oral                                  | pravastatin 10 mg tablet                                    | 34                   |                            |
| 5470041  | INVESTIGATIONAL ATORVASTATIN 20 MG TABS                      | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 34                   |                            |
| 152570   | ATORVASTATIN CALCIUM OR                                      | Atorvastatin Calcium                                        | 33                   |                            |
| 2185086  | simvastatin 20 mg tablet oral                                | simvastatin 20 mg tablet                                    | 33                   |                            |
| 2190576  | amLODIPine-atorvastatin 5 mg-10 mg oral tablet               | amLODIPine-atorvastatin 5 mg-10 mg tablet                   | 33                   |                            |
| 2317006  | Pravachol 10 mg oral tablet                                  |                                                             | 33                   |                            |
| 3607032  | simvastatin 5 mg tablet                                      | simvastatin 5 mg tablet                                     | 33                   |                            |
| 129184   | ADVICOR 750-20 MG PO TAB SR 24HR                             | Niacin-Lovastatin Tab ER 24HR 750-20 MG                     | 32                   |                            |
| 135230   | AMLODIPINE-ATORVASTATIN 5-80 MG PO TABS                      | Amlodipine Besylate-Atorvastatin Calcium Tab 5-80 MG        | 32                   |                            |
| 2175652  | Vytorin                                                      | ezetimibe-simvastatin                                       | 32                   |                            |
| 3648040  | Vytorin 10 mg-20 mg tablet                                   | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 32                   |                            |
| 127443   | NIACIN-LOVASTATIN ER 1000-20 MG PO TAB SR 24HR               | Niacin-Lovastatin Tab ER 24HR 1000-20 MG                    | 31                   |                            |
| 2170375  | ezetimibe-simvastatin tablet 10 mg-40 mg                     | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 31                   |                            |
| 2517039  | SIMCOR 1000-40 MG PO TAB SR 24HR                             | Niacin-Simvastatin Tab ER 24HR 1000-40 MG                   | 31                   |                            |
| 3685025  | lovastatin 40 mg tablet, extended release                    | lovastatin 40 mg tablet, extended release                   | 31                   |                            |
| 127867   | ALTOCOR 60 MG OR TB24                                        | Lovastatin Tab SR 24HR 60 MG                                | 30                   |                            |
| 137141   | AMLODIPINE-ATORVASTATIN 2.5-20 MG PO TABS                    | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-20 MG      | 30                   |                            |
| 162577   | MEVACOR OR                                                   | Lovastatin                                                  | 30                   |                            |
| 2181833  | lovastatin tablet, extended release 20 mg                    | lovastatin                                                  | 30                   |                            |
| 2183575  | Lescol XL tablet, extended release 80 mg                     | fluvastatin 80 mg tablet, extended release                  | 30                   |                            |
| 2184582  | Caduet 10 mg-10 mg oral tablet                               | amLODIPine-atorvastatin 10 mg-10 mg tablet                  | 30                   |                            |
| 2186664  | Altoprev 40 mg oral tablet, extended release                 | lovastatin 40 mg tablet, extended release                   | 30                   |                            |
| 2158165  | rosuvastatin 40 mg oral tablet                               |                                                             | 29                   |                            |
| 2166061  | rosuvastatin tablet 10 mg                                    | rosuvastatin                                                | 29                   |                            |
| 2185585  | Vytorin tablet 10 mg-10 mg                                   | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 29                   |                            |
| 2187661  | Altocor 40 mg oral tablet, extended release                  | lovastatin 40 mg tablet, extended release                   | 29                   |                            |
| 2198086  | Simcor 500 mg-20 mg oral tablet, extended release            | niacin-simvastatin 500 mg-20 mg tablet, extended release    | 29                   |                            |
| 24082031 | ROSUVASTATIN CALCIUM 20 MG PO CPSP                           | Rosuvastatin Calcium Sprinkle Cap 20 MG (Base Equivalent)   | 29                   |                            |
| 24086052 | ROSUVASTATIN CALCIUM 10 MG PO CPSP                           | Rosuvastatin Calcium Sprinkle Cap 10 MG (Base Equivalent)   | 29                   |                            |
| 125199   | BAYCOL TABS 0.8 MG OR                                        | Cerivastatin Sodium Tab 0.8 MG                              | 28                   |                            |
| 137139   | CADUET 2.5-20 MG PO TABS                                     | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-20 MG      | 28                   |                            |
| 2160261  | Zocor 20 mg tablet oral                                      | simvastatin                                                 | 28                   |                            |
| 2172544  | fluvastatin 20 mg oral capsule                               | fluvastatin 20 mg capsule                                   | 28                   |                            |
| 2186244  | atorvastatin 10 mg tablet oral                               | atorvastatin 10 mg tablet                                   | 28                   |                            |
| 2189076  | simvastatin tablet 5 mg                                      | simvastatin 5 mg tablet                                     | 28                   |                            |
| 3705011  | lovastatin 10 mg tablet                                      | lovastatin 10 mg tablet                                     | 28                   |                            |
| 2164875  | rosuvastatin tablet 40 mg                                    | rosuvastatin 40 mg tablet                                   | 27                   |                            |
| 2168514  | lovastatin 60 mg oral tablet, extended release               | lovastatin 60 mg tablet, extended release                   | 27                   |                            |
| 2179732  | Crestor tablet 20 mg                                         | rosuvastatin                                                | 27                   |                            |
| 4074103  | Livalo 1 mg oral tablet                                      | pitavastatin 1 mg tablet                                    | 27                   |                            |
| 5474049  | INVESTIGATIONAL ATORVASTATIN 10 MG TABS                      | Atorvastatin Calcium Tab 10 MG (Base Equivalent)            | 27                   |                            |
| 2144874  | Pravachol 80 mg oral tablet                                  |                                                             | 26                   |                            |
| 2160079  | rosuvastatin                                                 | rosuvastatin                                                | 26                   |                            |
| 2190282  | rosuvastatin tablet 5 mg                                     | rosuvastatin 5 mg tablet                                    | 26                   |                            |
| 2174378  | Caduet 5 mg-20 mg oral tablet                                | amLODIPine-atorvastatin 5 mg-20 mg tablet                   | 25                   |                            |
| 11333798 | atorvastatin 40 mg oral tablet                               | atorvastatin                                                | 25                   |                            |
| 59319    | BAYCOL TABS 0.2 MG OR                                        | Cerivastatin Sodium Tab 0.2 MG                              | 24                   |                            |
| 2184667  | lovastatin tablet, extended release 40 mg                    | lovastatin 40 mg tablet, extended release                   | 24                   |                            |
| 2189571  | Caduet 10 mg-20 mg oral tablet                               | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 24                   |                            |
| 7326019  | pitavastatin 4 mg oral tablet                                | pitavastatin 4 mg tablet                                    | 24                   |                            |
| 171945   | NIACIN-SIMVASTATIN ER 1000-20 MG PO TAB SR 24HR              | Niacin-Simvastatin Tab ER 24HR 1000-20 MG                   | 23                   |                            |
| 2156862  | Vytorin tablet 10 mg-10 mg                                   | ezetimibe-simvastatin                                       | 23                   |                            |
| 2161052  | lipitor 20mg daily                                           |                                                             | 23                   |                            |
| 2173382  | Vytorin 10 mg-40 mg tablet oral                              | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 23                   |                            |
| 2186578  | Caduet 10 mg-40 mg oral tablet                               | amLODIPine-atorvastatin 10 mg-40 mg tablet                  | 23                   |                            |
| 2188577  | Caduet 5 mg-10 mg oral tablet                                | amLODIPine-atorvastatin 5 mg-10 mg tablet                   | 23                   |                            |
| 6374037  | Simvastatin Tab 20 MG                                        |                                                             | 22                   |                            |
| 2176247  | simvastatin 5 mg oral tablet                                 |                                                             | 21                   |                            |
| 2186700  | Lescol 20 mg oral capsule                                    | fluvastatin 20 mg capsule                                   | 21                   |                            |
| 2190241  | atorvastatin 40 mg tablet oral                               | atorvastatin 40 mg tablet                                   | 21                   |                            |
| 6368029  | Simvastatin Tab 40 MG                                        |                                                             | 21                   |                            |
| 3799009  | lovastatin 20 mg tablet, extended release                    | lovastatin 20 mg tablet, extended release                   | 20                   |                            |
| 5357048  | ADVICOR PO                                                   |                                                             | 20                   |                            |
| 135928   | AMLODIPINE-ATORVASTATIN 2.5-40 MG PO TABS                    | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-40 MG      | 19                   |                            |
| 2171503  | Altocor 20 mg oral tablet, extended release                  | lovastatin 20 mg tablet, extended release                   | 19                   |                            |
| 2176554  | Vytorin 10 mg-80 mg oral tablet                              |                                                             | 19                   |                            |
| 2189569  | amLODIPine-atorvastatin 5 mg-40 mg oral tablet               | amLODIPine-atorvastatin 5 mg-40 mg tablet                   | 19                   |                            |
| 2516037  | SIMCOR 500-40 MG PO TAB SR 24HR                              | Niacin-Simvastatin Tab ER 24HR 500-40 MG                    | 19                   |                            |
| 2186582  | Vytorin 10 mg-20 mg tablet oral                              | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 18                   |                            |
| 2206003  | lovastatin 10 mg oral tablet                                 |                                                             | 18                   |                            |
| 5699026  | pitavastatin 1 mg oral tablet                                | pitavastatin 1 mg tablet                                    | 18                   |                            |
| 24083026 | ROSUVASTATIN CALCIUM 5 MG PO CPSP                            | Rosuvastatin Calcium Sprinkle Cap 5 MG (Base Equivalent)    | 18                   |                            |
| 2154944  | Lescol capsule 20 mg                                         | fluvastatin                                                 | 17                   |                            |
| 2181852  | pravastatin tablet 10 mg                                     | pravastatin                                                 | 17                   |                            |
| 5365511  | MEVACOR PO                                                   | Lovastatin                                                  | 17                   |                            |
| 140568   | NIACIN-LOVASTATIN ER 1000-40 MG PO TAB SR 24HR               | Niacin-Lovastatin Tab ER 24HR 1000-40 MG                    | 16                   |                            |
| 151425   | AMLODIPINE-ATORVASTATIN OR                                   | amLODIPine-Atorvastatin                                     | 16                   |                            |
| 2153301  | simvastatin 40mg daily                                       |                                                             | 16                   |                            |
| 2184702  | Lescol capsule 40 mg                                         | fluvastatin 40 mg capsule                                   | 16                   |                            |
| 2190434  | Lovastatin 40 mg tablet oral                                 | lovastatin 40 mg tablet                                     | 16                   |                            |
| 3640013  | Zocor 80 mg tablet                                           | simvastatin 80 mg tablet                                    | 16                   |                            |
| 135432   | ALTOPREV 20 MG PO TAB SR 24HR                                | Lovastatin Tab ER 24HR 20 MG                                | 15                   |                            |
| 2150108  | Lipitor 40mg daily                                           |                                                             | 15                   |                            |
| 2162183  | Mevacor tablet 40 mg                                         | lovastatin                                                  | 15                   |                            |
| 2171384  | ezetimibe-simvastatin tablet 10 mg-80 mg                     | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 15                   |                            |
| 2178717  | Lipitor 40 mg tablet oral                                    | atorvastatin                                                | 15                   |                            |
| 2181738  | Crestor tablet 40 mg                                         | rosuvastatin                                                | 15                   |                            |
| 2183293  | Crestor 10 mg tablet oral                                    | rosuvastatin 10 mg tablet                                   | 15                   |                            |
| 2187241  | atorvastatin 80 mg tablet oral                               | atorvastatin 80 mg tablet                                   | 15                   |                            |
| 2188662  | lovastatin tablet, extended release 20 mg                    | lovastatin 20 mg tablet, extended release                   | 15                   |                            |
| 134087   | ALGICELL CALCIUM DRESSING 4"X4 EX MISC                       | Calcium Alginate Wound Dressing                             | 14                   | TRUE                       |
| 173159   | SIMCOR 750-20 MG PO TAB SR 24HR                              | Niacin-Simvastatin Tab ER 24HR 750-20 MG                    | 14                   |                            |
| 2165250  | Zocor tablet 5 mg                                            | simvastatin                                                 | 14                   |                            |
| 2170371  | Caduet 5 mg-40 mg oral tablet                                | amLODIPine-atorvastatin 5 mg-40 mg tablet                   | 14                   |                            |
| 2184385  | pravastatin 10 mg tablet oral                                | pravastatin 10 mg tablet                                    | 14                   |                            |
| 2197087  | Simcor 1000 mg-20 mg oral tablet, extended release           | niacin-simvastatin 1000 mg-20 mg tablet, extended release   | 14                   |                            |
| 5188022  | ezetimibe-simvastatin 10 mg-20 mg tablet                     | ezetimibe-simvastatin 10 mg-20 mg tablet                    | 14                   |                            |
| 5854047  | SIMVASTATIN 20 MG OR TABS                                    |                                                             | 14                   |                            |
| 161414   | LESCOL XL OR                                                 | Fluvastatin Sodium                                          | 13                   |                            |
| 1632006  | LIVALO OR                                                    | Pitavastatin Calcium                                        | 13                   |                            |
| 2166215  | pravastatin tablet 80 mg                                     | pravastatin                                                 | 13                   |                            |
| 2173018  | pravastatin 40 mg tablet oral                                | pravastatin 40 mg tablet                                    | 13                   |                            |
| 2177838  | lovastatin tablet 10 mg                                      | lovastatin                                                  | 13                   |                            |
| 2188083  | Zocor tablet 5 mg                                            | simvastatin 5 mg tablet                                     | 13                   |                            |
| 2229018  | Vytorin 10 mg-10 mg oral tablet                              |                                                             | 13                   |                            |
| 6368015  | Rosuvastatin Calcium Tab 10 MG (CRESTOR)                     |                                                             | 13                   |                            |
| 6382031  | Atorvastatin Calcium Tab 20 MG (Base Equivalent) (LIPITOR)   |                                                             | 13                   |                            |
| 8772046  | INVESTIGATIONAL ATORVASTATIN 20 MG CAPS OR PLACEBO           | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 13                   |                            |
| 135926   | CADUET 2.5-40 MG PO TABS                                     | Amlodipine Besylate-Atorvastatin Calcium Tab 2.5-40 MG      | 12                   |                            |
| 166404   | ROSUVASTATIN CALCIUM OR                                      | Rosuvastatin Calcium                                        | 12                   |                            |
| 2151176  | rosuvastatin                                                 |                                                             | 12                   |                            |
| 2157292  | simva                                                        |                                                             | 12                   |                            |
| 2167383  | Caduet tablet 5 mg-10 mg                                     | amLODIPine-atorvastatin 5 mg-10 mg tablet                   | 12                   |                            |
| 2175163  | niacin-simvastatin 1000 mg-20 mg oral tablet, extended release | niacin-simvastatin 1000 mg-20 mg tablet, extended release   | 12                   |                            |
| 2186668  | lovastatin-niacin 20 mg-500 mg oral tablet, extended release | lovastatin-niacin 20 mg-500 mg tablet, extended release     | 12                   |                            |
| 2187434  | Mevacor tablet 40 mg                                         | lovastatin 40 mg tablet                                     | 12                   |                            |
| 2514035  | NIACIN-SIMVASTATIN ER 1000-40 MG PO TAB SR 24HR              | Niacin-Simvastatin Tab ER 24HR 1000-40 MG                   | 12                   |                            |
| 7298024  | SIMVASTATIN 40 MG OR TABS                                    |                                                             | 12                   |                            |
| 20527152 | SIMVASTATIN 20 MG/5ML PO SUSP                                | Simvastatin Susp 20 MG/5ML (4 MG/ML)                        | 12                   |                            |
| 24082030 | ROSUVASTATIN CALCIUM 40 MG PO CPSP                           | Rosuvastatin Calcium Sprinkle Cap 40 MG (Base Equivalent)   | 12                   |                            |
| 2162879  | Crestor 5 mg tablet oral                                     | rosuvastatin 5 mg tablet                                    | 11                   |                            |
| 2163067  | rosuvastatin tablet 20 mg                                    | rosuvastatin                                                | 11                   |                            |
| 2175924  | Caduet tablet 5 mg-10 mg                                     | amLODIPine-atorvastatin                                     | 11                   |                            |
| 2183588  | amlodipine-atorvastatin 10 mg-80 mg oral tablet              | amLODIPine-atorvastatin 10 mg-80 mg tablet                  | 11                   |                            |
| 3915004  | simvastatin 40 mg tablet                                     |                                                             | 11                   |                            |
| 4487068  | ezetimibe-simvastatin 10 mg-40 mg tablet                     | ezetimibe-simvastatin 10 mg-40 mg tablet                    | 11                   |                            |
| 4752014  | Simvastatin 40 mg or tabs, 1 tablet at bedtime               |                                                             | 11                   |                            |
| 5403027  | Simvastatin 40 mg or tabs, 1 tablet at bedtime (home med)    |                                                             | 11                   |                            |
| 1628020  | L-METHYLFOLATE CALCIUM 7.5 MG PO TABS                        | L-Methylfolate Tab 7.5 MG                                   | 10                   | TRUE                       |
| 2129714  | caduet                                                       |                                                             | 10                   |                            |
| 2143047  | Lescol                                                       |                                                             | 10                   |                            |
| 2164180  | Mevacor tablet 20 mg                                         | lovastatin                                                  | 10                   |                            |
| 2172378  | Caduet tablet 10 mg-10 mg                                    | amLODIPine-atorvastatin 10 mg-10 mg tablet                  | 10                   |                            |
| 2175255  | simvastatin tablet 20 mg                                     |                                                             | 10                   |                            |
| 2176913  | Advicor tablet 20 mg-500 mg                                  | lovastatin-niacin                                           | 10                   |                            |
| 2188080  | simvastatin 80 mg tablet oral                                | simvastatin 80 mg tablet                                    | 10                   |                            |
| 3641011  | lovastatin 60 mg tablet, extended release                    | lovastatin 60 mg tablet, extended release                   | 10                   |                            |
| 3920009  | simvastatin 20 mg tablet                                     |                                                             | 10                   |                            |
| 5373092  | PITAVASTATIN CALCIUM PO                                      | Pitavastatin Calcium                                        | 10                   |                            |
| 5471043  | INVESTIGATIONAL ATORVASTATIN 20 MG TABS OR PLACEBO           | Atorvastatin Calcium Tab 20 MG (Base Equivalent)            | 10                   |                            |
| 7388020  | simvastatin 20mg tab                                         |                                                             | 10                   |                            |
| 8985065  | LIPTRUZET 10-20 MG PO TABS                                   | Ezetimibe-Atorvastatin Tab 10-20 MG                         | 10                   |                            |
| 132992   | ALGICELL CALCIUM DRESSING 4"X8 EX MISC                       | Calcium Alginate Wound Dressing                             | 9                    | TRUE                       |
| 2153851  | zocor-home medication                                        |                                                             | 9                    |                            |
| 2158295  | simvastatin 40 mg                                            |                                                             | 9                    |                            |
| 2161287  | Caduet tablet 5 mg-20 mg                                     | amLODIPine-atorvastatin                                     | 9                    |                            |
| 2163876  | Crestor 20 mg tablet oral                                    | rosuvastatin 20 mg tablet                                   | 9                    |                            |
| 2165068  | rosuvastatin tablet 5 mg                                     | rosuvastatin                                                | 9                    |                            |
| 2165249  | simvastatin tablet 5 mg                                      | simvastatin                                                 | 9                    |                            |
| 2171547  | Lescol capsule 20 mg                                         | fluvastatin 20 mg capsule                                   | 9                    |                            |
| 2172501  | Altoprev 60 mg oral tablet, extended release                 | lovastatin 60 mg tablet, extended release                   | 9                    |                            |
| 2175254  | simvastatin 80mg daily                                       |                                                             | 9                    |                            |
| 2180240  | Simvastatin 40mg PO qhs                                      |                                                             | 9                    |                            |
| 2186436  | lovastatin 20 mg tablet oral                                 | lovastatin 20 mg tablet                                     | 9                    |                            |
| 2186579  | Caduet tablet 5 mg-20 mg                                     | amLODIPine-atorvastatin 5 mg-20 mg tablet                   | 9                    |                            |
| 2190580  | Vytorin 10 mg-80 mg tablet oral                              | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 9                    |                            |
| 2550006  | Simcor 500 mg-20 mg oral tablet, extended release            |                                                             | 9                    |                            |
| 3654022  | Lescol XL 80 mg tablet, extended release                     | fluvastatin 80 mg tablet, extended release                  | 9                    |                            |
| 4494086  | Simvastatin 20 mg or tabs, 1 tablet at bedtime (home med)    |                                                             | 9                    |                            |
| 5476048  | INVESTIGATIONAL ATORVASTATIN 10 MG TABS OR PLACEBO           | Atorvastatin Calcium Tab 10 MG (Base Equivalent)            | 9                    |                            |
| 6165157  | Atorvastatin calcium (lipitor) 20 mg or tabs, 1 tablet daily |                                                             | 9                    |                            |
| 8174065  | LOVASTATIN ER PO                                             | Lovastatin                                                  | 9                    |                            |
| 10690058 | Please check INR every 2-3 days or as needed                 |                                                             | 9                    | TRUE                       |
| 11051593 | lovastatin extended release 20 mg oral tablet, extended release | lovastatin 20 mg tablet, extended release                   | 9                    |                            |
| 11592185 | atorvastatin 20 mg oral tablet                               | atorvastatin                                                | 9                    |                            |
| 13018500 | ATORVASTATIN CALCIUM POWD                                    | Atorvastatin Calcium (Bulk) Powder                          | 9                    |                            |
| 14005070 | EZETIMIBE-SIMVASTATIN (VYTORIN 10/20) COMBINATION TABLET     |                                                             | 9                    |                            |
| 2152847  | zocor 20mg daily                                             |                                                             | 8                    |                            |
| 2155298  | simvastatin tablet 40 mg                                     |                                                             | 8                    |                            |
| 2158969  | Lescol XL 80 mg oral tablet, extended release                |                                                             | 8                    |                            |
| 2160060  | lipitor 40 mg                                                |                                                             | 8                    |                            |
| 2168513  | Altocor tablet, extended release 40 mg                       | lovastatin 40 mg tablet, extended release                   | 8                    |                            |
| 2172380  | ezetimibe-simvastatin tablet 10 mg-10 mg                     | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 8                    |                            |
| 2177244  | simvastatin 20mg qhs                                         |                                                             | 8                    |                            |
| 2179232  | simvastatin 20mg daily                                       |                                                             | 8                    |                            |
| 2805019  | Advicor 1000 mg-20 mg oral tablet, extended release          | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 8                    |                            |
| 4522006  | Altoprev 40 mg tablet, extended release                      | lovastatin 40 mg tablet, extended release                   | 8                    |                            |
| 5359832  | LESCOL XL PO                                                 | Fluvastatin Sodium                                          | 8                    |                            |
| 6161096  | Simvastatin 20 mg or tabs, 1 tablet at bedtime               |                                                             | 8                    |                            |
| 6481029  | Simvastatin Tab 20 MG (ZOCOR)                                |                                                             | 8                    |                            |
| 74123    | VITORMAINS TABS  OR                                          | Multiple Vitamin Tab                                        | 7                    |                            |
| 2162284  | Caduet tablet 10 mg-20 mg                                    | amLODIPine-atorvastatin                                     | 7                    |                            |
| 2165181  | lovastatin tablet, extended release 60 mg                    | lovastatin                                                  | 7                    |                            |
| 2167384  | Caduet tablet 10 mg-20 mg                                    | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 7                    |                            |
| 2169371  | fluvastatin tablet, extended release 80 mg                   | fluvastatin 80 mg tablet, extended release                  | 7                    |                            |
| 2176241  | simvas                                                       |                                                             | 7                    |                            |
| 2182238  | simvastatin 20 mg                                            |                                                             | 7                    |                            |
| 2184085  | simvastatin 10 mg tablet oral                                | simvastatin 10 mg tablet                                    | 7                    |                            |
| 2184666  | lovastatin 10 mg oral tablet, extended release               | lovastatin 10 mg tablet, extended release                   | 7                    |                            |
| 2189660  | Advicor 20 mg-1000 mg oral tablet, extended release          | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 7                    |                            |
| 2232011  | Advicor 1000 mg-40 mg oral tablet, extended release          | lovastatin-niacin 40 mg-1000 mg tablet, extended release    | 7                    |                            |
| 2515042  | NIACIN-SIMVASTATIN ER 500-40 MG PO TAB SR 24HR               | Niacin-Simvastatin Tab ER 24HR 500-40 MG                    | 7                    |                            |
| 3075001  | atorvastatin calcium                                         |                                                             | 7                    |                            |
| 3603057  | Zocor 5 mg tablet                                            | simvastatin 5 mg tablet                                     | 7                    |                            |
| 3996019  | Vytorin 10 mg-10 mg tablet                                   | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 7                    |                            |
| 6055019  | Atorvastatin calcium (lipitor) 10 mg or tabs, 1 tablet daily |                                                             | 7                    |                            |
| 6437016  | Simvastatin Tab 10 MG                                        |                                                             | 7                    |                            |
| 6498128  | Lovastatin Tab 20 MG                                         |                                                             | 7                    |                            |
| 7551017  | Tylenol 650 mg oral every 4 hours as needed for pain         |                                                             | 7                    | TRUE                       |
| 8923038  | atorvastatin 10 mg oral tablet                               | atorvastatin                                                | 7                    |                            |
| 10612972 | Lescol 80 mg oral tablet, extended release                   | fluvastatin 80 mg tablet, extended release                  | 7                    |                            |
| 10704580 | lovastatin extended release 40 mg oral tablet, extended release | lovastatin 40 mg tablet, extended release                   | 7                    |                            |
| 14296028 | EZETIMIBE-SIMVASTATIN (VYTORIN 10/40) COMBINATION TABLET     |                                                             | 7                    |                            |
| 2139851  | crestor 20mg                                                 |                                                             | 6                    |                            |
| 2145054  | Lescol 20 mg oral capsule                                    |                                                             | 6                    |                            |
| 2157941  | Lescol                                                       | fluvastatin                                                 | 6                    |                            |
| 2158942  | fluvastatin capsule 40 mg                                    | fluvastatin                                                 | 6                    |                            |
| 2162046  | lipi                                                         |                                                             | 6                    |                            |
| 2170496  | lovastatin tablet, extended release 60 mg                    | lovastatin 60 mg tablet, extended release                   | 6                    |                            |
| 2171380  | Caduet tablet 10 mg-80 mg                                    | amLODIPine-atorvastatin 10 mg-80 mg tablet                  | 6                    |                            |
| 2172377  | Caduet 10 mg-80 mg oral tablet                               | amLODIPine-atorvastatin 10 mg-80 mg tablet                  | 6                    |                            |
| 2174377  | Caduet tablet 5 mg-40 mg                                     | amLODIPine-atorvastatin 5 mg-40 mg tablet                   | 6                    |                            |
| 2175625  | zocor 20 daily                                               |                                                             | 6                    |                            |
| 2180150  | niacin-simvastatin 500 mg-20 mg oral tablet, extended release | niacin-simvastatin 500 mg-20 mg tablet, extended release    | 6                    |                            |
| 2180714  | Lipitor 20 mg tablet oral                                    | atorvastatin                                                | 6                    |                            |
| 2186377  | Lovastatin 10 mg tablet oral                                 | lovastatin 10 mg tablet                                     | 6                    |                            |
| 2187696  | Lescol 40 mg capsule oral                                    | fluvastatin 40 mg capsule                                   | 6                    |                            |
| 2611012  | lovastatin 60 mg oral tablet, extended release               |                                                             | 6                    |                            |
| 2710003  | ezetimibe-simvastatin 10 mg-20 mg oral tablet                |                                                             | 6                    |                            |
| 3753001  | atorva                                                       |                                                             | 6                    |                            |
| 3978010  | Vytorin 10 mg-80 mg tablet                                   | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 6                    |                            |
| 4915030  | Simvastatin 10 mg or tabs, 1 tablet at bedtime               |                                                             | 6                    |                            |
| 5356503  | FLUVASTATIN SODIUM PO                                        | Fluvastatin Sodium                                          | 6                    |                            |
| 5591022  | Simvastatin 10 mg or tabs, 1 tablet at bedtime (home med)    |                                                             | 6                    |                            |
| 6027020  | Atorvastatin calcium (lipitor) 20 mg or tabs                 |                                                             | 6                    |                            |
| 6372037  | Atorvastatin Calcium Tab 40 MG (Base Equivalent) (LIPITOR)   |                                                             | 6                    |                            |
| 6627022  | Simvastatin Tab 40 MG (ZOCOR)                                |                                                             | 6                    |                            |
| 7464021  | LIPITOR 20 MG OR TABS                                        |                                                             | 6                    |                            |
| 8076017  | Rosuvastatin 10mg tab                                        |                                                             | 6                    |                            |
| 8983065  | LIPTRUZET 10-40 MG PO TABS                                   | Ezetimibe-Atorvastatin Tab 10-40 MG                         | 6                    |                            |
| 8984065  | LIPTRUZET 10-10 MG PO TABS                                   | Ezetimibe-Atorvastatin Tab 10-10 MG                         | 6                    |                            |
| 11345341 | simvastatin 20 mg oral tablet                                | simvastatin                                                 | 6                    |                            |
| 11374154 | MAGNESIUM-POTASSIUM 300-500 MG/6.1GM PO PDEF                 | Magnesium w/ Potassium Effervescent Powder 300-500 MG/6.1GM | 6                    | TRUE                       |
| 129185   | NIACIN-LOVASTATIN ER 750-20 MG PO TAB SR 24HR                | Niacin-Lovastatin Tab ER 24HR 750-20 MG                     | 5                    |                            |
| 148520   | SIMVASTATIN POWD                                             | Simvastatin (Bulk) Powder                                   | 5                    |                            |
| 152328   | ALTOPREV OR                                                  | Lovastatin                                                  | 5                    |                            |
| 158357   | EZETIMIBE-SIMVASTATIN OR                                     | Ezetimibe-Simvastatin                                       | 5                    |                            |
| 173158   | NIACIN-SIMVASTATIN ER 750-20 MG PO TAB SR 24HR               | Niacin-Simvastatin Tab ER 24HR 750-20 MG                    | 5                    |                            |
| 2127595  | Ator                                                         |                                                             | 5                    |                            |
| 2133758  | atorvastatin 10mg every evening at bedtime                   |                                                             | 5                    |                            |
| 2138083  | crestor 20 mg daily                                          |                                                             | 5                    |                            |
| 2141863  | Crestor 20mg daily                                           |                                                             | 5                    |                            |
| 2146105  | lipitor 10mg                                                 |                                                             | 5                    |                            |
| 2147100  | lipitor 10mg PO daily                                        |                                                             | 5                    |                            |
| 2152873  | ezetimibe-simvastatin tablet 10 mg-20 mg                     | ezetimibe-simvastatin                                       | 5                    |                            |
| 2158293  | simv                                                         |                                                             | 5                    |                            |
| 2166243  | Zocor 40 mg tablet oral                                      | simvastatin                                                 | 5                    |                            |
| 2170372  | amlodipine-atorvastatin tablet 5 mg-20 mg                    | amLODIPine-atorvastatin 5 mg-20 mg tablet                   | 5                    |                            |
| 2170501  | lovastatin-niacin 20 mg-1000 mg oral tablet, extended release | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 5                    |                            |
| 2172365  | Lescol XL 80 mg tablet, extended release oral                | fluvastatin 80 mg tablet, extended release                  | 5                    |                            |
| 2173541  | pravachol 40mg daily                                         |                                                             | 5                    |                            |
| 2175248  | simvastatin (home med)                                       |                                                             | 5                    |                            |
| 2175252  | simvastatin 40mg                                             |                                                             | 5                    |                            |
| 2178246  | simvistatin                                                  |                                                             | 5                    |                            |
| 2179234  | simvastatin 40mg daily at bedtime                            |                                                             | 5                    |                            |
| 2179827  | lovastatin tablet, extended release 10 mg                    | lovastatin                                                  | 5                    |                            |
| 2183589  | amlodipine-atorvastatin tablet 10 mg-20 mg                   | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 5                    |                            |
| 2184581  | Caduet tablet 10 mg-40 mg                                    | amLODIPine-atorvastatin 10 mg-40 mg tablet                  | 5                    |                            |
| 2187575  | amlodipine-atorvastatin tablet 10 mg-40 mg                   | amLODIPine-atorvastatin 10 mg-40 mg tablet                  | 5                    |                            |
| 2188576  | Caduet 5 mg-80 mg oral tablet                                | amLODIPine-atorvastatin 5 mg-80 mg tablet                   | 5                    |                            |
| 2188985  | Advicor 40 mg-1000 mg oral tablet, extended release          | lovastatin-niacin 40 mg-1000 mg tablet, extended release    | 5                    |                            |
| 2189428  | Mevacor tablet 20 mg                                         | lovastatin 20 mg tablet                                     | 5                    |                            |
| 2189661  | Pravachol 80 mg tablet oral                                  | pravastatin 80 mg tablet                                    | 5                    |                            |
| 2221020  | Altoprev tablet, extended release 20 mg                      | lovastatin 20 mg tablet, extended release                   | 5                    |                            |
| 2237009  | simvastatin 20 mg oral tablet daily                          |                                                             | 5                    |                            |
| 2291051  | simvastatin 40 mg oral tablet daily                          |                                                             | 5                    |                            |
| 3121007  | simvastatin 10mg daily                                       |                                                             | 5                    |                            |
| 4166022  | Lipitor 10 mg tablet                                         |                                                             | 5                    |                            |
| 4508117  | simvastatin 10 mg tablet                                     |                                                             | 5                    |                            |
| 5167019  | lovastatin 40 mg oral tablet, extended release               |                                                             | 5                    |                            |
| 5403026  | Pravastatin sodium 40 mg or tabs, 1 tablet at bedtime (home med) |                                                             | 5                    |                            |
| 6086062  | Rosuvastatin calcium (crestor) 10 mg or tabs, 1 tablet daily |                                                             | 5                    |                            |
| 6087072  | Simvastatin 40 mg qhs                                        |                                                             | 5                    |                            |
| 6442029  | Rosuvastatin Calcium Tab 5 MG (CRESTOR)                      |                                                             | 5                    |                            |
| 8043021  | Simcor 1000 mg-40 mg oral tablet, extended release           | niacin-simvastatin 1000 mg-40 mg tablet, extended release   | 5                    |                            |
| 8128028  | Simvastatin 40mg tab                                         |                                                             | 5                    |                            |
| 8420037  | pitavastatin                                                 | pitavastatin                                                | 5                    |                            |
| 8770093  | INVESTIGATIONAL ATORVASTATIN 10 MG CAPS OR PLACEBO           | Atorvastatin Calcium Tab 10 MG (Base Equivalent)            | 5                    |                            |
| 8947051  | amLODIPine-atorvastatin 2.5 mg-10 mg oral tablet             | amLODIPine-atorvastatin 2.5 mg-10 mg tablet                 | 5                    |                            |
| 11296754 | simvastatin 10 mg oral tablet                                | simvastatin                                                 | 5                    |                            |
| 14717016 | EZETIMIBE-SIMVASTATIN (VYTORIN 10/10) COMBINATION TABLET     |                                                             | 5                    |                            |
| 20523091 | SIMVASTATIN 40 MG/5ML PO SUSP                                | Simvastatin Susp 40 MG/5ML (8 MG/ML)                        | 5                    |                            |
| 23153020 | INVESTIGATIONAL ATORVASTATIN (STOP-CA) 40 MG CAPS OR PLACEBO | Inv Atorvastatin Calcium 40MG (Base Equivalent)             | 5                    |                            |
| 2129588  | atorvastatin 20 mg                                           |                                                             | 4                    |                            |
| 2134305  | Advicor                                                      |                                                             | 4                    |                            |
| 2143875  | pravastatin 40mg daily                                       |                                                             | 4                    |                            |
| 2144112  | lipitor 20 mg                                                |                                                             | 4                    |                            |
| 2146333  | Mevacor 40 mg oral tablet                                    |                                                             | 4                    |                            |
| 2146971  | provastatin                                                  |                                                             | 4                    |                            |
| 2148104  | Lipit                                                        |                                                             | 4                    |                            |
| 2149106  | lipito                                                       |                                                             | 4                    |                            |
| 2149873  | pravastatin tablet 40 mg                                     |                                                             | 4                    |                            |
| 2151880  | ezetimibe-simvastatin tablet 10 mg-40 mg                     | ezetimibe-simvastatin                                       | 4                    |                            |
| 2153303  | simvastatin 80mg po daily                                    |                                                             | 4                    |                            |
| 2154297  | Simvastatin 40 mg daily at bedtime                           |                                                             | 4                    |                            |
| 2159073  | rosuvastatin tablet 40 mg                                    | rosuvastatin                                                | 4                    |                            |
| 2160888  | rosuvastatin 10 mg tablet oral                               | rosuvastatin 10 mg tablet                                   | 4                    |                            |
| 2162052  | lipitor 80mg daily                                           |                                                             | 4                    |                            |
| 2163249  | Zocor 80 mg tablet oral                                      | simvastatin                                                 | 4                    |                            |
| 2164798  | atorvastatin 10 mg oral tablet                               | atorvastatin 20 mg tablet                                   | 4                    |                            |
| 2167547  | pravastatin 40 mg                                            |                                                             | 4                    |                            |
| 2169023  | pravastatin                                                  | pravastatin 40 mg tablet                                    | 4                    |                            |
| 2171383  | Vytorin 10 mg-10 mg tablet oral                              | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 4                    |                            |
| 2180664  | fluvastatin tablet, extended release 80 mg                   | fluvastatin                                                 | 4                    |                            |
| 2181238  | simvastatin 20mg daily at bedtime                            |                                                             | 4                    |                            |
| 2183673  | lovastatin tablet, extended release 10 mg                    | lovastatin 10 mg tablet, extended release                   | 4                    |                            |
| 2185582  | amlodipine-atorvastatin tablet 5 mg-10 mg                    | amLODIPine-atorvastatin 5 mg-10 mg tablet                   | 4                    |                            |
| 2188435  | Mevacor 40 mg tablet oral                                    | lovastatin 40 mg tablet                                     | 4                    |                            |
| 2189655  | Altocor tablet, extended release 20 mg                       | lovastatin 20 mg tablet, extended release                   | 4                    |                            |
| 2193092  | Simcor tablet, extended release 500 mg-20 mg                 | niacin-simvastatin 500 mg-20 mg tablet, extended release    | 4                    |                            |
| 2203008  | Zocor 5 mg oral tablet                                       |                                                             | 4                    |                            |
| 2227001  | Advicor 500 mg-20 mg oral tablet, extended release           |                                                             | 4                    |                            |
| 2244006  | simvastatin 40mg each night                                  |                                                             | 4                    |                            |
| 2350006  | Caduet 5 mg-10 mg oral tablet                                |                                                             | 4                    |                            |
| 2399008  | ezetimibe-simvastatin 10 mg-40 mg oral tablet                |                                                             | 4                    |                            |
| 2719063  | lovastatin 20 mg oral tablet, extended release               |                                                             | 4                    |                            |
| 2885002  | fluvastatin 80 mg oral tablet, extended release              |                                                             | 4                    |                            |
| 2934045  | Dilaudid 4 mg oral one tablet every 3 hours as needed for pain |                                                             | 4                    | TRUE                       |
| 3613018  | Mevacor 40 mg tablet                                         | lovastatin 40 mg tablet                                     | 4                    |                            |
| 3908002  | amlodipine-atorvastatin 5 mg-10 mg oral tablet               |                                                             | 4                    |                            |
| 3910022  | Altoprev 20 mg tablet, extended release                      | lovastatin 20 mg tablet, extended release                   | 4                    |                            |
| 4274020  | Simvastatin 20 mg oral every night at bedtime                |                                                             | 4                    |                            |
| 4335015  | Zocor 20 mg oral tablet po QD                                |                                                             | 4                    |                            |
| 4443034  | amLODIPine-atorvastatin 5 mg-10 mg tablet                    | amLODIPine-atorvastatin 5 mg-10 mg tablet                   | 4                    |                            |
| 4503097  | simvastatin 80 mg tablet                                     |                                                             | 4                    |                            |
| 5021058  | Pravastatin sodium 20 mg or tabs, 1 tablet at bedtime (home med) |                                                             | 4                    |                            |
| 6014048  | Pravastatin sodium 20 mg or tabs, 1 tablet at bedtime        |                                                             | 4                    |                            |
| 6165085  | Simvastatin 40 MG OR TABS 1 TABLET  AT BEDTIME               |                                                             | 4                    |                            |
| 6267016  | Atorvastatin Calcium Tab 80 MG (Base Equivalent) (LIPITOR)   |                                                             | 4                    |                            |
| 6448057  | Atorvastatin Calcium Tab 10 MG (Base Equivalent) (LIPITOR)   |                                                             | 4                    |                            |
| 6564027  | crestor 10 mg                                                |                                                             | 4                    |                            |
| 6890011  | Pravastatin Sodium Tab 40 MG (PRAVACHOL)                     |                                                             | 4                    |                            |
| 7066039  | Pravastatin Sodium Tab 20 MG                                 |                                                             | 4                    |                            |
| 7431020  | Atorvastatin 40mg tab                                        |                                                             | 4                    |                            |
| 8055012  | ezetimibe-simvastatin                                        | ezetimibe-simvastatin                                       | 4                    |                            |
| 8177083  | Simvastatin 20 MG PO TABS                                    |                                                             | 4                    |                            |
| 9690108  | LIPICHOL 540 PO                                              | Dietary Management Product                                  | 4                    |                            |
| 2128759  | atorvast                                                     |                                                             | 3                    |                            |
| 2129590  | atorvastatin 80mg                                            |                                                             | 3                    |                            |
| 2130578  | atorvastatin 20 mg oral tablet (home med)                    |                                                             | 3                    |                            |
| 2131586  | atorvastatin 80 mg                                           |                                                             | 3                    |                            |
| 2133583  | atorv                                                        |                                                             | 3                    |                            |
| 2134592  | Atorvastatin Tablet 20 mg                                    |                                                             | 3                    |                            |
| 2136080  | crestor 20 daily                                             |                                                             | 3                    |                            |
| 2138120  | calcium as previously directed                               |                                                             | 3                    | TRUE                       |
| 2141892  | Crestor tablet 20 mg                                         |                                                             | 3                    |                            |
| 2146110  | lipitor 80mg                                                 |                                                             | 3                    |                            |
| 2147103  | lipitor 80 mg                                                |                                                             | 3                    |                            |
| 2147863  | pravastatin 20mg daily at bedtime                            |                                                             | 3                    |                            |
| 2147908  | prevachol                                                    |                                                             | 3                    |                            |
| 2148107  | Lipitor 20 mg once a day                                     |                                                             | 3                    |                            |
| 2148108  | lipitor 20mg                                                 |                                                             | 3                    |                            |
| 2149110  | lipitor 40 daily                                             |                                                             | 3                    |                            |
| 2149924  | prevastatin                                                  |                                                             | 3                    |                            |
| 2150148  | lovastatin 80 mg oral tablet                                 |                                                             | 3                    |                            |
| 2152302  | simvastatin 80 mg PO daily                                   |                                                             | 3                    |                            |
| 2153300  | Simvastatin 20mg PO qhs                                      |                                                             | 3                    |                            |
| 2153947  | fluvastatin capsule 20 mg                                    | fluvastatin                                                 | 3                    |                            |
| 2154295  | simvastat                                                    |                                                             | 3                    |                            |
| 2161225  | lovastatin 40 mg                                             |                                                             | 3                    |                            |
| 2161802  | Lipitor                                                      | atorvastatin 40 mg tablet                                   | 3                    |                            |
| 2163047  | Lipitor 20mg oral tabs, take one tablet daily                |                                                             | 3                    |                            |
| 2164033  | Lipitor 10 mg tablet oral                                    | atorvastatin                                                | 3                    |                            |
| 2164050  | Lipitor oral tablet                                          |                                                             | 3                    |                            |
| 2165046  | lipitor 20 daily                                             |                                                             | 3                    |                            |
| 2166041  | lipitor 20mg once a day                                      |                                                             | 3                    |                            |
| 2167507  | Altoprev tablet, extended release 60 mg                      | lovastatin 60 mg tablet, extended release                   | 3                    |                            |
| 2167664  | provachol                                                    |                                                             | 3                    |                            |
| 2168519  | Advicor tablet, extended release 20 mg-1000 mg               | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 3                    |                            |
| 2168520  | pravastatin 80 mg tablet oral                                | pravastatin 80 mg tablet                                    | 3                    |                            |
| 2169507  | Altocor 60 mg oral tablet, extended release                  | lovastatin 60 mg tablet, extended release                   | 3                    |                            |
| 2170495  | Altoprev tablet, extended release 40 mg                      | lovastatin 40 mg tablet, extended release                   | 3                    |                            |
| 2173379  | amlodipine-atorvastatin tablet 10 mg-10 mg                   | amLODIPine-atorvastatin 10 mg-10 mg tablet                  | 3                    |                            |
| 2173501  | Altocor 10 mg oral tablet, extended release                  | lovastatin 10 mg tablet, extended release                   | 3                    |                            |
| 2176244  | simvastatin 20mg every evening at bedtime                    |                                                             | 3                    |                            |
| 2176245  | simvastatin 40 mg oral tablet daily at bedtime               |                                                             | 3                    |                            |
| 2177243  | Simvastatin 20 mg QHS                                        |                                                             | 3                    |                            |
| 2177248  | simvastatin tablet                                           |                                                             | 3                    |                            |
| 2177645  | ezetimibe-simvastatin tablet 10 mg-80 mg                     | ezetimibe-simvastatin                                       | 3                    |                            |
| 2177720  | Lipitor 80 mg tablet oral                                    | atorvastatin                                                | 3                    |                            |
| 2178009  | Advicor tablet, extended release 40 mg-1000 mg               | lovastatin-niacin 40 mg-1000 mg tablet, extended release    | 3                    |                            |
| 2179145  | niacin-simvastatin tablet, extended release 1000 mg-20 mg    | niacin-simvastatin 1000 mg-20 mg tablet, extended release   | 3                    |                            |
| 2179607  | zocor 20 mg                                                  |                                                             | 3                    |                            |
| 2181151  | Simcor 750 mg-20 mg oral tablet, extended release            | niacin-simvastatin 750 mg-20 mg tablet, extended release    | 3                    |                            |
| 2181907  | Advicor tablet 20 mg-1000 mg                                 | lovastatin-niacin                                           | 3                    |                            |
| 2183387  | Mevacor 10 mg oral tablet                                    | lovastatin 10 mg tablet                                     | 3                    |                            |
| 2184247  | Lipitor                                                      | atorvastatin 10 mg tablet                                   | 3                    |                            |
| 2185581  | amLODIPine-atorvastatin 5 mg-80 mg oral tablet               | amLODIPine-atorvastatin 5 mg-80 mg tablet                   | 3                    |                            |
| 2185990  | Advicor 1000 mg-40 mg oral tablet                            | lovastatin-niacin 40 mg-1000 mg tablet, extended release    | 3                    |                            |
| 2188697  | fluvastatin capsule 40 mg                                    | fluvastatin 40 mg capsule                                   | 3                    |                            |
| 2190080  | simvastatin                                                  | simvastatin 20 mg tablet                                    | 3                    |                            |
| 2195080  | niacin-simvastatin tablet, extended release 500 mg-20 mg     | niacin-simvastatin 500 mg-20 mg tablet, extended release    | 3                    |                            |
| 2333012  | rosuva                                                       |                                                             | 3                    |                            |
| 2658002  | ezetimibe-simvastatin 10 mg-80 mg oral tablet                |                                                             | 3                    |                            |
| 2720066  | simvastatin tablet 80 mg                                     |                                                             | 3                    |                            |
| 3084035  | Caduet 10 mg-20 mg oral tablet                               |                                                             | 3                    |                            |
| 3122002  | Caduet 5 mg-40 mg oral tablet                                |                                                             | 3                    |                            |
| 3247009  | simvastatin 60 mg oral tablet                                |                                                             | 3                    |                            |
| 3462007  | Crestor 10 mg oral tablet daily                              |                                                             | 3                    |                            |
| 3786012  | amlodipine-atorvastatin 10 mg-10 mg oral tablet              |                                                             | 3                    |                            |
| 3824023  | Simcor 500 mg-40 mg oral tablet, extended release            | niacin-simvastatin 500 mg-40 mg tablet, extended release    | 3                    |                            |
| 3919001  | lovastatin 20 mg tablet                                      |                                                             | 3                    |                            |
| 4007016  | Zocor 40 mg oral tablet po qd                                |                                                             | 3                    |                            |
| 4163075  | Advicor 20 mg-1000 mg tablet, extended release               | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 3                    |                            |
| 4201013  | simvastatin 20 mg oral tablet once daily at bedtime          |                                                             | 3                    |                            |
| 4221011  | Tylenol 650 mg oral every 4 hours as needed for fever        |                                                             | 3                    | TRUE                       |
| 4229018  | Pravachol 20 mg oral tablet po qd                            |                                                             | 3                    |                            |
| 4264002  | atorvastatin 80 mg tablet                                    |                                                             | 3                    |                            |
| 4307011  | Lipitor 20 mg tablet                                         |                                                             | 3                    |                            |
| 4340007  | pravastatin 40 mg tablet                                     |                                                             | 3                    |                            |
| 4348059  | simvastatin 40mg PO daily                                    |                                                             | 3                    |                            |
| 4542018  | Zocor 40 mg tablet                                           |                                                             | 3                    |                            |
| 4565001  | Atorvastatin calcium (lipitor) 40 mg or tabs, 1 tablet daily (home med) |                                                             | 3                    |                            |
| 4623018  | simvastatin 40                                               |                                                             | 3                    |                            |
| 4797010  | amLODIPine-atorvastatin 10 mg-20 mg tablet                   | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 3                    |                            |
| 4897025  | simvastatin oral tablet                                      |                                                             | 3                    |                            |
| 5354164  | ALTOPREV PO                                                  | Lovastatin                                                  | 3                    |                            |
| 5373870  | Crestor 2.5 mg oral tablet                                   |                                                             | 3                    |                            |
| 5407049  | Simvastatin 40 mg tablet once daily at bedtime               |                                                             | 3                    |                            |
| 5549041  | Lovastatin 40 mg or tabs, 1 tablet daily at dinner (home med) |                                                             | 3                    |                            |
| 5657061  | Mevacor 20 mg tablet                                         | lovastatin 20 mg tablet                                     | 3                    |                            |
| 5855051  | Please have a Basic Metabolic Panel and Magnesium and Phosphorus level  drawn on Thursday (1/12), Monday (1/16), Thursday (1/19), and Monday (1/23). |                                                             | 3                    | TRUE                       |
| 5954090  | amLODIPine-atorvastatin 5 mg-20 mg tablet                    | amLODIPine-atorvastatin 5 mg-20 mg tablet                   | 3                    |                            |
| 5956090  | niacin-simvastatin 500 mg-20 mg tablet, extended release     | niacin-simvastatin 500 mg-20 mg tablet, extended release    | 3                    |                            |
| 5957056  | LOVASTATIN 40 MG OR TABS                                     |                                                             | 3                    |                            |
| 6159057  | Simvastatin 10 mg or tabs                                    |                                                             | 3                    |                            |
| 6191018  | Simvastatin 40 mg daily                                      |                                                             | 3                    |                            |
| 6217023  | Simvastatin (zocor) 40 mg or tabs, 1 tablet at bedtime       |                                                             | 3                    |                            |
| 6240022  | Lovastatin 40 MG OR TABS 1 TABLET DAILY AT DINNER            |                                                             | 3                    |                            |
| 6274045  | Simvastatin 40mg qHS                                         |                                                             | 3                    |                            |
| 6494143  | lipitor 40 mg oral daily                                     |                                                             | 3                    |                            |
| 6501115  | Pravastatin Sodium Tab 40 MG                                 |                                                             | 3                    |                            |
| 6521028  | Lovastatin 40 mg. PO QHS                                     |                                                             | 3                    |                            |
| 6613016  | Atorvastatin calcium (lipitor) 40 mg or tabs, 1 tablet daily |                                                             | 3                    |                            |
| 6615054  | Atorvastatin Calcium Tab 40 MG                               |                                                             | 3                    |                            |
| 6641012  | Lovastatin Tab 40 MG                                         |                                                             | 3                    |                            |
| 6656021  | pravastatin 40mg bedtime daily                               |                                                             | 3                    |                            |
| 6912039  | Rosuvastatin Calcium Tab 20 MG (CRESTOR)                     |                                                             | 3                    |                            |
| 6937030  | niacin-simvastatin 1000 mg-40 mg oral tablet, extended release | niacin-simvastatin 1000 mg-40 mg tablet, extended release   | 3                    |                            |
| 7089018  | Lipitor 5mg                                                  |                                                             | 3                    |                            |
| 7121017  | LIPITOR 10 MG OR TABS                                        |                                                             | 3                    |                            |
| 7216010  | ezetimibe-simvastatin 10 mg-80 mg tablet                     | ezetimibe-simvastatin 10 mg-80 mg tablet                    | 3                    |                            |
| 7295012  | amlodipine-atorvastatin                                      | amLODIPine-atorvastatin                                     | 3                    |                            |
| 7388042  | simvastatin 20mg                                             |                                                             | 3                    |                            |
| 7415011  | lipitor 40mg po daily                                        |                                                             | 3                    |                            |
| 7588018  | CRESTOR 5 MG OR TABS                                         |                                                             | 3                    |                            |
| 7866092  | Please have a Basic Metabolic Panel, Magnesium, and Phosphate level  checked in 1 week. |                                                             | 3                    | TRUE                       |
| 7867093  | Simvastatin 40 mg po tabs, 1 tablet at bedtime               |                                                             | 3                    |                            |
| 8016035  | simvastatin 40 mg oral tablet-home medication                |                                                             | 3                    |                            |
| 8017014  | simvastatin 20 mg po daily                                   |                                                             | 3                    |                            |
| 8468022  | Atorvastatin Calcium Tab 10 MG                               |                                                             | 3                    |                            |
| 8982066  | LIPTRUZET 10-80 MG PO TABS                                   | Ezetimibe-Atorvastatin Tab 10-80 MG                         | 3                    |                            |
| 8983141  | EZETIMIBE-ATORVASTATIN PO                                    |                                                             | 3                    |                            |
| 12366459 | Lipitor 80 mg oral tablet                                    | atorvastatin                                                | 3                    |                            |
| 12366564 | atorvastatin-ezetimibe 40 mg-10 mg oral tablet               | atorvastatin-ezetimibe 40 mg-10 mg tablet                   | 3                    |                            |
| 14714970 | AMLODIPINE-ATORVASTATIN 5-10 COMBO DOSE (INP)                |                                                             | 3                    |                            |
| 16010661 | ATORVASTATIN-COENZYME Q10 PO                                 | Atorvastatin-Coenzyme Q10                                   | 3                    |                            |
| 38083    | NICOTINIC ACID 400 MG OR CPCR                                | Niacin Cap CR 400 MG                                        | 2                    | TRUE                       |
| 157537   | FLUVASTATIN SODIUM OR                                        | Fluvastatin Sodium                                          | 2                    |                            |
| 173238   | NIACIN-SIMVASTATIN OR                                        |                                                             | 2                    |                            |
| 2133585  | atorvastatin 40mg every evening at bedtime                   |                                                             | 2                    |                            |
| 2135870  | Crestor daily                                                |                                                             | 2                    |                            |
| 2136860  | crestor 5 daily                                              |                                                             | 2                    |                            |
| 2140079  | crestor 5 mg                                                 |                                                             | 2                    |                            |
| 2141085  | Crestor 5 mg daily                                           |                                                             | 2                    |                            |
| 2142077  | crestor 10mg PO daily                                        |                                                             | 2                    |                            |
| 2143114  | lipitor 40mg once aday                                       |                                                             | 2                    |                            |
| 2143116  | Lipitor tablet 20 mg                                         |                                                             | 2                    |                            |
| 2143154  | lovastatin tablet 40 mg                                      |                                                             | 2                    |                            |
| 2144114  | lipitor 40 mg. orally daily                                  |                                                             | 2                    |                            |
| 2144115  | Lipitor 80 mg daily                                          |                                                             | 2                    |                            |
| 2144642  | Oscal 500 mg, 1 tablet by mouth twice a day                  |                                                             | 2                    | TRUE                       |
| 2145880  | Pravachol 40 mg oral tablet daily                            |                                                             | 2                    |                            |
| 2146107  | Lipitor 20 mg qHS                                            |                                                             | 2                    |                            |
| 2147098  | lipitor 10 daily                                             |                                                             | 2                    |                            |
| 2149113  | Lipitor tablet 10 mg                                         |                                                             | 2                    |                            |
| 2150109  | Lipitor 80 mg oral tablet daily                              |                                                             | 2                    |                            |
| 2150110  | Lipitor tablet                                               |                                                             | 2                    |                            |
| 2151854  | zocor 20mg once aday                                         |                                                             | 2                    |                            |
| 2152849  | zocor 80 mg                                                  |                                                             | 2                    |                            |
| 2153850  | zocor 80 mg orally daily at bedtime                          |                                                             | 2                    |                            |
| 2154742  | vitorin                                                      |                                                             | 2                    |                            |
| 2154845  | zocor 40 mg                                                  |                                                             | 2                    |                            |
| 2155740  | vitorin 10/40MG                                              |                                                             | 2                    |                            |
| 2155841  | zocor 20 mg orally daily                                     |                                                             | 2                    |                            |
| 2156292  | simvastatin OR                                               |                                                             | 2                    |                            |
| 2157295  | simvastatin 40mg every evening                               |                                                             | 2                    |                            |
| 2157298  | simvastin                                                    |                                                             | 2                    |                            |
| 2158294  | simvastatin 20 mg daily                                      |                                                             | 2                    |                            |
| 2159050  | lipitor 10 mg                                                |                                                             | 2                    |                            |
| 2159567  | Zocor                                                        | simvastatin 20 mg tablet                                    | 2                    |                            |
| 2159803  | Lipitor                                                      | atorvastatin 80 mg tablet                                   | 2                    |                            |
| 2160192  | Altoprev tablet, extended release 40 mg                      | lovastatin                                                  | 2                    |                            |
| 2160232  | lovastatin 40 mg daily                                       |                                                             | 2                    |                            |
| 2160810  | atorvastatin 20 mg oral tablet                               | atorvastatin 10 mg tablet                                   | 2                    |                            |
| 2161051  | lipitor 20 mg daily                                          |                                                             | 2                    |                            |
| 2162050  | Lipitor 40                                                   |                                                             | 2                    |                            |
| 2162051  | Lipitor 40mg oral tabs, take one tablet daily                |                                                             | 2                    |                            |
| 2162564  | simvastatin                                                  | simvastatin 40 mg tablet                                    | 2                    |                            |
| 2162878  | Crestor                                                      | rosuvastatin 10 mg tablet                                   | 2                    |                            |
| 2164281  | Caduet tablet 10 mg-10 mg                                    | amLODIPine-atorvastatin                                     | 2                    |                            |
| 2165049  | lipitor 40mg                                                 |                                                             | 2                    |                            |
| 2165051  | lipitor home med                                             |                                                             | 2                    |                            |
| 2165282  | amlodipine-atorvastatin tablet 5 mg-10 mg                    | amLODIPine-atorvastatin                                     | 2                    |                            |
| 2165797  | atorvastatin                                                 | atorvastatin 40 mg tablet                                   | 2                    |                            |
| 2165799  | atorvastatin                                                 | atorvastatin 20 mg tablet                                   | 2                    |                            |
| 2166039  | lipitor 10mg at night                                        |                                                             | 2                    |                            |
| 2166174  | Altoprev tablet, extended release 60 mg                      | lovastatin                                                  | 2                    |                            |
| 2166276  | Caduet tablet 5 mg-80 mg                                     | amLODIPine-atorvastatin                                     | 2                    |                            |
| 2167512  | Advicor 1000 mg-20 mg oral tablet                            | lovastatin-niacin 20 mg-1000 mg tablet, extended release    | 2                    |                            |
| 2171544  | pravastatin 40                                               |                                                             | 2                    |                            |
| 2173543  | pravastatin 80mg daily                                       |                                                             | 2                    |                            |
| 2174365  | fluvastatin 80 mg tablet, extended release oral              | fluvastatin 80 mg tablet, extended release                  | 2                    |                            |
| 2176243  | Simvastatin 20                                               |                                                             | 2                    |                            |
| 2177553  | Vytorin 1 tab daily                                          |                                                             | 2                    |                            |
| 2177917  | Caduet tablet 10 mg-40 mg                                    | amLODIPine-atorvastatin                                     | 2                    |                            |
| 2178616  | Zocor 20mg                                                   |                                                             | 2                    |                            |
| 2179236  | simvastatin 80mg daily at bedtime                            |                                                             | 2                    |                            |
| 2179609  | zocor 80 mg.                                                 |                                                             | 2                    |                            |
| 2180426  | tylenol #3 one or two tabs every 4 hours as needed for pain  |                                                             | 2                    | TRUE                       |
| 2180613  | zocor 20 mg.                                                 |                                                             | 2                    |                            |
| 2180911  | amlodipine-atorvastatin tablet 10 mg-20 mg                   | amLODIPine-atorvastatin                                     | 2                    |                            |
| 2183678  | Advicor 750 mg-20 mg oral tablet                             | lovastatin-niacin 20 mg-750 mg tablet, extended release     | 2                    |                            |
| 2185085  | simvastatin                                                  | simvastatin 80 mg tablet                                    | 2                    |                            |
| 2185088  | Zocor 5 mg tablet oral                                       | simvastatin 5 mg tablet                                     | 2                    |                            |
| 2185248  | Lipitor                                                      | atorvastatin 20 mg tablet                                   | 2                    |                            |
| 2188282  | Crestor                                                      | rosuvastatin 20 mg tablet                                   | 2                    |                            |
| 2189570  | amlodipine-atorvastatin tablet 10 mg-80 mg                   | amLODIPine-atorvastatin 10 mg-80 mg tablet                  | 2                    |                            |
| 2190696  | fluvastatin 40 mg capsule oral                               | fluvastatin 40 mg capsule                                   | 2                    |                            |
| 2367003  | pravachol-home medication                                    |                                                             | 2                    |                            |
| 2428010  | Simvastatin 20 mg at bedtime                                 |                                                             | 2                    |                            |
| 2458012  | Lescol 40 mg oral capsule                                    |                                                             | 2                    |                            |
| 2565023  | lipitor-home medication                                      |                                                             | 2                    |                            |
| 2574008  | simvastatin 40 mg oral tablet once daily                     |                                                             | 2                    |                            |
| 2664003  | ezetimibe-simvastatin 10 mg-10 mg oral tablet                |                                                             | 2                    |                            |
| 2770007  | simvast                                                      |                                                             | 2                    |                            |
| 2825006  | simvastatin 80mg each night                                  |                                                             | 2                    |                            |
| 2895012  | simvastatin 10 mg oral tablet once daily                     |                                                             | 2                    |                            |
| 2970009  | Simvastatin 20mg PO daily                                    |                                                             | 2                    |                            |
| 3036013  | Vytorin tablet                                               |                                                             | 2                    |                            |
| 3043018  | simvastatin 10mg po daily                                    |                                                             | 2                    |                            |
| 3082034  | lipitor 10 mg oral daily                                     |                                                             | 2                    |                            |
| 3097007  | Caduet 10 mg-40 mg oral tablet                               |                                                             | 2                    |                            |
| 3126003  | zocor 10mg po qhs                                            |                                                             | 2                    |                            |
| 3280009  | lovastatin 20 mg                                             |                                                             | 2                    |                            |
| 3372008  | Lipitor 20 mg PO daily                                       |                                                             | 2                    |                            |
| 3401001  | Atorvastatin 80mg qHS                                        |                                                             | 2                    |                            |
| 3418011  | pravastatin daily (home med)                                 |                                                             | 2                    |                            |
| 3544004  | pravastat                                                    |                                                             | 2                    |                            |
| 3615019  | Caduet 10 mg-10 mg tablet                                    | amLODIPine-atorvastatin 10 mg-10 mg tablet                  | 2                    |                            |
| 3656012  | Lipitor 40 mg PO daily                                       |                                                             | 2                    |                            |
| 3834021  | fluvastatin 80 mg tablet, extended release                   | fluvastatin 80 mg tablet, extended release                  | 2                    |                            |
| 3875016  | amlodipine-atorvastatin 10 mg-40 mg tablet                   | amLODIPine-atorvastatin 10 mg-40 mg tablet                  | 2                    |                            |
| 3900016  | Caduet 10 mg-20 mg tablet                                    | amLODIPine-atorvastatin 10 mg-20 mg tablet                  | 2                    |                            |
| 3949004  | Pravastatin 20mg every evening                               |                                                             | 2                    |                            |
| 3960009  | Simcor 1000 mg-20 mg tablet, extended release                | niacin-simvastatin 1000 mg-20 mg tablet, extended release   | 2                    |                            |
| 3992013  | rosuvas                                                      |                                                             | 2                    |                            |
| 4010005  | Crestor 10 mg oral tablet po Qpm                             |                                                             | 2                    |                            |
| 4069018  | simvastatin 10mg qhs                                         |                                                             | 2                    |                            |
| 4161067  | ezetimibe-simvastatin 10 mg-10 mg tablet                     | ezetimibe-simvastatin 10 mg-10 mg tablet                    | 2                    |                            |
| 4243022  | simvastatin 40 mg PO QHS                                     |                                                             | 2                    |                            |
| 4247007  | simvastatin 40 mg oral tablet at bedtime                     |                                                             | 2                    |                            |
| 4259002  | Dilaudid 4 mg oral one tablet every 4 hours as needed for pain |                                                             | 2                    | TRUE                       |
| 4262027  | simvastatin 40 mg oral tablet every night at bedtime         |                                                             | 2                    |                            |
| 4371005  | amlodipine-atorvastatin 5 mg-20 mg oral tablet               |                                                             | 2                    |                            |
| 4482030  | Simvastatin or, 1 tab daily (home med)                       |                                                             | 2                    |                            |
| 4511002  | atorvastatin 20 mg tablet                                    |                                                             | 2                    |                            |
| 4519013  | simvastatin 20mg each night                                  |                                                             | 2                    |                            |
| 5118019  | Crestor 5 mg oral daily                                      |                                                             | 2                    |                            |
| 5133011  | simvastatin 10 mg daily at bedtime                           |                                                             | 2                    |                            |
| 5220025  | Simvastatin 40 mg or tabs, 1 tab by mouth daily after dinner |                                                             | 2                    |                            |
| 5275026  | simvasta                                                     |                                                             | 2                    |                            |
| 5310019  | Lescol 40 mg capsule                                         | fluvastatin 40 mg capsule                                   | 2                    |                            |
| 5351434  | EZETIMIBE-SIMVASTATIN PO                                     | Ezetimibe-Simvastatin                                       | 2                    |                            |
| 5375021  | lovastatin 10 mg tablet, extended release                    | lovastatin 10 mg tablet, extended release                   | 2                    |                            |
| 5517035  | simvastatin 30 mg tablet                                     |                                                             | 2                    |                            |
| 5550035  | fluvastatin 20 mg capsule                                    | fluvastatin 20 mg capsule                                   | 2                    |                            |
| 5551030  | Simvastatin (zocor) 20 mg or tabs, 1 tablet at bedtime (home med) |                                                             | 2                    |                            |
| 5928080  | Rosuvastatin calcium (crestor) 10 mg or tabs                 |                                                             | 2                    |                            |
| 5952026  | atorvastatin 10mg                                            |                                                             | 2                    |                            |
| 6014020  | Atorvastatin calcium (lipitor) 40 mg or tabs                 |                                                             | 2                    |                            |
| 6014027  | Dilaudid 4 mg oral tablet PO Q 4 hours as needed for pain    |                                                             | 2                    | TRUE                       |
| 6015037  | rosuvastatin calcium (crestor) 40 mg oral tablet             |                                                             | 2                    |                            |
| 6038039  | Lovastatin 40 mg or tabs, 1 tablet daily at dinner           |                                                             | 2                    |                            |
| 6069046  | Simvastatin (zocor) 10 mg or tabs, 1 tablet at bedtime       |                                                             | 2                    |                            |
| 6093035  | Atorvastatin calcium (lipitor) 10 mg or tabs, 1 tablet daily (home med) |                                                             | 2                    |                            |
| 6093071  | Simvastatin 80 mg or tabs, 1 tablet daily                    |                                                             | 2                    |                            |
| 6158104  | Atorvastatin calcium 20 mg or tabs, 1 tablet daily           |                                                             | 2                    |                            |
| 6159213  | Pravastatin sodium 20 mg or tabs                             |                                                             | 2                    |                            |
| 6189036  | atorvastain                                                  |                                                             | 2                    |                            |
| 6200016  | Atorvastatin 40mg PO daily                                   |                                                             | 2                    |                            |
| 6218026  | Rosuvastatin calcium (crestor) 5 mg or tabs, 1 tab daily (home med) |                                                             | 2                    |                            |
| 6222037  | Atorvastatin Calcium 20 MG OR TABS 1 TABLET DAILY            |                                                             | 2                    |                            |
| 6228023  | Simvastatin 20 MG OR TABS 1 TABLET AT BEDTIME                |                                                             | 2                    |                            |
| 6238023  | Atorvastatin 80mg daily                                      |                                                             | 2                    |                            |
| 6283016  | Simvastatin (zocor) 20 mg or tabs, 1 tablet at bedtime       |                                                             | 2                    |                            |
| 6329026  | Pravastatin Sodium 20 MG OR TABS 1 TABLET AT BEDTIME         |                                                             | 2                    |                            |
| 6373027  | Isosorbide Mononitrate Tab SR 24HR 60 MG                     |                                                             | 2                    | TRUE                       |
| 6457015  | Simvastatin Tab 10 MG (ZOCOR)                                |                                                             | 2                    |                            |
| 6480026  | Atorvastatin Calcium Tab 40 MG (Base Equivalent)             |                                                             | 2                    |                            |
| 6498136  | Ezetimibe-Simvastatin Tab 10-20 MG (VYTORIN)                 |                                                             | 2                    |                            |
| 6548013  | Pravastatin Sodium Tab 80 MG                                 |                                                             | 2                    |                            |
| 6549017  | Rosuvastatin Calcium Tab 20 MG                               |                                                             | 2                    |                            |
| 6563023  | Crestor 20 mg                                                |                                                             | 2                    |                            |
| 6563029  | simvastatin 40mg every night at bedtime                      |                                                             | 2                    |                            |
| 6584013  | Crestor 10 mg oral every night at bedtime                    |                                                             | 2                    |                            |
| 6613018  | Caduet 2.5 mg-20 mg oral tablet                              | amLODIPine-atorvastatin 2.5 mg-20 mg tablet                 | 2                    |                            |
| 6671053  | Lovastatin 20 mg or tabs, 1 tablet daily at dinner           |                                                             | 2                    |                            |
| 6674069  | Crestor tablet                                               |                                                             | 2                    |                            |
| 6751037  | Simvastatin 5 mg or tabs, 1 tablet at bedtime (home med)     |                                                             | 2                    |                            |
| 6755040  | crestor 40 mg oral daily                                     |                                                             | 2                    |                            |
| 6778015  | simvastatin 10 mg oral tablet daily                          |                                                             | 2                    |                            |
| 6811021  | Lipitor 20 mg oral daily                                     |                                                             | 2                    |                            |
| 6987028  | Pravastatin 40mg PO daily                                    |                                                             | 2                    |                            |
| 7066041  | Rosuvastatin Calcium Tab 20 MG (CRESTOR                      |                                                             | 2                    |                            |
| 7222085  | Simvastatin 40 mg oral tabs 1 TABLET AT BEDTIME              |                                                             | 2                    |                            |
| 7480015  | Simvastatin 20mg nightly                                     |                                                             | 2                    |                            |
| 7580069  | atorvastatin 40mg nightly                                    |                                                             | 2                    |                            |
| 7609016  | Atorvastatin calcium 40 mg or tabs, 1 tablet daily           |                                                             | 2                    |                            |
| 7667023  | zocor 10 mg oral daily                                       |                                                             | 2                    |                            |
| 7732012  | LOVASTATIN 20 MG OR TABS                                     |                                                             | 2                    |                            |
| 7733018  | LIPITOR 40 MG OR TABS                                        |                                                             | 2                    |                            |
| 7766024  | PRAVASTATIN SODIUM 80 MG OR TABS                             |                                                             | 2                    |                            |
| 7785023  | Simvastatin 20 mg po tabs, 1 tablet at bedtime               |                                                             | 2                    |                            |
| 7897020  | ATORVASTATIN CALCIUM 10 MG OR TABS                           |                                                             | 2                    |                            |
| 7907030  | Atorvastatin Calcium Tab 10 MG (Base Equivalent)             |                                                             | 2                    |                            |
| 8133057  | Atorvastatin calcium (lipitor) 20 mg po tabs, 1 tablet daily |                                                             | 2                    |                            |
| 8250022  | Caduet                                                       | amLODIPine-atorvastatin                                     | 2                    |                            |
| 8278081  | NIACIN-SIMVASTATIN ER PO                                     |                                                             | 2                    |                            |
| 8310028  | Livalo 1 mg tablet                                           | pitavastatin 1 mg tablet                                    | 2                    |                            |
| 8666018  | Please have a BMP, Magnesium, and Phosphorus Level           |                                                             | 2                    | TRUE                       |
| 9164035  | Livalo                                                       | pitavastatin                                                | 2                    |                            |
| 10674217 | Liptruzet 10 mg-10 mg oral tablet                            | atorvastatin-ezetimibe 10 mg-10 mg tablet                   | 2                    |                            |
| 11333610 | atorvastatin calcium 80mg                                    |                                                             | 2                    |                            |
| 11384254 | fluvastatin extended release 80 mg oral tablet, extended release | fluvastatin 80 mg tablet, extended release                  | 2                    |                            |
| 11386095 | Liptruzet 20 mg-10 mg oral tablet                            | atorvastatin-ezetimibe 20 mg-10 mg tablet                   | 2                    |                            |
| 13152377 | atorvastatin-ezetimibe 20 mg-10 mg oral tablet               | atorvastatin-ezetimibe 20 mg-10 mg tablet                   | 2                    |                            |



[Back to top](#supplementary-information-about-the-turbo-medication-mapper--tmm---2020-05-25)



<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>