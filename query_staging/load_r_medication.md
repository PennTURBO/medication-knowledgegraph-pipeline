| Row Labels              | MDM | ODS | Grand Total |
|-------------------------|-----|-----|-------------|
| AMOUNT                  | 1   | 1   | 2           |
| CONTROLLED_MED_YN       | 1   | 1   | 2           |
| DEA_CLASS               | 1   | 1   | 2           |
| FK_3M_NCID_ID           | 1   | 1   | 2           |
| FORM                    | 1   | 1   | 2           |
| FULL_NAME               | 1   | 1   | 2           |
| GENERIC_NAME            | 1   | 1   | 2           |
| PHARMACY_CLASS          | 1   | 1   | 2           |
| PHARMACY_SUBCLASS       | 1   | 1   | 2           |
| PK_MEDICATION_ID        | 1   | 1   | 2           |
| RECORD_STATE            | 1   | 1   | 2           |
| SIMPLE_GENERIC_NAME     | 1   | 1   | 2           |
| THERAPEUTIC_CLASS       | 1   | 1   | 2           |
| MDM_INSERT_UPDATE_FLAG  | 1   |     | 1           |
| MDM_LAST_UPDATE_DATE    | 1   |     | 1           |
| ROUTE_DESCRIPTION       | 1   |     | 1           |
| ROUTE_TYPE              | 1   |     | 1           |
| RXNORM                  | 1   |     | 1           |
| RXNORM_DEFINITION       | 1   |     | 1           |
| FK_ROUTE_ID             |     | 1   | 1           |
| SOURCE_CODE             |     | 1   | 1           |
| SOURCE_LAST_UPDATE_DATE |     | 1   | 1           |
| SOURCE_ORIG_ID          |     | 1   | 1           |
| Grand Total             | 19  | 17  | 36          |


```
SELECT * 
FROM MDM.R_MEDICATION
FULL OUTER JOIN ODS.R_MEDICATION
ON ODS.R_MEDICATION.PK_MEDICATION_ID = MDM.R_MEDICATION.PK_MEDICATION_ID;
```

940 000+ rows


Check in R

```
library(readr)
mdm.ods.meds.20180403 <-
  read_csv(
    "C:/Users/Mark Miller/_SELECT_FROM_MDM_R_MEDICATION_FULL_OUTER_JOIN_ODS_R_MEDICATION_O_201904031356.csv"
  )

Parsed with column specification:
cols(
  .default = col_character(),
  PK_MEDICATION_ID = col_integer(),
  CONTROLLED_MED_YN = col_integer(),
  FK_3M_NCID_ID = col_double(),
  RXNORM = col_integer(),
  MDM_LAST_UPDATE_DATE = col_datetime(format = ""),
  PK_MEDICATION_ID_1 = col_integer(),
  FK_ROUTE_ID = col_integer(),
  CONTROLLED_MED_YN_1 = col_integer(),
  SOURCE_LAST_UPDATE_DATE = col_datetime(format = ""),
  FK_3M_NCID_ID_1 = col_double()
)
See spec(...) for full column specifications.
|=================================================================================================================================| 100%  233 MB
Warning message:
Duplicated column names deduplicated: 'PK_MEDICATION_ID' => 'PK_MEDICATION_ID_1' [20], 'SIMPLE_GENERIC_NAME' => 'SIMPLE_GENERIC_NAME_1' [21], 'GENERIC_NAME' => 'GENERIC_NAME_1' [22], 'THERAPEUTIC_CLASS' => 'THERAPEUTIC_CLASS_1' [23], 'PHARMACY_CLASS' => 'PHARMACY_CLASS_1' [24], 'PHARMACY_SUBCLASS' => 'PHARMACY_SUBCLASS_1' [25], 'AMOUNT' => 'AMOUNT_1' [26], 'FORM' => 'FORM_1' [27], 'CONTROLLED_MED_YN' => 'CONTROLLED_MED_YN_1' [29], 'DEA_CLASS' => 'DEA_CLASS_1' [30], 'RECORD_STATE' => 'RECORD_STATE_1' [31], 'FULL_NAME' => 'FULL_NAME_1' [34], 'FK_3M_NCID_ID' => 'FK_3M_NCID_ID_1' [36] 
> 
> dim(mdm.ods.meds.20180403)
[1] 941214     36

> rxnflag <- !is.na(mdm.ods.meds.20180403$RXNORM)
> table(rxnflag)
rxnflag
 FALSE   TRUE 
893 194  48 020 

```

Load into GraphDB with OntoRefine:

```
PREFIX mydata: <http://example.com/resource/>
PREFIX spif: <http://spinrdf.org/spif#>
# does anything have to be made optional here?  or is evverything guarnateed to be at least NA?
# that would require after-the-fact clearnup
# also cast rxnorms to URIs
# does anything needto be casted to numeric?
insert {
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?myRowId a mydata:Row ;
            mydata:File ?File ;
            mydata:PK_MEDICATION_ID ?PK_MEDICATION_ID ;
            mydata:FULL_NAME ?FULL_NAME ;
            mydata:PHARMACY_CLASS ?PHARMACY_CLASS ;
            mydata:SIMPLE_GENERIC_NAME ?SIMPLE_GENERIC_NAME ;
            mydata:GENERIC_NAME ?GENERIC_NAME ;
            mydata:THERAPEUTIC_CLASS ?THERAPEUTIC_CLASS ;
            mydata:PHARMACY_SUBCLASS ?PHARMACY_SUBCLASS ;
            mydata:AMOUNT ?AMOUNT ;
            mydata:FORM ?FORM ;
            mydata:ROUTE_DESCRIPTION ?ROUTE_DESCRIPTION ;
            mydata:ROUTE_TYPE ?ROUTE_TYPE ;
            mydata:CONTROLLED_MED_YN ?CONTROLLED_MED_YN ;
            mydata:DEA_CLASS ?DEA_CLASS ;
            mydata:RECORD_STATE ?RECORD_STATE ;
            mydata:FK_3M_NCID_ID ?FK_3M_NCID_ID ;
            mydata:RXNORM ?RXNORM ;
            mydata:RXNORM_DEFINITION ?RXNORM_DEFINITION ;
            mydata:MDM_LAST_UPDATE_DATE ?MDM_LAST_UPDATE_DATE ;
            mydata:MDM_INSERT_UPDATE_FLAG ?MDM_INSERT_UPDATE_FLAG ;
            mydata:PK_MEDICATION_ID_1 ?PK_MEDICATION_ID_1 ;
            mydata:FULL_NAME_1 ?FULL_NAME_1 ;
            mydata:SOURCE_ORIG_ID ?SOURCE_ORIG_ID .
    }
} WHERE {
    SERVICE <ontorefine:1714094139089> {
        ?row a mydata:Row ;
             mydata:File ?File ;
             mydata:PK_MEDICATION_ID ?PK_MEDICATION_ID ;
             mydata:FULL_NAME ?FULL_NAME ;
             mydata:PHARMACY_CLASS ?PHARMACY_CLASS ;
             mydata:SIMPLE_GENERIC_NAME ?SIMPLE_GENERIC_NAME ;
             mydata:GENERIC_NAME ?GENERIC_NAME ;
             mydata:THERAPEUTIC_CLASS ?THERAPEUTIC_CLASS ;
             mydata:PHARMACY_SUBCLASS ?PHARMACY_SUBCLASS ;
             mydata:AMOUNT ?AMOUNT ;
             mydata:FORM ?FORM ;
             mydata:ROUTE_DESCRIPTION ?ROUTE_DESCRIPTION ;
             mydata:ROUTE_TYPE ?ROUTE_TYPE ;
             mydata:CONTROLLED_MED_YN ?CONTROLLED_MED_YN ;
             mydata:DEA_CLASS ?DEA_CLASS ;
             mydata:RECORD_STATE ?RECORD_STATE ;
             mydata:FK_3M_NCID_ID ?FK_3M_NCID_ID ;
             mydata:RXNORM ?RXNORM ;
             mydata:RXNORM_DEFINITION ?RXNORM_DEFINITION ;
             mydata:MDM_LAST_UPDATE_DATE ?MDM_LAST_UPDATE_DATE ;
             mydata:MDM_INSERT_UPDATE_FLAG ?MDM_INSERT_UPDATE_FLAG ;
             mydata:PK_MEDICATION_ID_1 ?PK_MEDICATION_ID_1 ;
             mydata:FULL_NAME_1 ?FULL_NAME_1 ;
             mydata:SOURCE_ORIG_ID ?SOURCE_ORIG_ID .
        bind(uuid() as ?myRowId)	
    }
}
```

> Added 22589136 statements. Update took 36m 46s, today at 21:06. @ r5.4xl

```
select (count(distinct ?s) as ?count)
where {
    graph <http://example.com/resource/mdm_ods_meds_20180403_unique_cols.csv> {
        ?s a ?t
    }
}
```

> 941214

```
select (count(distinct ?s) as ?count)
where {
    graph <http://example.com/resource/mdm_ods_meds_20180403_unique_cols.csv> {
        ?s ?p "NA"
    }
}
```

> 941013

```
delete {
    graph <http://example.com/resource/mdm_ods_meds_20180403_unique_cols.csv> {
        ?s ?p "NA"
    }
}
where {
    graph <http://example.com/resource/mdm_ods_meds_20180403_unique_cols.csv> {
        ?s ?p "NA"
    }
}
```

> Removed 11946667 statements. Update took 1m 19s, moments ago.

941214 http://example.com/resource/Row  individuals before and after


