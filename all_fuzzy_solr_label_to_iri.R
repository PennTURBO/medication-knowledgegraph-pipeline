args = commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop(
    "There should be exactly on command line argument: a medication term (ing., class, role, prod., etc.)",
    call. = FALSE
  )
} else {
  user.input <- args[1]
  print(paste0("Searching for IRIs like: ", user.input))
}

source("rxnav_med_mapping_setup.R",
       echo = FALSE,
       print.eval = FALSE)

#### prerequisities
# $ ~/solr-8.4.1/bin/solr start
# *** [WARN] *** Your open file limit is currently 2560.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# *** [WARN] ***  Your Max Processes Limit is currently 5568.
# It should be set to 65000 to avoid operational disruption.
# If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
# Waiting up to 180 seconds to see Solr running on port 8983 [-]
# Started Solr server on port 8983 (pid=33449). Happy searching!
#
# $ ~/solr-8.4.1/bin/solr create_core -c <config$med.map.kb.solr.host>

# and it should ahve been populated with soemthign like sparql_mm_kb_labels_to_solr.R

# create Solr client object
mm.kb.solr.client <-
  SolrClient$new(
    host = config$med.map.kb.solr.host,
    path = "search",
    port = config$med.map.kb.solr.port
  )

# could also ping it
print(mm.kb.solr.client)

# sample of taking user input, splitting on spaces, adding the ~ fuzzy operator, and wrapping in parens
# for bag-of-words search

# user.input <-
#   readline(prompt = "Enter a medication ingredient, product, class or role: ")

fuzzied <- unlist(strsplit(user.input, " "))
fuzzied <-
  paste0('medlabel:(',
         paste(fuzzied, "~", sep = "", collapse =  " "),
         ')')
my.solr.result <-
  mm.kb.solr.client$search(
    name = config$med.map.kb.solr.core,
    params = list(
      q = fuzzied,
      rows = 33,
      fl = c('mediri', 'labelpred', 'medlabel', 'score')
    )
  )

options(width = 160)

print(paste0("Actually searched for ",fuzzied))

print(as.data.frame(my.solr.result))

