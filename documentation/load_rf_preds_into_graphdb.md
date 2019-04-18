```ubuntu@ip-172-31-88-67:~$ head pred_has_potential_without_nddf_alt_rownums.csv`
"trn","R_MEDICATION_URI","solrsubmission","labelContent","term","ontology","rxnifavailable","jaccard","score","cosine","rank","jw","hwords","hchars","qchars","qgram","term.count","qwords","lv","lcs","T200","ontology.count","rxnMatchMeth","altLabel","labelType","solr_rxnorm","rf_predicted_proximity","FALSE-FALSE-FALSE-FALSE","FALSE-FALSE-FALSE-TRUE","FALSE-FALSE-TRUE-FALSE","FALSE-FALSE-TRUE-TRUE","FALSE-TRUE-FALSE-FALSE","FALSE-TRUE-TRUE-FALSE","TRUE-FALSE-FALSE-FALSE","TRUE-TRUE-FALSE-FALSE","max.useful.prob"
1,"urn:uuid:429dcfee-82a6-48d7-b640-8f9965425404","0.000002g nafcillin injectable","nafcillin injectable product","http://purl.bioontology.org/ontology/RXNORM/1156404","https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM","http://purl.bioontology.org/ontology/RXNORM/1156404",0.266666666666667,7.3178864,0.260735752313845,2,0.258730158730159,2,28,30,9,224,3,11,11,1,5067224,"RxNorm direct",0,"http://www.w3.org/2004/02/skos/core#prefLabel",1,"FALSE-FALSE-FALSE-TRUE",0.186666666666667,0.246666666666667,0.07,0.04,0.0866666666666667,0.186666666666667,0.0166666666666667,0.166666666666667,0.246666666666667```

## observed proximities:

FFFF useless
FFFT separated by 2 permitted links
FFTF separated by 1 permitted link
FFTT separated by at least one 1-link and one 2-link paths
FTFF siblings sharing same is-a parent
FTTF siblings and connected by some one-link path
TFFF exact match
TTFF exact match and has "is_a" parent

8 used out of 2^4=16

Previously:
Wrote from R to CSV
Used StarDog VG import with "periods.ttl" config
Then dumped to TTL
Then loaded into GraphDB

Any intermediate cleanup steps?

## periods.ttl

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
Export from StarDog

*probably could have written a StarDog VG configuration that would have eliminated the need for the following steps*

## Ontorefine

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
