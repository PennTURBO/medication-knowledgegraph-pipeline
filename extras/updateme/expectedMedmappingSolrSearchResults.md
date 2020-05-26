Search Term: aspirin\
Expected top result(s):\
http://purl.obolibrary.org/obo/CHEBI_15365 Label: aspirin\
http://purl.bioontology.org/ontology/RXNORM/1191 Label: aspirin

Search Term: terbinafine\
Expected top result(s):\
http://purl.obolibrary.org/obo/CHEBI_9448 Label: terbinafine\
http://purl.bioontology.org/ontology/RXNORM/37801 Label: terbinafine

Search Term: anti-inflammatory\
Expected top result(s):\
http://purl.obolibrary.org/obo/CHEBI_35472 Label: anti-inflammatory

Search Term: analgesic\
Expected top result(s):\
http://purl.obolibrary.org/obo/CHEBI_35480 Label: analgesic

Search Term: meperidine\
Expected top result(s):\
http://purl.bioontology.org/ontology/RXNORM/6754 Label: meperidine

Search Term: pethidine\
Expected top result(s):\
http://purl.bioontology.org/ontology/RXNORM/6754 Label: meperidine


----

# 2020-05-26

_For ingredients searches, we expect a top-ranked, perfect hit from RxNorm and ChEBI, or DrOn instead of ChEBI in a minority of cases. It shouldn't require constraining the employment. See examples of that below._

## Active Ingredients

### Aspirin

`http://<solrhost:solrport>/solr/med_mapping_kb_labels_exp/select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=aspirin`

for the rest of this document,only the portion after the core name will be shown, ie

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=aspirin`

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

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=acetaminophen`

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

That gets correct search results even though ChEBI's preferred label for this entity is "paracetamol". (The Solr core was created I a way that prioritizes DrOn labels on ChEBI labels on ChEBI terms

Note that ChEBI provides the brand name "tylenol" for this molecule. That mean users searching for "tylenol" (and several other common brands) will get BN hits from RxNorm, but can also be redirected to active_ingredient hits with a query like this:

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=30&qf=medlabel%20tokens%20employment&q=(tylenol%20active_ingredient)`

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

That doesn’t return CHEBI:6754 because DrOn uses its own term in "has active ingredient axioms" instead (informally speaking). In other words, CHEBI:6754 does not have an active_ingredient employment in TMM.

On a related note, ChEBI uses the preferred label "pethidine" for CHEBI:6754. Due to the design described above, "pethidine" won't return CHEBI:6754 either.  

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=pethidine`

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

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=terbinafine`

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

Like the meperidine search, that doesn’t return a ChEBI hit because DrOn doesn't mention it as an ingredient. However, it does return a DrOn native ingredient in addition to the RxNorm term.

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

## Curated Roles

### Anti-inflammatory

_As Hayden showed, it would be nice if CHEBI:35472 came to the top._

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=anti-inflammatory`

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

`select?defType=edismax&fl=id,medlabel,employment,definedin,tokens,score&rows=3&qf=medlabel%20tokens&q=(anti-inflammatory+drug)`

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

