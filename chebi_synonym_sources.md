## Motivation: get more medical synonyms for Solr, but not formulae, etc.

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
(?as as ?mediri) (?ap as ?labelpred) ?source (lcase(str(?at)) as ?medlabel) (lcase(str(?rawLabel)) as ?prefLabel)
where {
    values ?ap {
        oboInOwl:hasRelatedSynonym oboInOwl:hasExactSynonym
    }
    #  oboInOwl:hasDbXref can also be used as an annotated property 
    #    (in addition to a source-attributing predicate)
    # where do "band name" assertions come from?
    values ?source {
        "EuroFIR" "Beilstein" "FooDB" "EBI_Industry_Programme" "PubChem" "VSDB" "KEGG_DRUG" "WHO_MedNet" "DrugBank"
    }
    graph <http://purl.obolibrary.org/obo/chebi.owl> {
        ?s a owl:Axiom ;
           owl:annotatedTarget ?at ;
           owl:annotatedProperty ?ap ;
           oboInOwl:hasDbXref ?source ;
           owl:annotatedSource ?as .
        ?as rdfs:label ?rawLabel .
        filter( (lcase(str(?rawLabel))) != (lcase(str(?at))))
    }
}
```
## Approach

```SPARQL
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
select
#*
?source (count(distinct ?s) as ?count)
where {
    values ?x {
        oboInOwl:hasRelatedSynonym oboInOwl:hasExactSynonym
    }
    #  oboInOwl:hasDbXref can also be used as an annotated property 
    #    (in addition to a source-attributing predicate)
    ?s a owl:Axiom ;
       ?ap ?ao ;
       owl:annotatedProperty ?x ;
       oboInOwl:hasDbXref ?source .
} 
group by ?source
order by desc(count(distinct ?s))
```



| source                 | chebi  annotations | using | notes                                                        |
| ---------------------- | ------------------ | ----- | ------------------------------------------------------------ |
| ChEBI                  | 82485              |       | low clinical focus                                           |
| IUPAC                  | 53623              |       | low clinical focus                                           |
| ChemIDplus             | 30458              |       | low clinical focus                                           |
| HMDB                   | 24899              |       | low clinical focus                                           |
| KEGG_COMPOUND          | 19981              |       | low clinical focus                                           |
| UniProt                | 13059              |       | low clinical focus                                           |
| SUBMITTER              | 12634              |       | low clinical focus                                           |
| DrugCentral            | 6319               |       | low clinical focus                                           |
| NIST_Chemistry_WebBook | 5841               |       | low clinical focus                                           |
| LIPID_MAPS             | 2735               |       | lipid like molecules                                         |
| PDBeChem               | 1659               |       | low clinical focus                                           |
| DrugBank               | 1529               | TRUE  | English, Latin and Romance language terms for drugs, plus some codes and  formulae |
| WHO_MedNet             | 1427               | TRUE  | English, Latin and Romance language terms for drugs          |
| KEGG_DRUG              | 1312               | TRUE  |                                                              |
| JCBN                   | 1226               |       | amino acids, peptides, glycans                               |
| MetaCyc                | 932                |       | low clinical focus                                           |
| Alan_Wood's_Pesticides | 550                |       | pesticides                                                   |
| ChEMBL                 | 456                |       | lots of handy looking drug names, but lots of mile-long formulae too |
| KEGG_GLYCAN            | 424                |       | glycans                                                      |
| UM-BBD                 | 270                |       | formulae, codes and names. I don't recognize many.           |
| MolBase                | 262                |       | mostly metal complex formulae                                |
| CBN                    | 254                |       | formulae, codes and names. I don't recognize many.           |
| KNApSAcK               | 207                |       | formulae, codes and names. I don't recognize many.           |
| IUBMB                  | 163                |       | mostly formulae                                              |
| SMID                   | 157                |       | mostly formulae                                              |
| Patent                 | 121                |       | mostly formulae                                              |
| IUPHAR                 | 80                 |       | has some handy aliases like 5-HT for serotonin. lots of formulae, too |
| RESID                  | 61                 |       | amino acid enantiomers and other formulae                    |
| COMe                   | 43                 |       | metal-protein complexes?                                     |
| LINCS                  | 38                 |       | has a few pronounceable aliases (for investigational drugs?) https://lincs.hms.harvard.edu/db/ |
| PDB                    | 30                 |       | low clinical focus                                           |
| PPDB                   | 28                 |       | pesticides                                                   |
| EMBL                   | 23                 |       | tRNAs!                                                       |
| GlyTouCan              | 5                  |       | glycans                                                      |
| EuroFIR                | 4                  | TRUE  |                                                              |
| Beilstein              | 2                  | TRUE  |                                                              |
| FooDB                  | 2                  | TRUE  |                                                              |
| EBI_Industry_Programme | 1                  | TRUE  |                                                              |
| PubChem                | 1                  | TRUE  |                                                              |
| VSDB                   | 1                  | TRUE  |                                                              |
