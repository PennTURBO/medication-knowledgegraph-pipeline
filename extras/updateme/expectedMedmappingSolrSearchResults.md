### Search Term: aspirin
- Expected top result(s):
    - http://purl.obolibrary.org/obo/CHEBI_15365 Label: aspirin
    - http://purl.bioontology.org/ontology/RXNORM/1191 Label: aspirin

### Search Term: terbinafine
- Expected top result(s):
    - http://purl.obolibrary.org/obo/CHEBI_9448 Label: terbinafine
    - http://purl.bioontology.org/ontology/RXNORM/37801 Label: terbinafine

### Search Term: anti-inflammatory
- Expected top result(s):
    - http://purl.obolibrary.org/obo/CHEBI_35472 Label: anti-inflammatory

### Search Term: analgesic
- Expected top result(s):
    - http://purl.obolibrary.org/obo/CHEBI_35480 Label: analgesic

### Search Term: meperidine
- Expected top result(s):
    - http://purl.bioontology.org/ontology/RXNORM/6754 Label: meperidine

### Search Term: pethidine
- Expected top result(s):
    - http://purl.bioontology.org/ontology/RXNORM/6754 Label: meperidine

----

# 2020-05-26

_For ingredients searches, we expect a top-ranked, perfect hit from RxNorm and ChEBI (or DrOn instead of ChEBI in a minority of cases.) It shouldn't require constraining the employment. See examples of that below._

## Active Ingredients (DrOn or ChEBI `active_ingredient`, RxNorm `IN`)

### Aspirin

`http://<solrhost:solrport>/solr/med_mapping_kb_labels_exp/select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=aspirin`

for the rest of this document, only the portion of the URL to the right of the Solr core name will be shown, i.e.

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=aspirin`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"aspirin",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":1370,"start":0,"maxScore":7.630991,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1191",
        "medlabel":["aspirin"],
        "tokens":["aspirin"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":7.630991},
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_15365",
        "medlabel":["aspirin"],
        "tokens":["2-acetoxybenzenecarboxylic",
          "acetylsalicylate",
          "acetylsalicylic",
          "acid",
          "aspirin",
          "easprin"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["active_ingredient"],
        "score":7.627565},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/368457",
        "medlabel":["aspirin oral tablet [bayer aspirin]"],
        "tokens":["[bayer",
          "aspirin",
          "aspirin]",
          "oral",
          "tablet"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDF"],
        "score":7.3570666}]
  }}
```

### acetaminophen

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=acetaminophen`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":1,
    "params":{
      "q":"acetaminophen",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":4164,"start":0,"maxScore":5.9278255,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/161",
        "medlabel":["acetaminophen"],
        "tokens":["acetaminophen"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":5.9278255},
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_46195",
        "medlabel":["acetaminophen"],
        "tokens":["4-acetamidophenol",
          "acetaminophen",
          "apap",
          "panadol",
          "paracetamol",
          "tylenol"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["active_ingredient"],
        "score":5.9236603},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1006970",
        "medlabel":["acetaminophen / dimenhydrinate"],
        "tokens":["/",
          "acetaminophen",
          "dimenhydrinate"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["MIN"],
        "score":5.416124}]
  }}
```

That gets correct search results even though ChEBI's preferred label for this entity is "paracetamol". (The Solr core was created in a way that prioritizes DrOn labels on ChEBI labels over ChEBI terms.)

Note that ChEBI also provides the brand name "tylenol" for this molecule. That means users searching for "tylenol" (and several other common brands) will get `BN` hits from RxNorm, but can also be redirected to `active_ingredient` hits with the query below. We'll have to decide whether it's appropriate to broaden the scope from a brand to any product that contains the active ingredient that is most closely associated with the submitted brand.

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=30&qf=medlabel+tokens+employment&q=(tylenol+active_ingredient)`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"(tylenol active_ingredient",
      "defType":"edismax",
      "qf":"medlabel tokens employment",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":5023,"start":0,"maxScore":10.996134,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/202433",
        "medlabel":["tylenol"],
        "tokens":["tylenol"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["BN"],
        "score":10.996134},
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_46195",
        "medlabel":["acetaminophen"],
        "tokens":["4-acetamidophenol",
          "acetaminophen",
          "apap",
          "panadol",
          "paracetamol",
          "tylenol"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["active_ingredient"],
        "score":10.722801},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1187315",
        "medlabel":["tylenol pill"],
        "tokens":["pill",
          "tylenol"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDG"],
        "score":10.039544}]
  }}
```

### meperidine

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=meperidine`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"meperidine",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":156,"start":0,"maxScore":10.956157,"docs":[
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00016917",
        "medlabel":["meperidine"],
        "tokens":["meperidine"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-ingredient.owl"],
        "employment":["active_ingredient"],
        "score":10.956157},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/6754",
        "medlabel":["meperidine"],
        "tokens":["meperidine",
          "pethidine"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":10.946421},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/103755",
        "medlabel":["meperidine hydrochloride"],
        "tokens":["hydrochloride",
          "meperidine"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["PIN"],
        "score":10.0104}]
  }}
```

That doesn’t return CHEBI:6754 because DrOn uses its own meperidine term in "has active ingredient" axioms (informally speaking). In other words, CHEBI:6754 does not hold the `active_ingredient` employment in TMM.

On a related note, ChEBI asserts the preferred label "pethidine" for CHEBI:6754. Due to the design patterns mentioned above, "pethidine" won't return CHEBI:6754 either. Those patterns could be loosened, but that would almost certainly add noise to the Solr core, increase its size, increase query times, and generally decrease the usefulness of the matches.

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=pethidine`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"pethidine",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":2,"start":0,"maxScore":15.802455,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/6754",
        "medlabel":["meperidine"],
        "tokens":["meperidine",
          "pethidine"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":15.802455},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/861455",
        "medlabel":["meperidine hydrochloride 100 mg oral tablet"],
        "tokens":["100",
          "hcl",
          "hydrochloride",
          "meperidine",
          "mg",
          "oral",
          "pethidine",
          "tablet"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SCD"],
        "score":10.410517}]
  }}
```

### terbinafine

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=terbinafine`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"terbinafine",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":64,"start":0,"maxScore":12.314482,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/37801",
        "medlabel":["terbinafine"],
        "tokens":["terbinafine"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":12.314482},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00016960",
        "medlabel":["terbinafine"],
        "tokens":["terbinafine"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-ingredient.owl"],
        "employment":["active_ingredient"],
        "score":12.314482},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1161496",
        "medlabel":["terbinafine pill"],
        "tokens":["pill",
          "terbinafine"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SCDG"],
        "score":11.2514715}]
  }}
```

Like the meperidine search, that doesn’t return a ChEBI hit because DrOn doesn't mention ChEBI's meperidine as an ingredient. However, it does return a DrOn native ingredient in addition to the RxNorm term.

The same case is true for...

### rosuvastatin

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"rosuvastatin",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":57,"start":0,"maxScore":12.490527,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/301542",
        "medlabel":["rosuvastatin"],
        "tokens":["rosuvastatin"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["IN"],
        "score":12.490527},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00018679",
        "medlabel":["rosuvastatin"],
        "tokens":["rosuvastatin"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-ingredient.owl"],
        "employment":["active_ingredient"],
        "score":12.490527},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1157992",
        "medlabel":["rosuvastatin pill"],
        "tokens":["pill",
          "rosuvastatin"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SCDG"],
        "score":11.41232}]
  }}
```

## ChEBI clinically relevant structural class

### Statin

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(statin)`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":1,
    "params":{
      "q":"(statin",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":13,"start":0,"maxScore":14.69808,"docs":[
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_87631",
        "medlabel":["statin"],
        "tokens":["statin",
          "statins"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["clinrel_structclass"],
        "score":14.69808},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/215681",
        "medlabel":["bio-statin"],
        "tokens":["bio-statin"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["BN"],
        "score":13.441258},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1174323",
        "medlabel":["bio-statin pill"],
        "tokens":["bio-statin",
          "pill"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDG"],
        "score":12.37318}]
  }}
```

As with most of the `clinrel_structclass`es, 'statin' and 'statins' get the same result



## Curated Roles

### Anti-inflammatory

_As Hayden showed, it would be nice if CHEBI:35472 came to the top._

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=anti-inflammatory`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":38,
    "params":{
      "q":"anti-inflammatory",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":192,"start":0,"maxScore":21.306614,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1043480",
        "medlabel":["surpass anti-inflammatory"],
        "tokens":["anti-inflammatory",
          "surpass"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["BN"],
        "score":21.306614},
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_35472",
        "medlabel":["anti-inflammatory drug"],
        "tokens":["agent",
          "anti-inflammatory",
          "antiinflammatory",
          "drug",
          "drugs"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["curated_role"],
        "score":21.306614},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1184899",
        "medlabel":["surpass anti-inflammatory topical product"],
        "tokens":["anti-inflammatory",
          "product",
          "surpass",
          "topical"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDG"],
        "score":18.366787}]
  }}
```



CHEBI:35472 does come to the top if "drug" is included in the query, or if the query is scoped to roles

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(anti-inflammatory+drug)`

or

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens+employment&q=(anti-inflammatory+curated+drug+role)`

## Analgesic

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(analgesic)`

returns

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"(analgesic",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":20,"start":0,"maxScore":14.300753,"docs":[
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_35480",
        "medlabel":["analgesic"],
        "tokens":["analgesic"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["curated_role"],
        "score":14.300753},
      {
        "id":"http://purl.obolibrary.org/obo/CHEBI_35482",
        "medlabel":["opioid analgesic"],
        "tokens":["analgesic",
          "analgesics",
          "narcotic",
          "narcotics",
          "opioid"],
        "definedin":["http://purl.obolibrary.org/obo/chebi.owl"],
        "employment":["curated_role"],
        "score":13.056684},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/998598",
        "medlabel":["analgesic balm grx"],
        "tokens":["analgesic",
          "balm",
          "grx"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["BN"],
        "score":12.011742}]
  }}
```

## Products (DrOn `product`, RxNorm `SBD`, `SCD`, `SCDF`)

### 500 mg acetaminophen tablet

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(500+mg+acetaminophen+tablet)`

```json
{
  "responseHeader":{
    "status":0,
    "QTime":21,
    "params":{
      "q":"(500 mg acetaminophen tablet",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":120922,"start":0,"maxScore":11.326523,"docs":[
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00073389",
        "medlabel":["acetaminophen 500 mg oral tablet [panex 500]"],
        "tokens":["[panex",
          "500",
          "500]",
          "acetaminophen",
          "mg",
          "oral",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.326523},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00036033",
        "medlabel":["acetaminophen 500 mg oral tablet"],
        "tokens":["500",
          "acetaminophen",
          "mg",
          "oral",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.188951},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00054521",
        "medlabel":["acetaminophen 500 mg disintegrating tablet"],
        "tokens":["500",
          "acetaminophen",
          "disintegrating",
          "mg",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.188951}]
  }}
```

`DRON:00036033` and `RXNORM:198440` are the most relevant results

DRON:00073389, "acetaminophen 500 mg oral tablet [panex 500]" contains a total of 3 occurrences of "500", so it rises to the top.

We are not currently differentiating the type or source of the non-preferred terms. We could retain all of them in separate fields but not query over them, just the current `medlabel` and `tokens` fields.

If the Solr query were applied to `tokens` only and not `medlabel`...

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=tokens&q=(500+mg+acetaminophen+tablet)`

then the optimal results do come to the top

```json
{
  "responseHeader":{
    "status":0,
    "QTime":6,
    "params":{
      "q":"(500 mg acetaminophen tablet",
      "defType":"edismax",
      "qf":"tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":120941,"start":0,"maxScore":11.068883,"docs":[
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00036033",
        "medlabel":["acetaminophen 500 mg oral tablet"],
        "tokens":["500",
          "acetaminophen",
          "mg",
          "oral",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.068883},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00054521",
        "medlabel":["acetaminophen 500 mg disintegrating tablet"],
        "tokens":["500",
          "acetaminophen",
          "disintegrating",
          "mg",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.068883},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00055375",
        "medlabel":["acetaminophen 500 mg chewable tablet"],
        "tokens":["500",
          "acetaminophen",
          "chewable",
          "mg",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":11.068883}]
  }}
```



#### One can imagine that many users would type in "500 mg acetaminophen tablets". 

Submitting that to either `medlabel` alone or `medlabel+tokens` returns the following, which is not helpful. Some modification of the query should be applied before or during the Solr query parsing. Solr has [spell checking](https://lucene.apache.org/solr/guide/7_3/spell-checking.html), the `~` [fuzzy match operator](https://lucene.apache.org/solr/guide/7_3/the-standard-query-parser.html#TheStandardQueryParser-FuzzySearches), a [suggester](https://lucene.apache.org/solr/guide/7_3/suggester.html), an aggressive [Porter stemming filter](https://lucene.apache.org/solr/guide/7_3/about-filters.html), and a [more minimal stemmer](https://lucene.apache.org/core/7_4_0/analyzers-common/org/apache/lucene/analysis/en/EnglishMinimalStemFilterFactory.html). There's also a `synonyms.txt` file in each core or collection's `config` directory. For now, I have put `tablet,tablets` into the synonyms files

`elect?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(500+mg+acetaminophen+tablets)`

without synonyms:

```json
{
  "responseHeader":{
    "status":0,
    "QTime":0,
    "params":{
      "q":"(500 mg acetaminophen tablets",
      "defType":"edismax",
      "qf":"medlabel",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":111727,"start":0,"maxScore":12.029095,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1293403",
        "medlabel":["rescon tablets"],
        "tokens":["rescon",
          "tablets"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["BN"],
        "score":12.029095},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/1293407",
        "medlabel":["rescon tablets pill"],
        "tokens":["pill",
          "rescon",
          "tablets"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDG"],
        "score":11.066392},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/315266",
        "medlabel":["acetaminophen 500 mg"],
        "tokens":["500",
          "acetaminophen",
          "mg"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SCDC"],
        "score":10.834423}]
  }}
```



#### 500 mg tylenol tablet would also be a reasonable query

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel+tokens&q=(500+mg+tylenol+tablets)`

which retrieves good results when searching `medlabel` alone or along with `tokens`. I wouldn't the results perfect because `RXNORM:570070` , without "tablet" comes to the top. If that was passed on to the semantic part of the search, it would also get people who had orders for 500 mg Tylenol **capsules** (or injections, or suppositories, if they are available at 500 mg).

```json
{
  "responseHeader":{
    "status":0,
    "QTime":11,
    "params":{
      "q":"(500 mg tylenol tablets",
      "defType":"edismax",
      "qf":"medlabel tokens",
      "fl":"id,medlabel,employment,definedin,tokens,score",
      "rows":"3"}},
  "response":{"numFound":111116,"start":0,"maxScore":13.984484,"docs":[
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/570070",
        "medlabel":["acetaminophen 500 mg [tylenol]"],
        "tokens":["[tylenol]",
          "500",
          "acetaminophen",
          "mg"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBDC"],
        "score":13.984484},
      {
        "id":"http://purl.bioontology.org/ontology/RXNORM/209459",
        "medlabel":["acetaminophen 500 mg oral tablet [tylenol]"],
        "tokens":["[tylenol]",
          "500",
          "acetaminophen",
          "apap",
          "extra",
          "mg",
          "oral",
          "strength",
          "tablet",
          "tylenol"],
        "definedin":["http://purl.bioontology.org/ontology/RXNORM/"],
        "employment":["SBD"],
        "score":13.351553},
      {
        "id":"http://purl.obolibrary.org/obo/DRON_00073395",
        "medlabel":["acetaminophen 500 mg oral tablet [tylenol]"],
        "tokens":["[tylenol]",
          "500",
          "acetaminophen",
          "mg",
          "oral",
          "tablet"],
        "definedin":["http://purl.obolibrary.org/obo/dron/dron-rxnorm.owl"],
        "employment":["product"],
        "score":12.185806}]
  }}
```



----



see also XXX



`mydata: <http://example.com/resource>`

`rxn_tty: <http://example.com/resource/rxn_tty/>`

`CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>`

`DRON: <http://purl.obolibrary.org/obo/DRON_>`

`RXNORM: <<http://purl.bioontology.org/ontology/RXNORM/>`




