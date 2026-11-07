# Development smoke test only. Never include gold labels in model requests.
# Run from repository root.
stopifnot(file.exists("R/llm_prompt.R"))
source("R/llm_prompt.R")
stopifnot(file.exists("data/reference/reference_coding_workbook.csv"))

ref <- readr::read_csv("data/reference/reference_coding_workbook.csv", show_col_types = FALSE)
needed <- c("RESPID", "mention_number", "Q22", "Q22_original")
stopifnot(all(needed %in% names(ref)))
stopifnot(!anyDuplicated(ref[c("RESPID", "mention_number")]))

# Fixed, simple development smoke-test subset: first 10 rows only.
examples <- utils::head(ref[, needed], 10L)
requests <- examples |>
  dplyr::mutate(
    system_prompt = llm_system_prompt(),
    user_prompt = vapply(seq_len(nrow(examples)), function(i) {
      llm_user_prompt(examples$Q22[i], examples$Q22_original[i])
    }, character(1))
  )

dir.create("output/llm_classification", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(requests, "output/llm_classification/dev_requests_10.csv")
cat("Created 10 synthetic DEVELOPMENT prompt requests. No API call was made.\n")
