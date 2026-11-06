# Run from repository root after sourcing the proposed v2 helpers.
source("R/classification_helpers.R")
source("R/entity_standardization.R")
stopifnot(identical(
  classify_q22(c("npr", "veritasium", "jre", "fresh & fit", "the pat mcafee show")),
  rep("named_source", 5)
))
stopifnot(identical(
  classify_q22(c("nba", "nfl", "nba highlights", "a few finance people", "some people on twitch", "a few on social media", "some basketball players")),
  rep("platform_or_topic", 7)
))
stopifnot(identical(classify_q22(c("myself", "good")), c("junk", "junk")))
stopifnot(identical(classify_q22("a creator called alex"), "entity"))
stopifnot(identical(classify_q22(c("joe rogan", "espn", "lebron james")), c("entity", "named_source", "entity")))
aliases <- readr::read_csv("data/entity_aliases.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(aliases$mention))
stopifnot(aliases$entity_clean[aliases$mention == "jre"] == "The Joe Rogan Experience")
stopifnot(aliases$entity_clean[aliases$mention == "the pat mcafee show"] == "The Pat McAfee Show")
sample <- data.frame(RESPID="SYN9999", Q22="alex", response_type="entity")
resolved <- standardize_entities(sample, aliases)
stopifnot(is.na(resolved$entity_clean), resolved$standardization_status == "unmapped_candidate")
message("PASS: targeted v2 regressions")
