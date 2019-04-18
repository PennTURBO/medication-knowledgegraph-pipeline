## Move medication mapping predictions from R to RDF

Previously only loaded a small number of columns, only for the 'best' prediction for each FULL_NAME.  Now try all columns (as far as important training features, etc.) for all rows except FALSE-FALSE-FALSE-FALSE proximity predictions

Just remember 
- solrsubmission (query = tidied full name)
- labelContent (subject = term's label, as is)

BUT string similarity was calculated against "noproduct" (words "product" and "containing" removed, and "@" replaced with " ")

Dimensions of CSV file: 4,132,516 x 36

```
> colnames(for.graphdb)
 [1] "trn"                     "R_MEDICATION_URI"        "solrsubmission"          "labelContent"            "term"                   
 [6] "ontology"                "rxnifavailable"          "jaccard"                 "score"                   "cosine"                 
[11] "rank"                    "jw"                      "hwords"                  "hchars"                  "qchars"                 
[16] "qgram"                   "term.count"              "qwords"                  "lv"                      "lcs"                    
[21] "T200"                    "ontology.count"          "rxnMatchMeth"            "altLabel"                "labelType"              
[26] "solr_rxnorm"             "rf_predicted_proximity"  "FALSE-FALSE-FALSE-FALSE" "FALSE-FALSE-FALSE-TRUE"  "FALSE-FALSE-TRUE-FALSE" 
[31] "FALSE-FALSE-TRUE-TRUE"   "FALSE-TRUE-FALSE-FALSE"  "FALSE-TRUE-TRUE-FALSE"   "TRUE-FALSE-FALSE-FALSE"  "TRUE-TRUE-FALSE-FALSE"  
[36] "max.useful.prob" 

> sort(colnames(for.graphdb))
 [1] "altLabel"                "cosine"                  "FALSE-FALSE-FALSE-FALSE" "FALSE-FALSE-FALSE-TRUE"  "FALSE-FALSE-TRUE-FALSE" 
 [6] "FALSE-FALSE-TRUE-TRUE"   "FALSE-TRUE-FALSE-FALSE"  "FALSE-TRUE-TRUE-FALSE"   "hchars"                  "hwords"                 
[11] "jaccard"                 "jw"                      "labelContent"            "labelType"               "lcs"                    
[16] "lv"                      "max.useful.prob"         "ontology"                "ontology.count"          "qchars"                 
[21] "qgram"                   "qwords"                  "rank"                    "rf_predicted_proximity"  "R_MEDICATION_URI"       
[26] "rxnifavailable"          "rxnMatchMeth"            "score"                   "solr_rxnorm"             "solrsubmission"         
[31] "T200"                    "term"                    "term.count"              "trn"                     "TRUE-FALSE-FALSE-FALSE" 
[36] "TRUE-TRUE-FALSE-FALSE"  

 > summary(for.graphdb)
                                      R_MEDICATION_URI   solrsubmission     labelContent           term          
 urn:uuid:00de798f-25b8-4e6d-982a-39c36170bd24:     30   Length:4132516     Length:4132516     Length:4132516    
 urn:uuid:00e72ab6-e7d1-4bac-b677-659a4934894a:     30   Class :character   Class :character   Class :character  
 urn:uuid:01318295-00d4-45f1-b1e6-c1946054920e:     30   Mode  :character   Mode  :character   Mode  :character  
 urn:uuid:015198ea-d744-443f-bb60-f9af5e4837ee:     30                                                           
 urn:uuid:025c4fae-78e0-4a0c-9aee-3514e00e7d09:     30                                                           
 urn:uuid:02735dac-90f4-4d2d-816f-982d00611149:     30                                                           
 (Other)                                      :4132336                                                           
                                                                   ontology       rxnifavailable        jaccard      
 https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM:1105991   Length:4132516     Min.   :0.0000  
 https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMSL/ : 824922   Class :character   1st Qu.:0.1786  
 https://bitbucket.org/uamsdbmi/dron/raw/master/dron-full.owl          : 491541   Mode  :character   Median :0.2800  
 https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMX/  : 319111                      Mean   :0.2980  
 https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MTH/  : 189361                      3rd Qu.:0.4118  
 https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/GS/   : 188476                      Max.   :0.9500  
 (Other)                                                               :1013114                                      
     score            cosine             rank             jw             hwords            hchars           qchars      
 Min.   : 1.343   Min.   :0.00000   Min.   : 1.00   Min.   :0.0000   Min.   :  0.000   Min.   :  1.00   Min.   :  1.00  
 1st Qu.: 6.722   1st Qu.:0.05509   1st Qu.: 4.00   1st Qu.:0.1573   1st Qu.:  1.000   1st Qu.: 14.00   1st Qu.: 26.00  
 Median : 8.247   Median :0.09869   Median :10.00   Median :0.2189   Median :  4.000   Median : 30.00   Median : 36.00  
 Mean   : 8.761   Mean   :0.12660   Mean   :11.45   Mean   :0.2162   Mean   :  4.527   Mean   : 32.87   Mean   : 39.44  
 3rd Qu.:10.148   3rd Qu.:0.17071   3rd Qu.:18.00   3rd Qu.:0.2736   3rd Qu.:  7.000   3rd Qu.: 45.00   3rd Qu.: 49.00  
 Max.   :62.354   Max.   :0.91246   Max.   :30.00   Max.   :1.0000   Max.   :199.000   Max.   :875.00   Max.   :289.00  
                                                                                                                        
     qgram          term.count          qwords             lv              lcs              T200        ontology.count   
 Min.   :  0.00   Min.   :    1.0   Min.   : 0.000   Min.   :  0.00   Min.   :  0.00   Min.   :0.0000   Min.   :  32705  
 1st Qu.: 11.00   1st Qu.:   51.0   1st Qu.: 3.000   1st Qu.: 11.00   1st Qu.: 12.00   1st Qu.:0.0000   1st Qu.:1619852  
 Median : 18.00   Median :  161.0   Median : 5.000   Median : 20.00   Median : 22.00   Median :1.0000   Median :3469702  
 Mean   : 20.55   Mean   :  934.5   Mean   : 6.719   Mean   : 23.56   Mean   : 26.67   Mean   :0.6026   Mean   :3168517  
 3rd Qu.: 27.00   3rd Qu.:  607.0   3rd Qu.: 9.000   3rd Qu.: 31.00   3rd Qu.: 36.00   3rd Qu.:1.0000   3rd Qu.:5067224  
 Max.   :832.00   Max.   :45194.0   Max.   :97.000   Max.   :831.00   Max.   :859.00   Max.   :1.0000   Max.   :5067224  
                                                                                                                         
                rxnMatchMeth        altLabel                                              labelType        solr_rxnorm    
 non-BP-CUI           :1566583   Min.   :0.0000   http://www.w3.org/2000/01/rdf-schema#label   : 563877   Min.   :0.0000  
 RxNorm direct        :1105991   1st Qu.:0.0000   http://www.w3.org/2004/02/skos/core#altLabel : 948612   1st Qu.:0.0000  
 unmapped             : 525898   Median :0.0000   http://www.w3.org/2004/02/skos/core#prefLabel:2620027   Median :0.0000  
 DrOn assertion       : 491541   Mean   :0.2295                                                           Mean   :0.2676  
 CUI; LOOM; non-BP-CUI: 242132   3rd Qu.:0.0000                                                           3rd Qu.:1.0000  
 CUI; non-BP-CUI      : 133224   Max.   :1.0000                                                           Max.   :1.0000  
 (Other)              :  67147                                                                                            
            rf_predicted_proximity FALSE-FALSE-FALSE-FALSE FALSE-FALSE-FALSE-TRUE FALSE-FALSE-TRUE-FALSE FALSE-FALSE-TRUE-TRUE
 FALSE-FALSE-FALSE-TRUE:1116459    Min.   :0.0000          Min.   :0.00000        Min.   :0.00000        Min.   :0.00000      
 TRUE-TRUE-FALSE-FALSE :1024666    1st Qu.:0.1667          1st Qu.:0.01000        1st Qu.:0.03333        1st Qu.:0.00000      
 FALSE-FALSE-TRUE-FALSE: 663541    Median :0.2433          Median :0.05333        Median :0.08000        Median :0.01000      
 FALSE-TRUE-FALSE-FALSE: 634347    Mean   :0.2354          Mean   :0.17605        Mean   :0.15031        Mean   :0.07729      
 FALSE-FALSE-TRUE-TRUE : 338933    3rd Qu.:0.3100          3rd Qu.:0.34000        3rd Qu.:0.18333        3rd Qu.:0.08000      
 TRUE-FALSE-FALSE-FALSE: 289734    Max.   :0.5000          Max.   :1.00000        Max.   :1.00000        Max.   :1.00000      
 (Other)               :  64836                                                                                               
 FALSE-TRUE-FALSE-FALSE FALSE-TRUE-TRUE-FALSE TRUE-FALSE-FALSE-FALSE TRUE-TRUE-FALSE-FALSE max.useful.prob 
 Min.   :0.000000       Min.   :0.000000      Min.   :0.000000       Min.   :0.00000       Min.   :0.1567  
 1st Qu.:0.003333       1st Qu.:0.000000      1st Qu.:0.000000       1st Qu.:0.00000       1st Qu.:0.3767  
 Median :0.040000       Median :0.000000      Median :0.003333       Median :0.05333       Median :0.4567  
 Mean   :0.126078       Mean   :0.017989      Mean   :0.062540       Mean   :0.15431       Mean   :0.4924  
 3rd Qu.:0.183333       3rd Qu.:0.006667      3rd Qu.:0.036667       3rd Qu.:0.29333       3rd Qu.:0.5767  
 Max.   :1.000000       Max.   :1.000000      Max.   :1.000000       Max.   :1.00000       Max.   :1.0000  

```

## As a CSV file:

```ubuntu@ip-172-31-88-67:~$ head pred_has_potential_without_nddf_alt_rownums.csv`
"trn","R_MEDICATION_URI","solrsubmission","labelContent","term","ontology","rxnifavailable","jaccard","score","cosine","rank","jw","hwords","hchars","qchars","qgram","term.count","qwords","lv","lcs","T200","ontology.count","rxnMatchMeth","altLabel","labelType","solr_rxnorm","rf_predicted_proximity","FALSE-FALSE-FALSE-FALSE","FALSE-FALSE-FALSE-TRUE","FALSE-FALSE-TRUE-FALSE","FALSE-FALSE-TRUE-TRUE","FALSE-TRUE-FALSE-FALSE","FALSE-TRUE-TRUE-FALSE","TRUE-FALSE-FALSE-FALSE","TRUE-TRUE-FALSE-FALSE","max.useful.prob"
1,"urn:uuid:429dcfee-82a6-48d7-b640-8f9965425404","0.000002g nafcillin injectable","nafcillin injectable product","http://purl.bioontology.org/ontology/RXNORM/1156404","https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM","http://purl.bioontology.org/ontology/RXNORM/1156404",0.266666666666667,7.3178864,0.260735752313845,2,0.258730158730159,2,28,30,9,224,3,11,11,1,5067224,"RxNorm direct",0,"http://www.w3.org/2004/02/skos/core#prefLabel",1,"FALSE-FALSE-FALSE-TRUE",0.186666666666667,0.246666666666667,0.07,0.04,0.0866666666666667,0.186666666666667,0.0166666666666667,0.166666666666667,0.246666666666667```

## observed proximities:

- FFFF useless
- FFFT separated by 2 permitted links
- FFTF separated by 1 permitted link
- FFTT separated by at least one 1-link and one 2-link paths
- FTFF siblings sharing same is-a parent
- FTTF siblings and connected by some one-link path
- TFFF exact match
- TTFF exact match and has "is_a" parent

8 used out of 2^4=16

----

## StarDog Virtual Graph config file "periods.ttl"

```
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix rfres: <http://example.com/rfres/> .
@prefix sm: <tag:stardog:api:mapping:> .

rfres:{trn} a rfres:rfres ;
        rfres:R_MEDICATION_URI "{R_MEDICATION_URI}" ;
        rfres:term "{term}";
        rfres:ontology "{ontology}";
        rfres:rxnifavailable "{rxnifavailable}";
        rfres:jaccard "{jaccard}";
        rfres:score "{score}";
        rfres:cosine "{cosine}";
        rfres:rank "{rank}";
        rfres:jw "{jw}";
        rfres:hwords "{hwords}";
        rfres:hchars "{hchars}";
        rfres:qchars "{qchars}";
        rfres:qgram "{qgram}";
        rfres:term.count "{term.count}";
        rfres:qwords "{qwords}";
        rfres:lv "{lv}";
        rfres:lcs "{lcs}";
        rfres:T200 "{T200}";
        rfres:ontology.count "{ontology.count}";
        rfres:rxnMatchMeth "{rxnMatchMeth}";
        rfres:altLabel "{altLabel}";
        rfres:labelType "{labelType}";
        rfres:solr_rxnorm "{solr_rxnorm}";
        rfres:rf_predicted_proximity "{rf_predicted_proximity}";

        rfres:FALSE-FALSE-FALSE-FALSE "{FALSE-FALSE-FALSE-FALSE}";
        rfres:FALSE-FALSE-FALSE-TRUE "{FALSE-FALSE-FALSE-TRUE}";
        rfres:FALSE-FALSE-TRUE-FALSE "{FALSE-FALSE-TRUE-FALSE}";
        rfres:FALSE-FALSE-TRUE-TRUE "{FALSE-FALSE-TRUE-TRUE}";
        rfres:FALSE-TRUE-FALSE-FALSE "{FALSE-TRUE-FALSE-FALSE}";
        rfres:FALSE-TRUE-TRUE-FALSE "{FALSE-TRUE-TRUE-FALSE}";
        rfres:TRUE-FALSE-FALSE-FALSE "{TRUE-FALSE-FALSE-FALSE}";
        rfres:TRUE-TRUE-FALSE-FALSE "{TRUE-TRUE-FALSE-FALSE}";
        rfres:FALSE-FALSE-FALSE-FALSE "{FALSE-FALSE-FALSE-FALSE}";

        rfres:max.useful.prob "{max.useful.prob}";


        sm:map [
                sm:table "pred_has_potential_without_nddf_alt_rownums" ;
        ] .
```

```
ubuntu@ip-172-31-88-67:~$ stardog-6.1.2/bin/stardog-admin virtual import rf_res periods.ttl pred_has_potential_without_nddf_alt_rownums.csv
Successfully imported 140 505 544 triples into rf_res
```
## Export from StarDog

```
ubuntu@ip-172-31-88-67:~$ stardog-6.1.2/bin/stardog data export -f PRETTY_TURTLE -s -v rf_res
Exported 140,505,544 statements from rf_res to /home/ubuntu/.exports/rf_res-2019-04-15.ttl in 4.747 min
```

8 GB, ~ 600 MB gzipped

*probably could have written a StarDog VG configuration that would have eliminated the need for the following steps*

Import into graph http://example.com/resource/rf_res-2019-04-15_strings in repo  pred_has_potential_without_nddf_alt_first_strings on host medmapping.pennturbo.org:7200

> rf_res-2019-04-15.ttl Imported successfully in 20m 2s.

## Tidying

- count entries
- double check all properties are present
- cast URIs and create UUID records
- check for NA solr_rxnorm URIs
- document
- this uses shallow semantics like several other database imports... change to realism?
- check MRB's birth control/opioid complaint
    - .Morphine Liq Oral 20 mg/5 mL-HUP

```
PREFIX mydata: <http://example.com/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
insert {
    graph mydata:med_map_rf_pred {
        ?uuid a mydata:med_map_rf_pred ;
            #        rdfs:comment ?s ;
            mydata:R_MEDICATION_URI ?R_MEDICATION_URI ;
            mydata:labelType ?labelType ;
            mydata:ontology ?ontology ;
            mydata:rxnifavailable ?rxnifavailable ;
            mydata:solrMatchTerm ?solrMatchTerm ;
            mydata:rf_predicted_proximity ?rf_predicted_proximity ;
            mydata:rxnMatchMeth ?rxnMatchMeth ;
            #        mydata:solr_rxnormString ?solr_rxnormString ;
            #        mydata:altLabelString ?altLabelString ;
            #        mydata:T200String ?T200String ;
            mydata:solr_rxnorm ?solr_rxnorm ;
            mydata:altLabel ?altLabel ;
            mydata:T200 ?T200 ;
            mydata:lcs ?lcs;
            mydata:lv ?lv;
            mydata:hchars ?hchars;
            mydata:hwords ?hwords;
            mydata:ontology_count ?ontology_count;
            mydata:qchars ?qchars;
            mydata:qgram ?qgram;
            mydata:qwords ?qwords;
            mydata:solr_rank ?rank;
            mydata:term_count ?term_count;
            mydata:FALSE_FALSE_FALSE_FALSE ?FALSE_FALSE_FALSE_FALSE;
            mydata:FALSE_FALSE_FALSE_TRUE ?FALSE_FALSE_FALSE_TRUE;
            mydata:FALSE_FALSE_TRUE_FALSE ?FALSE_FALSE_TRUE_FALSE;
            mydata:FALSE_FALSE_TRUE_TRUE ?FALSE_FALSE_TRUE_TRUE;
            mydata:FALSE_TRUE_FALSE_FALSE ?FALSE_TRUE_FALSE_FALSE;
            mydata:FALSE_TRUE_TRUE_FALSE ?FALSE_TRUE_TRUE_FALSE;
            mydata:jaccard ?jaccard;
            mydata:jw ?jw;
            mydata:max_useful_prob ?max_useful_prob;
            mydata:solr_score ?score;
            mydata:TRUE_FALSE_FALSE_FALSE ?TRUE_FALSE_FALSE_FALSE;
            mydata:TRUE_TRUE_FALSE_FALSE ?TRUE_TRUE_FALSE_FALSE;
    } 
}
where {
    graph <http://example.com/resource/rf_res-2019-04-15_strings> {
        ?s a <http://example.com/rfres/rfres> ;
           <http://example.com/rfres/R_MEDICATION_URI> ?R_MEDICATION_URI_STRING ;
           <http://example.com/rfres/labelType> ?labelTypeString ;
           <http://example.com/rfres/ontology> ?ontologyString ;
           <http://example.com/rfres/rxnifavailable> ?rxnifavailableString ;
           <http://example.com/rfres/term> ?termString ;
           <http://example.com/rfres/rf_predicted_proximity> ?rf_predicted_proximityString ;
           <http://example.com/rfres/rxnMatchMeth> ?rxnMatchMethString ;
           #
           <http://example.com/rfres/solr_rxnorm> ?solr_rxnormString ;
           <http://example.com/rfres/altLabel> ?altLabelString ;
           <http://example.com/rfres/T200> ?T200String ;
           #
           <http://example.com/rfres/FALSE-FALSE-FALSE-FALSE> ?FALSE_FALSE_FALSE_FALSEString ;
           <http://example.com/rfres/FALSE-FALSE-FALSE-TRUE> ?FALSE_FALSE_FALSE_TRUEString ;
           <http://example.com/rfres/FALSE-FALSE-TRUE-FALSE> ?FALSE_FALSE_TRUE_FALSEString ;
           <http://example.com/rfres/FALSE-FALSE-TRUE-TRUE> ?FALSE_FALSE_TRUE_TRUEString ;
           <http://example.com/rfres/FALSE-TRUE-FALSE-FALSE> ?FALSE_TRUE_FALSE_FALSEString ;
           <http://example.com/rfres/FALSE-TRUE-TRUE-FALSE> ?FALSE_TRUE_TRUE_FALSEString ;
           <http://example.com/rfres/jaccard> ?jaccardString ;
           <http://example.com/rfres/jw> ?jwString ;
           <http://example.com/rfres/max.useful.prob> ?max_useful_probString ;
           <http://example.com/rfres/score> ?scoreString ;
           <http://example.com/rfres/TRUE-FALSE-FALSE-FALSE> ?TRUE_FALSE_FALSE_FALSEString ;
           <http://example.com/rfres/TRUE-TRUE-FALSE-FALSE> ?TRUE_TRUE_FALSE_FALSEString ;
           <http://example.com/rfres/lcs> ?lcsString ;
           <http://example.com/rfres/lv> ?lvString ;
           <http://example.com/rfres/hchars> ?hcharsString ;
           <http://example.com/rfres/hwords> ?hwordsString ;
           <http://example.com/rfres/ontology.count> ?ontology_countString ;
           <http://example.com/rfres/qchars> ?qcharsString ;
           <http://example.com/rfres/qgram> ?qgramString ;
           <http://example.com/rfres/qwords> ?qwordsString ;
           <http://example.com/rfres/rank> ?rankString ;
           <http://example.com/rfres/term.count> ?term_countString ;
           optional {
            ?s <http://example.com/rfres/rxnifavailable> ?rxnifavailableString .
            bind(uri(?rxnifavailableString) as ?rxnifavailable)
        }
    }
    bind(xsd:integer(?lcsString) as ?lcs)
    bind(xsd:integer(?lvString) as ?lv)
    bind(xsd:integer(?hcharsString) as ?hchars)
    bind(xsd:integer(?hwordsString) as ?hwords)
    bind(xsd:integer(?ontology_countString) as ?ontology_count)
    bind(xsd:integer(?qcharsString) as ?qchars)
    bind(xsd:integer(?qgramString) as ?qgram)
    bind(xsd:integer(?qwordsString) as ?qwords)
    bind(xsd:integer(?rankString) as ?rank)
    bind(xsd:integer(?term_countString) as ?term_count)
    bind(xsd:float(?FALSE_FALSE_FALSE_FALSEString) as ?FALSE_FALSE_FALSE_FALSE)
    bind(xsd:float(?FALSE_FALSE_FALSE_TRUEString) as ?FALSE_FALSE_FALSE_TRUE)
    bind(xsd:float(?FALSE_FALSE_TRUE_FALSEString) as ?FALSE_FALSE_TRUE_FALSE)
    bind(xsd:float(?FALSE_FALSE_TRUE_TRUEString) as ?FALSE_FALSE_TRUE_TRUE)
    bind(xsd:float(?FALSE_TRUE_FALSE_FALSEString) as ?FALSE_TRUE_FALSE_FALSE)
    bind(xsd:float(?FALSE_TRUE_TRUE_FALSEString) as ?FALSE_TRUE_TRUE_FALSE)
    bind(xsd:float(?jaccardString) as ?jaccard)
    bind(xsd:float(?jwString) as ?jw)
    bind(xsd:float(?max_useful_probString) as ?max_useful_prob)
    bind(xsd:float(?scoreString) as ?score)
    bind(xsd:float(?TRUE_FALSE_FALSE_FALSEString) as ?TRUE_FALSE_FALSE_FALSE)
    bind(xsd:float(?TRUE_TRUE_FALSE_FALSEString) as ?TRUE_TRUE_FALSE_FALSE)
    bind(uuid() as ?uuid)
    bind(uri(?R_MEDICATION_URI_STRING) as ?R_MEDICATION_URI)
    bind(uri(?labelTypeString) as ?labelType)
    bind(uri(?ontologyString) as ?ontology)
    bind(uri(?termString) as ?solrMatchTerm)
    bind(uri(concat("http://example.com/rfres/", ?rf_predicted_proximityString)) as ?rf_predicted_proximity)
    bind(uri(concat("http://example.com/resource/", ENCODE_FOR_URI(?rxnMatchMethString))) as ?rxnMatchMeth)
    bind(if(?solr_rxnormString="0", false, true) as ?solr_rxnorm)
    bind(if(?altLabelString="0", false, true) as ?altLabel)
    bind(if(?T200String="0", false, true) as ?T200)
}
```

> Added 135705869 statements. Update took 47m 16s, minutes ago.

```
PREFIX mydata: <http://example.com/resource/>
select (count(distinct ?uuid) as ?count) where {
    graph mydata:med_map_rf_pred {
        ?uuid a mydata:med_map_rf_pred 
    }
}
```

> 4 132 516

## Dump from GraphDB for reimport into actual medication mapping graph

```
ubuntu@ip-172-31-90-126:/consolidation$ curl -X GET --header 'Accept: application/x-binary-rdf' 'http://localhost:7200/repositories/pred_has_potential_without_nddf_alt_first_strings/statements?context=%3Chttp%3A%2F%2Fexample.com%2Fresource%2Fmed_map_rf_pred%3E' > \
med_map_rf_pred_retain_TTFF_20190417.brf
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 14.7G    0 14.7G    0     0  34.6M      0 --:--:--  0:07:16 --:--:-- 34.6M
```

## Import into graph http://example.com/resource/med_map_rf_pred via web interface

> med_map_rf_pred_retain_TTFF_20190417.brf

>   Imported successfully in 27m 13s.
