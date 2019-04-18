More UMLS components included in Solr collection, like ...

Prep:  separated out ChEBI export for Solr.  Matching methods are uniquely semicolon separated but not sorted, so there could be multiple lexical representations with the same semantics.  Is tidied up in R training and prediction code.

Was more careful not to report ChEBI entities as if they "belong" to DrON.  Asserting that all DrON terms come from dron-full.owl.  Previously had reported the actual source filename, which led to duplication/noise

Did NDFRT RF generation with "load on CUIs".  NCBO imples that it would be OK to load on codes.  BioPOrtal mappings use the load-on-code URIs, so we're more dependent on the shared-CUI RxNrom matching method now.  NDFRT load-on-code output is smaller.

Note:  the labels containing @s instead of whitespace are alternate labels from NDFRT

NDDF alternate labels were excluded from training and filtered out of prediction results...

FULL_NAME ".Morphine Liq Oral 20 mg/5 mL-HUP" with PK 59991 can be mapped to http://purl.bioontology.org/ontology/NDDF/004089, which has the preferred label “MORPHINE SULFATE 20 mg/5 mL (4 mg/mL) ORAL SOLUTION, ORAL”.  
Unfortunately, NDDF 004089 has the unrelated alternative label "gestodene-ethinyl estradiol", corresponding to an unrelated CUI.
