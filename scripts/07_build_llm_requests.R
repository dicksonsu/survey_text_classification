# Development smoke test only. Never include gold labels in model requests.
# Run from repository root.
stopifnot(file.exists("R/llm_prompt.R"))
source("R/llm_prompt.R")
stopifnot(file.exists("data/reference/reference_coding_workbook.csv"))

ref <- readr::read_csv("data/reference/reference_coding_workbook.csv", show_col_types = FALSE)
needed <- c("RESPID", "mention_number", "Q22", "Q22_original")
stopifnot(all(needed %in% names(ref)))
stopifnot(!anyDuplicated(ref[c("RESPID", "mention_number")]))

# Use all 114 researcher-reviewed development mentions.
examples <- ref[, needed]

# Verify the expected number of mentions.
stopifnot(nrow(examples) == 114L)
requests <- examples |>
  dplyr::mutate(
    system_prompt = llm_system_prompt(),
    user_prompt = vapply(seq_len(nrow(examples)), function(i) {
      llm_user_prompt(examples$Q22[i], examples$Q22_original[i])
    }, character(1))
  )

dir.create("output/llm_classification", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(
  requests,
  "output/llm_classification/dev_requests_114.csv"
)

cat(
  "Created", nrow(requests),
  "synthetic DEVELOPMENT prompt requests. No API call was made.\n"
)
