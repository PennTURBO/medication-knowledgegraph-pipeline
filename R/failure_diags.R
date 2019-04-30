library(readr)

# sdf.cols <- colnames(solr.dropouts.frame)
# 
# temp <- eapply(.GlobalEnv, function(current.obj) {
#   idf <- is.data.frame(current.obj)
#   if (idf) {
#     co.cols <-  colnames(current.obj)
#     intersect.size <- length(intersect(co.cols, sdf.cols))
#     return(intersect.size)
#   }
# })
# 
# temp <- unlist(temp)
# 
# temp <- cbind.data.frame(names(temp), unlist(temp))
# 
# colnames(uphs.plus.expanded)

distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051 <-
  read_csv("/terabyte/distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051.csv")

useless.frame <-
  uphs.plus.expanded[uphs.plus.expanded$MedicationName %in% uncovered.fullnames ,]

useless.frame <-
  merge(x = useless.frame, y = distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051,
        by = "PK_MEDICATION_ID", all.x = TRUE)

###

only.nddf.alt.frame <- uphs.plus.expanded[uphs.plus.expanded$MedicationName %in% only.nddf.alt.medications ,]

only.nddf.alt.frame <-
  merge(x = only.nddf.alt.frame, y = distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051,
        by = "PK_MEDICATION_ID", all.x = TRUE)

###   ###   ###

pred.has.potential <- result.frame

pred.cols <- pred.has.potential[, pred.col.names]

max.useful.prob <- apply(
  pred.cols,
  1,
  FUN = function(my.current.row) {
    return(max(my.current.row))
  }
)

pred.has.potential$max.useful.prob.by.row <- max.useful.prob

# ###   ###   ###
#
# pred.has.potential.without.nddf.alt <-
#   pred.has.potential[!(
#     pred.has.potential$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
#       pred.has.potential$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"
#   ) ,]
#
# pred.has.potential.only.nddf.alt <-
#   pred.has.potential[(
#     pred.has.potential$ontology == "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF." &
#       pred.has.potential$labelType == "http...www.w3.org.2004.02.skos.core.altLabel"
#   ) ,]
#
# only.nddf.alt.medications <-
#   setdiff(pred.has.potential.only.nddf.alt$MedicationName,
#           pred.has.potential.without.nddf.alt$MedicationName)
#
# ###   ###   ###

aggdata <-
  aggregate(
    pred.has.potential$max.useful.prob,
    by = list(pred.has.potential$MedicationName),
    FUN = max,
    na.rm = TRUE
  )

names(aggdata) <- c("MedicationName", "max.useful.prob.by.med")

pred.has.potential.max.useful.prob <-
  merge(x = pred.has.potential,
        y = aggdata,
        by = c("MedicationName"))

pred.has.potential.max.useful.prob$relative.prob <-
  pred.has.potential.max.useful.prob$max.useful.prob.by.row / pred.has.potential.max.useful.prob$max.useful.prob.by.med

###   ###   ###

pred.has.potential.without.nddf.alt <-
  pred.has.potential.max.useful.prob

for.graphdb <- pred.has.potential.without.nddf.alt[, c( "MedicationName",
                                                        "PK_MEDICATION_ID", "s", "solrsubmission", "labelContent", "term", "ontology",
                                                        "rxnifavailable", "jaccard", "score", "cosine", "rank", "jw", "hwords",
                                                        "hchars", "qchars", "qgram", "term.count", "qwords", "lv", "lcs", "T200",
                                                        "ontology.count", "rxnMatchMeth",
                                                        "http...www.w3.org.2004.02.skos.core.altLabel", "labelType",
                                                        "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
                                                        "rf_predicted_proximity", "FALSE-FALSE-FALSE-FALSE", "FALSE-FALSE-FALSE-TRUE",
                                                        "FALSE-FALSE-TRUE-FALSE", "FALSE-FALSE-TRUE-TRUE", "FALSE-TRUE-FALSE-FALSE",
                                                        "FALSE-TRUE-TRUE-FALSE", "TRUE-FALSE-FALSE-FALSE", "TRUE-TRUE-FALSE-FALSE",
                                                        "max.useful.prob.by.row", "max.useful.prob.by.med", "relative.prob" )]

oldnames <- colnames(for.graphdb)

newnames <-  c( "MedicationName", "PK_MEDICATION_ID", "R_MEDICATION_URI",
                "solrsubmission", "labelContent", "term", "ontology", "rxnifavailable",
                "jaccard", "score", "cosine", "rank", "jw", "hwords", "hchars", "qchars",
                "qgram", "term.count", "qwords", "lv", "lcs", "T200", "ontology.count",
                "rxnMatchMeth", "altLabel", "labelType", "solr_rxnorm",
                "rf_predicted_proximity", "FALSE-FALSE-FALSE-FALSE", "FALSE-FALSE-FALSE-TRUE",
                "FALSE-FALSE-TRUE-FALSE", "FALSE-FALSE-TRUE-TRUE", "FALSE-TRUE-FALSE-FALSE",
                "FALSE-TRUE-TRUE-FALSE", "TRUE-FALSE-FALSE-FALSE", "TRUE-TRUE-FALSE-FALSE",
                "max.useful.prob.by.row", "max.useful.prob.by.med", "relative.prob" )


names(for.graphdb) <-newnames

# recast ontolgy and labeltype columns back to real URIs
# make URIs for other categoricals, like the sematic proximity?

for.graphdb$labelType <- factor(
  x = for.graphdb$labelType,
  levels = c(
    "http...www.w3.org.2000.01.rdf.schema.label",
    "http...www.w3.org.2004.02.skos.core.altLabel",
    "http...www.w3.org.2004.02.skos.core.prefLabel"
  ),
  labels = c(
    "http://www.w3.org/2000/01/rdf-schema#label",
    "http://www.w3.org/2004/02/skos/core#altLabel",
    "http://www.w3.org/2004/02/skos/core#prefLabel"
  )
)

for.graphdb$ontology <- factor(
  x = for.graphdb$ontology,
  levels = c(
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.CVX.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.DRUGBANK.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.GS.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MDDB.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MED.RT.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMSL.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MMX.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.MTH.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_FDA.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NCI_NCPDP.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDDF.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.NDFRT.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.RXNORM",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.SPN.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.ATC.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.UMD.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USP.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.USPMG.",
    "https...www.nlm.nih.gov.research.umls.sourcereleasedocs.current.VANDF.",
    "ftp...ftp.ebi.ac.uk.pub.databases.chebi.ontology.chebi.owl.gz",
    "https...bitbucket.org.uamsdbmi.dron.raw.master.dron.full.owl"
  ),
  labels = c(
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/CVX/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/DRUGBANK/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/GS/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MDDB/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MED-RT/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMSL/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MMX/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/MTH/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_FDA/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NCI_NCPDP/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDFRT/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/SPN/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/ATC/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/UMD/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USP/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/USPMG/",
    "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/VANDF/",
    "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz",
    "https://bitbucket.org/uamsdbmi/dron/raw/master/dron-full.owl"
  )
)


# na.tracking <- apply(for.graphdb, 2, anyNA)
#
# na.tracking <-
#   cbind.data.frame(names(na.tracking), as.logical(na.tracking))

for.graphdb <- merge(x = for.graphdb,
                     y =
                       distinct_mdm_om_PK_ORDER_MED_ID_FROM_per_rm_PK_MEDICATION_201904192051,
                     by =
                       "PK_MEDICATION_ID",
                     all.x = TRUE)

for.graphdb <- for.graphdb[, c( "MedicationName", "PK_MEDICATION_ID",
                                "COUNT(DISTINCTOM.PK_ORDER_MED_ID)", "R_MEDICATION_URI", "solrsubmission",
                                "labelContent", "term", "ontology", "rxnifavailable", "jaccard", "score",
                                "cosine", "rank", "jw", "hwords", "hchars", "qchars", "qgram", "term.count",
                                "qwords", "lv", "lcs", "T200", "ontology.count", "rxnMatchMeth", "altLabel",
                                "labelType", "solr_rxnorm", "rf_predicted_proximity",
                                "FALSE-FALSE-FALSE-FALSE", "FALSE-FALSE-FALSE-TRUE", "FALSE-FALSE-TRUE-FALSE",
                                "FALSE-FALSE-TRUE-TRUE", "FALSE-TRUE-FALSE-FALSE", "FALSE-TRUE-TRUE-FALSE",
                                "TRUE-FALSE-FALSE-FALSE", "TRUE-TRUE-FALSE-FALSE", "max.useful.prob.by.row",
                                "max.useful.prob.by.med", "relative.prob" ) ,]

names(for.graphdb) <- c( "MedicationName", "PK_MEDICATION_ID",
                         "ORDER_MED_count", "R_MEDICATION_URI", "solrsubmission", "labelContent",
                         "term", "ontology", "rxnifavailable", "jaccard", "score", "cosine", "rank",
                         "jw", "hwords", "hchars", "qchars", "qgram", "term_count", "qwords", "lv",
                         "lcs", "T200", "ontology_count", "rxnMatchMeth", "altLabel", "labelType",
                         "solr_rxnorm", "rf_predicted_proximity", "FALSE_FALSE_FALSE_FALSE",
                         "FALSE_FALSE_FALSE_TRUE", "FALSE_FALSE_TRUE_FALSE", "FALSE_FALSE_TRUE_TRUE",
                         "FALSE_TRUE_FALSE_FALSE", "FALSE_TRUE_TRUE_FALSE", "TRUE_FALSE_FALSE_FALSE",
                         "TRUE_TRUE_FALSE_FALSE", "max_useful_prob_by_row", "max_useful_prob_by_med",
                         "relative_prob" )

true.boost <- 1.1
rxn.boost <- 1.1

for.graphdb$boosted <- for.graphdb$relative_prob

true.pred <-
  grepl(pattern = "^TRUE", x = for.graphdb$rf_predicted_proximity)
table(true.pred)

for.graphdb$boosted[true.pred] <-
  for.graphdb$boosted[true.pred] * true.boost

rxn.pred <- !is.na(for.graphdb$rxnifavailable)
table(rxn.pred)

for.graphdb$boosted[rxn.pred] <-
  for.graphdb$boosted[rxn.pred] * rxn.boost

for.graphdb$FFFF.pred <-
  for.graphdb$rf_predicted_proximity == "FALSE-FALSE-FALSE-FALSE"
table(for.graphdb$FFFF.pred)


###   ###   ###


table(for.graphdb$ontology)
table(for.graphdb$labelType)

table(for.graphdb$ontology, for.graphdb$labelType)
table(for.graphdb$labelType, for.graphdb$ontology)

nrow(for.graphdb)

for.graphdb <-
  for.graphdb[!(for.graphdb$ontology == "https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDDF/" &
                for.graphdb$labelType == "http://www.w3.org/2004/02/skos/core#altLabel") ,]

nrow(for.graphdb)

###   ###   ###


# for.graphdb <-
#   for.graphdb[!for.graphdb$FFFF.pred &
#                 for.graphdb$ORDER_MED_count > 1 ,]

for.graphdb <-
  for.graphdb[!for.graphdb$FFFF.pred , ]

nrow(for.graphdb)

aggdata <-
  aggregate(
    for.graphdb$boosted,
    by = list(for.graphdb$R_MEDICATION_URI),
    FUN = max,
    na.rm = TRUE
  )

names(aggdata) <- c("R_MEDICATION_URI", "max_boosted")

for.graphdb <-
  merge(x = for.graphdb,
        y = aggdata,
        by = c("R_MEDICATION_URI"))

for.graphdb$relative_boosted <-
  for.graphdb$boosted / for.graphdb$max_boosted


###

for.graphdb$rf_predicted_proximity <-
  sapply(for.graphdb$rf_predicted_proximity, function(current.val) {
    gsub(pattern = "-",
         replacement = "_",
         x = current.val)
  })

trn <- 1:nrow(for.graphdb)
for.graphdb <- cbind(trn, for.graphdb)

dim(for.graphdb)

head(for.graphdb)

temp <- unique(for.graphdb[,c("PK_MEDICATION_ID","ORDER_MED_count")])
temp <- table(temp$ORDER_MED_count)
temp <- cbind.data.frame(as.numeric(names(temp)), as.numeric(temp))
colnames(temp) <- c("ORDER_MEDs","R_MEDICATION_count")

# na.tracking <- apply(for.graphdb, 2, anyNA)
# 
# na.tracking <-
#   cbind.data.frame(names(na.tracking), as.logical(na.tracking))

# write.csv(for.graphdb, file = "/terabyte/rf_predictions_boosted_ordercounts_no_ffff_201904251619.csv", row.names = FALSE)

# write.csv(for.graphdb.order.counts, file = "/terabyte/hgf_only_analgesics_rf_predictions_unfiltered_ordercounts.csv", row.names = FALSE)
# write.csv(for.graphdb, file = "/terabyte/hgf_only_analgesics_rf_predictions_twoplus_no_ffff_ordercounts.csv", row.names = FALSE)
# write.csv(uphs.vs.solr.hit, "uphs_vs_solr_hit_hfg_only_analgesics.csv")

my.repo <- "med_map_support_20180403"

sparql.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo)

update.endpoint <-
  paste0("http://localhost:7200/repositories/",
         my.repo,
         "/statements")

query.list <- c(
#   "tidy" = '
#   PREFIX mydata: <http://example.com/resource/>
# PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
# PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
# insert {
#     graph <http://example.com/resource/rf_predictions_boosted_ordercounts_no_ffff_201904251619> {
#         ?uuid a  mydata:rfres ;
#             mydata:R_MEDICATION_URI ?R_MEDICATION_URI ;
#             mydata:labelType ?labelType ;
#             mydata:ontology ?ontology ;
#             mydata:rxnifavailable ?rxnifavailable ;
#             mydata:solrMatchTerm ?solrMatchTerm ;
#             mydata:rf_predicted_proximity ?rf_predicted_proximity ;
#             mydata:rxnMatchMeth ?rxnMatchMeth ;
#             mydata:solr_rxnorm ?solr_rxnorm ;
#             mydata:altLabel ?altLabel ;
#             mydata:T200 ?T200 ;
#             mydata:lcs ?lcs;
#             mydata:lv ?lv;
#             mydata:hchars ?hchars;
#             mydata:hwords ?hwords;
#             mydata:ontology_count ?ontology_count;
#             mydata:qchars ?qchars;
#             mydata:qgram ?qgram;
#             mydata:qwords ?qwords;
#             mydata:solr_rank ?rank;
#             mydata:term_count ?term_count;
#             mydata:FALSE_FALSE_FALSE_FALSE ?FALSE_FALSE_FALSE_FALSE;
#             mydata:FALSE_FALSE_FALSE_TRUE ?FALSE_FALSE_FALSE_TRUE;
#             mydata:FALSE_FALSE_TRUE_FALSE ?FALSE_FALSE_TRUE_FALSE;
#             mydata:FALSE_FALSE_TRUE_TRUE ?FALSE_FALSE_TRUE_TRUE;
#             mydata:FALSE_TRUE_FALSE_FALSE ?FALSE_TRUE_FALSE_FALSE;
#             mydata:FALSE_TRUE_TRUE_FALSE ?FALSE_TRUE_TRUE_FALSE;
#             mydata:jaccard ?jaccard;
#             mydata:jw ?jw;
#             mydata:max_useful_prob ?max_useful_prob;
#             mydata:solr_score ?score;
#             mydata:TRUE_FALSE_FALSE_FALSE ?TRUE_FALSE_FALSE_FALSE;
#             mydata:TRUE_TRUE_FALSE_FALSE ?TRUE_TRUE_FALSE_FALSE;
#             mydata:max_useful_prob_by_row ?max_useful_prob_by_row;
#             mydata:max_useful_prob_by_med ?max_useful_prob_by_med;
#             mydata:relative_prob ?relative_prob;
#             mydata:boosted ?boosted;
#             mydata:max_boosted ?max_boosted ;
#             mydata:relative_boosted  ?relative_boosted ;
#     }
# }
# where {
#     graph <http://example.com/resource/rf_predictions_boosted_ordercounts_no_ffff_201904251619_strings>  {
#         ?s a mydata:rfres ;
#            mydata:FALSE_FALSE_FALSE_FALSE  ?FALSE_FALSE_FALSE_FALSEString ;
#            mydata:FALSE_FALSE_FALSE_TRUE  ?FALSE_FALSE_FALSE_TRUEString ;
#            mydata:FALSE_FALSE_TRUE_FALSE  ?FALSE_FALSE_TRUE_FALSEString ;
#            mydata:FALSE_FALSE_TRUE_TRUE  ?FALSE_FALSE_TRUE_TRUEString ;
#            mydata:FALSE_TRUE_FALSE_FALSE  ?FALSE_TRUE_FALSE_FALSEString ;
#            mydata:FALSE_TRUE_TRUE_FALSE  ?FALSE_TRUE_TRUE_FALSEString ;
#            mydata:ORDER_MED_count  ?ORDER_MED_countString ;
#            mydata:PK_MEDICATION_ID  ?PK_MEDICATION_IDString ;
#            mydata:R_MEDICATION_URI  ?R_MEDICATION_URIString ;
#            mydata:T200  ?T200String ;
#            mydata:TRUE_FALSE_FALSE_FALSE  ?TRUE_FALSE_FALSE_FALSEString ;
#            mydata:TRUE_TRUE_FALSE_FALSE  ?TRUE_TRUE_FALSE_FALSEString ;
#            mydata:altLabel  ?altLabelString ;
#            mydata:cosine  ?cosineString ;
#            mydata:hchars  ?hcharsString ;
#            mydata:hwords  ?hwordsString ;
#            mydata:jaccard   ?jaccardString ;
#            mydata:jw    ?jwString ;
#            mydata:labelContent    ?labelContentString ;
#            mydata:labelType    ?labelTypeString ;
#            mydata:lcs    ?lcsString ;
#            mydata:lv   ?lvString ;
#            mydata:ontology    ?ontologyString ;
#            mydata:ontology_count   ?ontology_countString ;
#            mydata:qchars   ?qcharsString ;
#            mydata:qgram   ?qgramString ;
#            mydata:qwords   ?qwordsString ;
#            mydata:rank   ?rankString ;
#            mydata:rf_predicted_proximity   ?rf_predicted_proximityString ;
#            mydata:rxnMatchMeth   ?rxnMatchMethString ;
#            # mydata:rxnifavailable   ?rxnifavailableString ;
#            mydata:score   ?scoreString ;
#            mydata:solr_rxnorm   ?solr_rxnormString ;
#            mydata:solrsubmission   ?solrsubmissionString ;
#            mydata:term   ?termString ;
#            mydata:term_count   ?term_countString ;
#            mydata:max_useful_prob_by_row ?max_useful_prob_by_rowString ;
#            mydata:max_useful_prob_by_med ?max_useful_prob_by_medString ;
#            mydata:relative_prob ?relative_probString ;
#            mydata:boosted ?boostedString ;
#            mydata:max_boosted ?max_boostedString ;
#            mydata:relative_boosted  ?relative_boostedString ;
#            optional {
#             ?s mydata:rxnifavailable  ?rxnifavailableString ;
#                bind(uri(?rxnifavailableString) as ?rxnifavailable)
#         }
#     }
#     bind(xsd:integer(?lcsString) as ?lcs)
#     bind(xsd:integer(?lvString) as ?lv)
#     bind(xsd:integer(?hcharsString) as ?hchars)
#     bind(xsd:integer(?hwordsString) as ?hwords)
#     bind(xsd:integer(?ontology_countString) as ?ontology_count)
#     bind(xsd:integer(?qcharsString) as ?qchars)
#     bind(xsd:integer(?qgramString) as ?qgram)
#     bind(xsd:integer(?qwordsString) as ?qwords)
#     bind(xsd:integer(?rankString) as ?rank)
#     bind(xsd:integer(?term_countString) as ?term_count)
#     bind(xsd:float(?FALSE_FALSE_FALSE_FALSEString) as ?FALSE_FALSE_FALSE_FALSE)
#     bind(xsd:float(?FALSE_FALSE_FALSE_TRUEString) as ?FALSE_FALSE_FALSE_TRUE)
#     bind(xsd:float(?FALSE_FALSE_TRUE_FALSEString) as ?FALSE_FALSE_TRUE_FALSE)
#     bind(xsd:float(?FALSE_FALSE_TRUE_TRUEString) as ?FALSE_FALSE_TRUE_TRUE)
#     bind(xsd:float(?FALSE_TRUE_FALSE_FALSEString) as ?FALSE_TRUE_FALSE_FALSE)
#     bind(xsd:float(?FALSE_TRUE_TRUE_FALSEString) as ?FALSE_TRUE_TRUE_FALSE)
#     bind(xsd:float(?jaccardString) as ?jaccard)
#     bind(xsd:float(?jwString) as ?jw)
#     bind(xsd:float(?scoreString) as ?score)
#     bind(xsd:float(?TRUE_FALSE_FALSE_FALSEString) as ?TRUE_FALSE_FALSE_FALSE)
#     bind(xsd:float(?TRUE_TRUE_FALSE_FALSEString) as ?TRUE_TRUE_FALSE_FALSE)
#     bind(xsd:float(?max_useful_prob_by_rowString) as ?max_useful_prob_by_row)
#     bind(xsd:float(?max_useful_prob_by_medString) as ?max_useful_prob_by_med)
#     bind(xsd:float(?relative_probString) as ?relative_prob)
#     bind(xsd:float(?boostedString) as ?boosted)
#     bind(xsd:float(?max_boostedString) as ?max_boosted )
#     bind(xsd:float(?relative_boostedString) as ?relative_boosted)
#     bind(uuid() as ?uuid)
#     bind(uri(?R_MEDICATION_URIString) as ?R_MEDICATION_URI)
#     bind(uri(?labelTypeString) as ?labelType)
#     bind(uri(?ontologyString) as ?ontology)
#     bind(uri(?termString) as ?solrMatchTerm)
#     bind(uri(concat("http://example.com/resource/", ?rf_predicted_proximityString)) as ?rf_predicted_proximity)
#     bind(uri(concat("http://example.com/resource/", ENCODE_FOR_URI(?rxnMatchMethString))) as ?rxnMatchMeth)
#     bind(if(?solr_rxnormString="0", false, true) as ?solr_rxnorm)
#     bind(if(?altLabelString="0", false, true) as ?altLabel)
#     bind(if(?T200String="0", false, true) as ?T200)
# }
#   ',
"inherts from highest rxn" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
insert {
    graph mydata:rmed_inherits_from_highest_conf_rxn_boosted {
        ?R_MEDICATION mydata:inherits_from ?rxn .
    }
}
where {
    graph <http://example.com/resource/rf_predictions_boosted_ordercounts_no_ffff_201904251619> {
        ?boosted_prox mydata:R_MEDICATION_URI ?R_MEDICATION ;
                      mydata:relative_boosted "1"^^xsd:float;
                                                   mydata:rxnifavailable ?rxn
    }
}
',
"iteration 1" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_1 {
        ?R_MEDICATION mydata:inherits_from ?donor
    }
}
where {
    values ?p {
        rxnorm:consists_of
        rxnorm:contains
        rxnorm:has_ingredient
        rxnorm:has_ingredients
        rxnorm:has_part
        rxnorm:has_precise_ingredient
        rxnorm:isa
        rxnorm:tradename_of
        rxnorm:form_of
    }
    graph mydata:rmed_inherits_from_highest_conf_rxn_boosted {
        ?R_MEDICATION mydata:inherits_from ?rxn .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn ?p ?donor .
    }
}
',
"iteration 2" = '
PREFIX mydata: <http://example.com/resource/>
  PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX obo: <http://purl.obolibrary.org/obo/>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_2 {
    ?R_MEDICATION mydata:inherits_from ?donor
  }
}
where {
  values ?p {
    rxnorm:consists_of
    rxnorm:contains
    rxnorm:has_ingredient
    rxnorm:has_ingredients
    rxnorm:has_part
    rxnorm:has_precise_ingredient
    rxnorm:isa
    rxnorm:tradename_of
    rxnorm:form_of
  }
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_1 {
    ?R_MEDICATION mydata:inherits_from ?rxn .
  }
  graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
    ?rxn ?p ?donor .
  }
}
',
"iteration 3" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_3 {
        ?R_MEDICATION mydata:inherits_from ?donor
    }
}
where {
    values ?p {
        rxnorm:consists_of
        rxnorm:contains
        rxnorm:has_ingredient
        rxnorm:has_ingredients
        rxnorm:has_part
        rxnorm:has_precise_ingredient
        rxnorm:isa
        rxnorm:tradename_of
        rxnorm:form_of
    }
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_2 {
        ?R_MEDICATION mydata:inherits_from ?rxn .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn ?p ?donor .
    }
}
',
"iteration 4" = '
PREFIX mydata: <http://example.com/resource/>
  PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX obo: <http://purl.obolibrary.org/obo/>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_4 {
    ?R_MEDICATION mydata:inherits_from ?donor
  }
}
where {
  values ?p {
    rxnorm:consists_of
    rxnorm:contains
    rxnorm:has_ingredient
    rxnorm:has_ingredients
    rxnorm:has_part
    rxnorm:has_precise_ingredient
    rxnorm:isa
    rxnorm:tradename_of
    rxnorm:form_of
  }
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_3 {
    ?R_MEDICATION mydata:inherits_from ?rxn .
  }
  graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
    ?rxn ?p ?donor .
  }
}
',
"iteration 5" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_5 {
        ?R_MEDICATION mydata:inherits_from ?donor
    }
}
where {
    values ?p {
        rxnorm:consists_of
        rxnorm:contains
        rxnorm:has_ingredient
        rxnorm:has_ingredients
        rxnorm:has_part
        rxnorm:has_precise_ingredient
        rxnorm:isa
        rxnorm:tradename_of
        rxnorm:form_of
    }
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_4 {
        ?R_MEDICATION mydata:inherits_from ?rxn .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn ?p ?donor .
    }
}
',
"iteration 6" = '
PREFIX mydata: <http://example.com/resource/>
  PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
  PREFIX obo: <http://purl.obolibrary.org/obo/>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_6 {
    ?R_MEDICATION mydata:inherits_from ?donor
  }
}
where {
  values ?p {
    rxnorm:consists_of
    rxnorm:contains
    rxnorm:has_ingredient
    rxnorm:has_ingredients
    rxnorm:has_part
    rxnorm:has_precise_ingredient
    rxnorm:isa
    rxnorm:tradename_of
    rxnorm:form_of
  }
  graph mydata:rmed_inherits_rxn_whitelisteds_boosted_5 {
    ?R_MEDICATION mydata:inherits_from ?rxn .
  }
  graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
    ?rxn ?p ?donor .
  }
}
',
"iteration 7" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
insert {
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_7 {
        ?R_MEDICATION mydata:inherits_from ?donor
    }
}
where {
    values ?p {
        rxnorm:consists_of
        rxnorm:contains
        rxnorm:has_ingredient
        rxnorm:has_ingredients
        rxnorm:has_part
        rxnorm:has_precise_ingredient
        rxnorm:isa
        rxnorm:tradename_of
        rxnorm:form_of
    }
    graph mydata:rmed_inherits_rxn_whitelisteds_boosted_6 {
        ?R_MEDICATION mydata:inherits_from ?rxn .
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn ?p ?donor .
    }
}
',
"aggregate iterations" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX rxnorm: <http://purl.bioontology.org/ontology/RXNORM/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
insert {
    graph mydata:rmed_inherits_from_chebicomp_boosted {
        ?R_MEDICATION mydata:inherits_from ?chebi
    }
}
where {
    graph mydata:mdm_ods_meds_20180403_unique_cols.csv {
        ?R_MEDICATION rdf:type mydata:Row .
    }
    {
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_6 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_5 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_4 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_3 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_2 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_rxn_whitelisteds_boosted_1 {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
        union
        {
            graph mydata:rmed_inherits_from_highest_conf_rxn_boosted {
                ?R_MEDICATION mydata:inherits_from ?rxn .
            }
        }
    }
    graph <https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/RXNORM/> {
        ?rxn rdf:type owl:Class	 .
    }
    graph <http://bioportal.bioontology.org/mappings> {
        ?map rdf:type mydata:Row ;
             mydata:sourceTerm|mydata:mapTerm ?rxn ;
                              mydata:sourceTerm|mydata:mapTerm ?chebi .
    }
    graph <ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz> {
        ?chebi rdf:type owl:Class	 .
    }
}
',
"chebi solr hit" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
insert {
    graph mydata:rmed_inherits_from_chebicomp_boosted {
        ?R_MEDICATION mydata:inherits_from ?chebi .
    }
}
where {
    graph <http://example.com/resource/rf_predictions_boosted_ordercounts_no_ffff_201904251619>> {
        ?boosted_prox mydata:R_MEDICATION_URI ?R_MEDICATION ;
                      mydata:relative_boosted "1"^^xsd:float;
                                                   mydata:solrMatchTerm ?chebi
    }
    graph <ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz> {
        ?chebi a owl:Class
    }
}
',
"dron mapping" = '
PREFIX mydata: <http://example.com/resource/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
insert {
    graph mydata:rmed_inherits_from_chebicomp_boosted {
        ?R_MEDICATION mydata:inherits_from ?dron_chebi_term .
    }
}
where {
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_6 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_5 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_4 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_3 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_2 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph mydata:rmed_inherits_rxn_whitelisteds_boosted_1 {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    union
    {
        graph  mydata:rmed_inherits_from_highest_conf_rxn_boosted  {
            ?R_MEDICATION mydata:inherits_from ?rxn .
        }
    }
    bind(replace(str(?rxn), "http://purl.bioontology.org/ontology/RXNORM/", "") as ?rxnval)
    {
        {
            graph <http://purl.obolibrary.org/obo/dron/dron-ingredient.owl> {
                ?dron_chebi_term obo:DRON_00010000 ?rxnval
            }
        }
        union {
            graph <http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl> {
                ?dron_chebi_term obo:DRON_00010000 ?rxnval
            }
        }
    }
    graph <ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz> {
        ?dron_chebi_term a owl:Class
    }
}
',
"inherit classes and roles, must ahve already been materialized" = '
PREFIX mydata: <http://example.com/resource/>
insert {
    graph mydata:rmed_inherits_from_chebi_class_and_role_boosted {
        ?R_MEDICATION  mydata:inherits_from  ?donor
    }
}
where {
    graph mydata:rmed_inherits_from_chebicomp_boosted	{
        ?R_MEDICATION mydata:inherits_from ?child_class.
    }
    graph mydata:materialized_class_and_role {
        ?child_class mydata:inherits_from  ?donor
    }
}
'
)

placeholder <-
  lapply(names(query.list), function(current.update) {
    print(current.update)
    print(Sys.time())
    current.statement <- query.list[[current.update]]
    # cat(current.statement)
    insert.result <-
      POST(update.endpoint, body = list(update = current.statement))
    
    print(insert.result$status_code)
    print(insert.result$times)
    
  })
0.0

