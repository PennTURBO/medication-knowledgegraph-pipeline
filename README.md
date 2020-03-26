# TURBO Medication Mapping

## Introduction

The PennTURBO medication mapper (TMM) takes strings describing medications or medication orders and predicts RxNorm terms, specifically RXCUIs, with the same meaning. TMM can tolerate a wide range of specificity, e.g. "acetaminophen" vs "500 mg Tylenol oral tablets", but it is not intended to parse medication phrases out of longer narratives.

This document provides some brief background with performance metrics, explains how to run the software components, and then provides more detailed information about the mechanism/strategy.

## Background

TMM is written in R and has been tested with version 3.6.2 on a 32 GB MacBook Pro. Besides R and a handful of libraries (including rJava, and therefore a JRE), the only requirement is the RxNav-in-a-box (RXB) Docker Container, Docker itself, and a slight modification to the dockerfile. (TMM has been tested with Docker Desktop community edition 2.2.0.3 and the January, 2020 RXB. This author has found that API requests to other versions of RXB, including February 2020, return no responses.) Training on (or classifying over) hundreds of thousands of medication strings will likely require more RAM and/or docker tuning.

TMM uses the approach of training a random forest classifier to inspect medication search results and classify them as **identical** to the latent meaning, **related** by one named, _allowable_, RxNorm relation, or **more distant**. Then the unknown strings are searched using the same method and classified with the previously mentioned random forest. **Identical** predictions can be taken as is, **more distant** predictions should be discarded, and **related** predictions should be spot checked.

When the classifier is trained on 10,000 known medication string/RXCUI pairs, the ability to predict the **identical** and **more distant** cases is very good. When the classifier determines that there is one **relation** between the RXCUI returned by a search engine and the RXCUI that would best describe the unknown medication string, there can be some ambiguity about what the true relation is. Specifically, while the specificity for these non-identical but directly-adjacent cases tend to be in the 0.90s, the sensitivity can be lower than 0.50. Training over the previously mentioned volume of data takes less than one hour.

```
 Class: identical
 Sensitivity     0.8518
 Specificity     0.9811
```

```
Class: more distant
Sensitivity     0.9832
Specificity     0.8013
```

The coverage, or ability to provide something other than a 'more distant' result for each PDS R_MEDICATION is assessed
independently and appears to be a string correlate of the `identical` sensitivity and the 'more distant' specificity.

**Latest coverage: 0.89**

## Prerequisites
### Training and Classification R Scripts
- [R Interpreter](https://cran.r-project.org/)
  - Install R libraries in an interactive R session with `install.packages(<"package1">, <"package2">,...,<"packageN">)`
      - RJDBC
      - ROCR
      - caret
      - config
      - ggplot2
      - randomForest
      - readr
      - splitstackshape
      - stringdist
      - stringr

  - RJDBC requires the rJava R library, which requires a JRE. TMM has been tested with

    ```
    Java(TM) SE Runtime Environment (build 1.8.0_241-b07)
    Java HotSpot(TM) 64-Bit Server VM (build 25.241-b07, mixed mode)
    ```

    rJava can be more difficult to install and auto-configure, compared to other R packages. If this is an absolute blocker, RJDBC could probably be replaced with RODBC, along with corresponding code changes.

- Oracle and MySql JDBC Drivers

   TMM has been tested with `ojdbc8.jar` and `mysql-connector-java-8.0.19.jar`.  Downloading Oracle and MySQL JDBC driver may require an [Oracle account](https://profile.oracle.com/myprofile/account/create-account.jspx).
  - The Oracle 12c JDBC drivers can be found [here](https://www.oracle.com/database/technologies/jdbc-drivers-12c-downloads.html)
  - The MySQL driver can be found [here](https://dev.mysql.com/downloads/connector/j/)
      - no MySQL server is required. TMM will make SQL queries against the MySQL database embedded in the RxNav-in-a-Box Container. (There are a few datatypes which are not accessible via REST APIs).

### RxNav-in-a-Box

- RxNav-in-a-Box ([RXB](https://rxnav.nlm.nih.gov/RxNav-in-a-Box.html))
  - Downloading RXB requires obtaining a [UMLS license](https://uts.nlm.nih.gov/license.html), which requires completing some use-case documentation and waiting a few days.
- [Docker Desktop](https://www.docker.com/products/docker-desktop), or any version that supports Docker Compose
  - RXB states the following requirements:
    - 12 gigabytes of memory to devote to Docker containers
    - 50 gigabytes of disk space

## Configuration

The current classifier assumes that the unknowns will come from the Penn Data Store clinical warehouse at the University of Pennsylvania's Healthcare system. The script could be modified to take input from other sources. In the current state, PDS credentials are required, possibly along with a VPN connection and/or port forwarding. Those database and networking concerns are left to the reader.

### Expose RXB's MySQL port
Before starting RXB, modify `docker-compose.yml` by **adding** a port mapping as below:
```
services:
  rxnav_db:
    ports:
    - "3307:3306"
 ```

### Create the configuration file for the training and testing scripts
`rxnav_med_mapping.yaml` is the default name of configuration file needed for the training and classification scripts, template named `rx_med_mapping.yaml.template` is provided.  The scripts should be run from the same folder as the config file.  (They could be modified to take a configuration path as a command line argument. Note: no file-missing or database-unavailable tests are present in the current scripts.) Other files required by TMM are specified in the configuration file and can reside elsewhere.  

Copy `rx_med_mapping.yaml.template` to `rx_med_mapping.yaml` then modify the file:

- Set `rxnav.mysql.port` and `rxnav.mysql.pw` to the exposed port (3307 in the case above) and root password for RXB's MySql server.
  - The root password is located in `mysql-secret.txt`
- Set `pds.host`, `pds.port`, `pds.database`, `pds.user`, and `pds.pw` with the connection parameters for PDS (or any other RDBMS source of medication strings.
    - TMM requires input as a four-columned data frame. Right now, it is obtained with a SQL query against the Penn Data Store. Reading it from a CSV file is an upcoming feature.
        - source stable identifier for the medication (string, required)
        - source name of medication (string, required)
        - source generic name (string, optional)
        - source count (numeric, strongly recommended)
            - how common is this prescription? For example, for how many different people has it been ordered?
- Several other parameters include constrains on whether long queries should be repeated (vs reading from a cache saved to disk), what fraction of the available data are used for training and how the random forest is trained. These will be described in greater detail at a later date.

#### `rxnav_med_mapping.yaml` Parameters

- `reissue.pds.query`: read medication strings live from PDS, or from `pds.rmedication.result.loadpath`
    - If the query is repeated, the results will be saved to `pds.rmedication.result.savepath`
- `min.empi.count`: (default = 5). medication strings that have been ordered for fewer EMPIs (and indirectly fewer distinct patients) will not be classified. In PDS, there is a very large number of orders attributed to one single EMPI. The strings frequently include a lot of personalized drug-utilization information, and even clinician or patient names. These can be left out for decreasing the time required, increasing the prediction accuracy, and
- `normalization.file`: unknown medication strings can be scrubbed of tokens that are source specific, or even replaced with tokens that are characteristic of RxNorm. For example, "po tabs" -> "oral tablet"
- `pds2rxnav.fraction`: what percentage of the PDS medication strings should be classified? Should be set to 100 for routine use. Lower percentages are for a faster development cycle.
- `rxaui.asserted.strings.chunk.count`: when retrieving strings corresponding to RXAUIs via SQL, how many chunks of RXAUIs should be sent. (Should probably be changed to number of RXAUIs per chunk)
    - *RXB's approximate match may return several RXCUIs for a given input medication string, or even multiple instances of the same RXCUI, with different RXAUIs (RxNorm atom unique identifiers, corresponding to the different string s used by data provides upstream of RxNorm.) The approximate match API does not, however, return the strings for the returned RXAUIs, presumably because any RXB installation could be opened up for whole-world use, and the RXCUI-RXAUI-string tuples are intellectual property of the upstream providers.*
- `approximate.row.count`: how many string/RXCUI pairs from RXNAV should be used for training. Lower counts result in faster performance but lower accuracy. Counts over 10,000 have resulted in an unresponsive RXB on the developer's laptop.
- `approximate.max.chars`: don't use medication strings with a greater number of characters for training. This was empirically based on the character count distribution of PDS R_MEDICATION FULL_NAMES.
- `tune.rf`: **Not currently in use.** If additional tuning is desired, `tuning_followon.R` should be run after `rxnav_med_mapping_proximity_training_no_tuning.R`, and the optimal parameters like ntree, mtry and feature importance should be saved to this configuration file, `rxnav_med_mapping.yaml`.
- `train.split`: after isolating some rows for coverage determination, what fraction of the search results should be used for training (vs testing/validation/performance passement.)
- `target.col:` what should the random forest predict? One possibility is solely whether the RXCUI in a search result is identical with the latent RXCUI best describing a search input. The currently favored target is "RELA", or the relation that RXNORM knows exists between the RXCUI of the **searched** medication string and the RXCUI from each search result. If the two RXCUIs are identical, the RELA is overwritten with "identical". If RxNorm knows of no one-step relation between the searched and matched RXCUIs, "more distant" is overwritten.
- `factor.levels`: a named dictionary of sorted lists for the acceptable levels of categorical predictors and targets (like RELA). Uncommon levels are omitted. Sorting is used to ensure that the numerical levels are consistent between the training data and the unknown input (for classification.)
- `important.features`: training features determined to have high importance by `tuning_followon.R`
- `static.ntree`: optimal number of trees to predict before creating the ensemble forest, from `tuning_followon.R`
- `static.mtry`: optimal number of features for training each tree. Can be determined with `tuning_followon.R`, but will be overridden to |important features| - 1 if that's lower
- `testing.confusion.writepath`: file path for saving a training and validation performance report.
- `coverage.check.fraction`: Before breaking the available training data into train and test/ validate fractions, another fraction is set aside for determining coverage, or the fraction of medication strings submitted to the search engine and classifier that result in a prediction of something other than "more distant". This is not a random fraction of row; it is all rows corresponding to a randomly selected list of medication strings.
- `rf.model.savepath`: after training the random forest classifier (in `rxnav_med_mapping_proximity_training_no_tuning.R`), the classifier will be saved as a binary object to this path/filename
- `rf.model.loadpath`: this path/filename will be read to obtain the random forest classifier for predicting unknowns in `rxnav_med_mapping_pds_proximity_classifier.R`
- `excluded.term.types`: some terms returned by the RXB approximate match search are categorically unlike the terms used in PDS. These term types (TTYs) will be excluded from the search results before training the random forest.
- `allowed.synonym.sources`: along with `excluded.term.types`, synonyms are generally excluded from the search results submitted for training the random forest classifier. Exceptions are mode for synonyms from these sources (SABs)
- `final.predictions.writepath`: the search results and proximity classifications for the unknown medication strings will be written to this CSV file. These are the final results and include several QC columns, which are described below.

## Running
- Start RXB
- Start any VPN/port forwarding necessary to connect to PDS

### Train a TTM model

- `$ Rscript rxnav_med_mapping_proximity_training_no_tuning.R`

This trains a random forest classifier using training data from (*ADD: brief description of where the medication strings and rx mappings used to train the classifier are located.  Include description of any hardcoded filtering applied to get the final training set*).  It saves the model in (*ADD:filename/path/location of saved model*).

### Classify medication strings (PDS `R_MEDICATION.FULL_NAME`s) with a trained TTM model

- `$ Rscript rxnav_med_mapping_pds_proximity_classifier.R`

This loads a model saved in (*ADD:filename/path/location of model*) and classifies the medication strings specified in (*ADD: brief description of where the medication strings that are being classified are located.  Include any hardcoded filtering/assumptions.*).  Generates output files in (*ADD:filename/path/location of output files*).

### Generate Medication KnowledgeGraph
(*ADD: Add instructions and brief description of the process to generate med knowledgegraph*)

## Classification Output
### Columns in the output of the TMM search & classification

There are currently 53 columns

Each row corresponds to one classified RxNav approximate search result. Up to two different strings can be submitted for each R_MEDICATION: a normalized version of the FULL_NAME and a lowercased version of the GENERIC_NAME, and up to 50 results can be returned for each API call.

Any number of these columns could be included in a knowledge graph version of these results, or it could be culled row-wise for the most useful result for each R_MEDICATION. For example, any 'identical' classification, or the highest scoring classification across all of the various RxNorm relations. Most rows are 'more distant'. Those could be discarded for brevity or retained for QC.

- query.val: the string (from PDS R_MEDICATION) that was actually submitted to the RxNav approximate search API. (normalized FULL_NAME or lowercased GENERIC_NAME) See also xxx
- STR.lc: lowercased version of the string hit by the RxNav approximate search API.
- normalized: FULL_NAMEs in which source-specific language has been either scrubbed or replaced with RxNorm language with eh same meaning ("po tabs" -> "oral tablet")
- FK_MEDICATION_ID: actually the PK of a R_MEDICATION (but accessed via a join from ORDER_MED)
- FULL_NAME: raw value from R_MEDICATION
- GENERIC_NAME: raw value from R_MEDICATION
- RXNORM: raw value from R_MEDICATION. These are often wrong, in the sense that they don't represent all of the knowledge in the FULL_NAME. The way in which information is lost or altered is inconsistent.
- EMPI_COUNT: proxy for the number of patients who received an order for this R_MEDICATION. Assuming one unique and singular EMPI per patient.
- pds.rxn.annotated: is R_MEDICATION.RXNORM non-NULL/non-empty/non-zero
- GENERIC_NAME.lc: lowercased GENERIC_NAME with no other normalization
- rxaui: RXAUI for strings returned by the RxNav approximate search API. More granular than the rxcui from the same API, due to the fact that RxNorm models knowledge from each upstream provider as atoms and then aggregates to RXCUIs with the same meaning.
- rxcui: RXCUI for strings returned by the RxNav approximate search API. See also rxaui.
- score: semi-opaque assessment of the quality of an RxNav approximate search result. 0 to 100.
- rank: 1 for the RxNav approximate search result with the highest score, which may not necessarily be 100.
- rxcui.count: number of RxNav approximate search results, across all inputs, with a given RXCUI.
- rxcui.freq: rxcui.count/(sum(rxcui.count))
- rxaui.count: number of RxNav approximate search results, across all inputs, with a given RXAUI.
- rxaui.freq: rxaui.count/(sum(rxaui.count))
- SAB.sr: what upstream source did the RxNav approximate search result come from?
- SUPPRESS: RxNorm internal. Ignored at this point.
- TTY.sr: what is the type of the RxNav approximate search result? Ingredient, brand name, multi-pack, etc.?
- STR: raw string hit by the RxNav approximate search API.
- query.source: indicates whether a normalized R_MEDICATION FULL_NAME or a lowercased GENERIC_NAME was submitted to the RxNav approximate search API

#### The next several columns are measures of [string distance](https://www.rdocumentation.org/packages/stringdist/versions/0.9.5.5/topics/stringdist-metrics)

(Between the medication string **submitted** to the RxNav approximate search API `a` and a string **returned** by the API `b`). Some are integers from 0 to infinity and some are reals from 0.0 to 1.0. Lower numbers mean more similar strings.

- lv: Levenshtein edit distance. The number of deletions, insertions and substitutions necessary to turn `b` into `a`
- lcs: longest common substring **distance**
- qgram: qgram distance
- cosine: cosine distance between the qgrams in `a` and the qgrams in `b`. More sensitive to differences in qgram repeats.
- jaccard: jaccard distance between the qgrams in `a` and the qgrams in `b`. Less sensitive to differences in qgram repeats.
- jw: See the documentation above.

#### Lengths of strings in characters and words

- q.char: character length of query.val, the submitted string
- q.words: number of words-like tokens in query.val, using count of space characters as a proxy. Queries have already been scrubbed of leading and training space as well as duplicate spaces and whitespace characters other than XXX
- sr.char: character length of STR, the string returned by the RxNav approximate search API.
- sr.words: word count for STR

----

- rf_responses: prediction from the random forest. Either the name of the RxNorm relation that links a RxNav approximate search result's RXCUI to the RXCUI that could best explain a R_MEDICATION


### Probabilities that each row should be classified in any one of the following states

Besides 'identical to' and 'more distant', each of these is the probability that the R_MEDICATION's (latent) RXCU is related to the RxNav approximate search result's RXCUI by the named relation

- consists_of
- constitutes
- contained_in
- contains
- form_of
- has_form
- has_ingredient
- has_part
- has_quantified_form
- has_tradename
- identical: probability that a R_MEDICATION's most representative RXCUI and a RxNav approximate search result's RXCUI are identical... an exact match, with no loss or addition of knowledge
- ingredient_of
- inverse_isa
- isa
- more distant: probability that there is more than one semantic hop between a R_MEDICATION's most representative RXCUI and a RxNav approximate search result's RXCUI. From TMM's perspective, the search result is wrong.
- part_of
- quantified_form_of
- tradename_of

----

- override: whenever the RxNav approximate search result's score is 100, this is set to identical, regardless of rf_responses. Likewise, it is set to more distant when the score is 0. Otherwise, override is rf_responses
