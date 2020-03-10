> 53 variables:

Each row corresponds to one RxNav aprroximate search results. Up to two different strings can be submitted for each `R_MEDICATION`: a normaized version of the `FULL_NAME` and a lowercased version of the `GENERIC_NAME`., **and** up to 50 results can be returned for each API call.

> - query.val: the string (from PDS R_MEDICATION) that was actually submitted to the RxNav approximate search API. (normaized  `FULL_NAME` or lowercased  `GENERIC_NAME`) See also `xxx`
> - STR.lc: lowercased version of the string hit by the RxNav approximate search API.
> - normalized: `FULL_NAME`s in which source-specific language has been either scrubbed or replaced with RxNorm language witht eh same meaning ("po tabs" -> "oral tablet")
> - FK_MEDICATION_ID: actually the **PK** of a `R_MEDICATION` (but accessed via a join from `ORDER_MED`)
> - FULL_NAME: raw value from `R_MEDICATION`
> - GENERIC_NAME:  raw value from `R_MEDICATION`
> - RXNORM:  raw value from `R_MEDICATION`. These are often _wrong_, in the sense that they don't represent all of the knowledge in teh `FULL_NAME`. The way in which infomration is lost or altered is inconsistent.
> - EMPI_COUNT: proxy for the number of patients who received an order for this `R_MEDICATION`. Assuming one unique and singular `EMPI` per patient.
> - pds.rxn.annotated: is `R_MEDICATION.RXNORM` non-NULL/non-empty/non-zero
> - GENERIC_NAME.lc: lowercased `GENERIC_NAME` with no other normalization
> - rxaui: RXAUI for strings returned by the RxNav approximate search API. More granular than the rxcui from the same API, due to teh fact that RxNorm models knowledge from each upstream provider as atoms and then aggregates to RXCUIs with teh same meaning.
> - rxcui: RXCUI  for strings returned by the RxNav approximate search API. See also rxaui.
> - score: semi-opaque assesment of the quality of an RxNav approximate search result. 0 to 100.
> - rank: 1 for the RxNav approximate search result with the highest score, which may not necessarily be 100.
> - rxcui.count: numnber of RxNav approximate search results, across all inputs, with a given RXCUI.
> - rxcui.freq: rxcui.count/(sum(rxcui.count))
> - rxaui.count: numnber of RxNav approximate search results, across all inputs, with a given RXAUI.
> - rxaui.freq: rxaui.count/(sum(rxaui.count))
> - SAB.sr: what upstream source did the RxNav approximate search result come from?
> - SUPPRESS: RxNorm internal. Ignored at this point.
> - TTY.sr: what is the type of the RxNav approximate search result? Ingredient, brand name, multi-pack, etc?
> - STR: raw string hit by the RxNav approximate search API.
> - query.source: indicates whether a normalized R_MEDICATION FULL_NAME or a lowercased GENERIC_NAME was submitted to the RxNav approximate search API
> - lv: Levenstein string distance between submitted string and string attributed to a RxNav approximate search result.
> - lcs
> - qgram: qgram string distance (size currently unknown)
> - cosine: cosine distance... how similar are the vectors of qgrams between the submitted and matched strings?
> - jaccard: jaccard distance between submitted and matched strings? Qgrams?
> - jw
> - q.char: character length of `query.val`
> - q.words: number of words-like tokens in `query.val`, using count of space characters as a proxy. Quereis have alrady been scrubbed of leading and training space as well as duplicate spaces and whitespace characters other than XXX
> - sr.char: character length of `STR`
> - sr.words: word count for `STR`
> - rf_responses: prediction from the rnadom forest. Either the name of the RxNorm relation that links   a RxNav approximate search result's RXCUI to the RXCUI that could best explain a `R_MEDICATION` 
> - consists_of: probablilty that the relation between the `R_MEDICATION`'s most repressentatitve RXCUI and a RxNav approximate search result's RXCUI is `consists_of`
> - constitutes
> - contained_in
> - contains
> - form_of
> - has_form
> - has_ingredient
> - has_part
> - has_quantified_form
> - has_tradename
> - identical: probability that a `R_MEDICATION`'s most repressentatitve RXCUI and a RxNav approximate search result's RXCUI are identical... and exact match with no loss or addition of knowledge
> - ingredient_of
> - inverse_isa
> - isa
> - more distant: probability that there is more than one semantic hop between a `R_MEDICATION`'s most repressentatitve RXCUI and a RxNav approximate search result's RXCUI. From TMM's perspective, the search result is wrong.
> - part_of
> - quantified_form_of
> - tradename_of
> - override: whenever the RxNav approximate search result's `score` is 100, this is set to `identical`, regradless of `rf_responses`. Likewise, it is set to `more distant` when the score is 0. Otherwise, `override` is `rf_responses`
>