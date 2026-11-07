# Parse all successful Gemini development responses.
# Run from survey-text-classification repository root.
# Does not call an API or modify the raw request history.

library(dplyr)
library(readr)
library(purrr)
library(jsonlite)

input_path <- "output/llm_classification/gemini_dev_responses.csv"
output_path <- "output/llm_classification/gemini_dev_parsed.csv"
model_id <- "gemini-3.5-flash-lite"

history <- read_csv(input_path, show_col_types = FALSE)

successful <- history |>
  filter(validation_ok %in% TRUE, model == model_id) |>
  arrange(desc(run_utc)) |>
  distinct(RESPID, mention_number, .keep_all = TRUE)

# Convert JSON null/missing fields into typed R NA values.
get_character <- function(item, field) {
  value <- item[[field]]
  if (is.null(value) || length(value) == 0L) return(NA_character_)
  as.character(value[[1]])
}
get_logical <- function(item, field) {
  value <- item[[field]]
  if (is.null(value) || length(value) == 0L) return(NA)
  as.logical(value[[1]])
}

parsed <- successful |>
  mutate(parsed_json = map(json_text, jsonlite::fromJSON)) |>
  mutate(
    response_type = map_chr(parsed_json, get_character, "response_type"),
    entity_clean = map_chr(parsed_json, get_character, "entity_clean"),
    resolution_status = map_chr(parsed_json, get_character, "resolution_status"),
    nonresponse_subtype = map_chr(parsed_json, get_character, "nonresponse_subtype"),
    review_flag = map_lgl(parsed_json, get_logical, "review_flag"),
    review_reason = map_chr(parsed_json, get_character, "review_reason")
  ) |>
  select(-parsed_json) |>
  arrange(RESPID, mention_number)

stopifnot(!anyDuplicated(parsed[c("RESPID", "mention_number")]))
write_csv(parsed, output_path, na = "")
cat("Saved", nrow(parsed), "unique valid Gemini classifications to", output_path, "\n")
if (nrow(parsed) != 114L) {
  message("NOTE: Expected 114 development mentions. Still missing: ", 114L - nrow(parsed))
}
