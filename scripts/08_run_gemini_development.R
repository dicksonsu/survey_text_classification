# Gemini development smoke test for synthetic survey text.
# Run from the repository root. Does NOT evaluate the holdout.
# One request by default; call run_gemini_development(n = 10) after inspection.

source("R/llm_output_validation.R")

run_gemini_development <- function(n = 1L, model = "gemini-3.5-flash-lite",
                                   pause_seconds = 13) {
  if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("readr", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Install these packages first: httr2, readr, jsonlite")
  }
  key <- Sys.getenv("GEMINI_API_KEY")
  if (!nzchar(key)) stop("GEMINI_API_KEY not found. Set it in ~/.Renviron and restart RStudio.")

  input_path <- "output/llm_classification/dev_requests_114.csv"
  output_path <- "output/llm_classification/gemini_dev_responses.csv"
  if (!file.exists(input_path)) stop("Missing dev_requests_10.csv; rerun script 07.")
  requests <- readr::read_csv(input_path, show_col_types = FALSE)
  needed <- c("RESPID", "mention_number", "Q22", "system_prompt", "user_prompt")
  if (!all(needed %in% names(requests))) stop("Unexpected request CSV columns")
  if (n < 1L || n > nrow(requests)) {
    stop(
      "Requested ", n, " mentions, but the input file contains ",
      nrow(requests), " rows.\n",
      "Input file: ", normalizePath(input_path)
    )
  }

  # Resume safely; avoid overwriting completed responses on rerun.
  existing <- if (file.exists(output_path))
    readr::read_csv(output_path, show_col_types = FALSE) else NULL
  if (!is.null(existing) && !all(c("RESPID", "mention_number", "model", "json_text", "validation_ok") %in% names(existing))) {
    stop("Existing response CSV has unexpected columns; inspect before continuing.")
  }
  out <- if (is.null(existing)) data.frame() else as.data.frame(existing)

  for (i in seq_len(n)) {
    row <- requests[i, ]
    if (nrow(out) > 0 && any(out$RESPID == row$RESPID &
                            out$mention_number == row$mention_number &
                            out$model == model & out$validation_ok %in% TRUE,
                            na.rm = TRUE)) {
      message("Skipping previously validated row ", i)
      next
    }

    body <- list(
      systemInstruction = list(parts = list(list(text = row$system_prompt))),
      contents = list(list(role = "user", parts = list(list(text = row$user_prompt)))),
      generationConfig = list(
        responseMimeType = "application/json",
        temperature = 0,
        maxOutputTokens = 500
      )
    )
    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/",
                  model, ":generateContent")
    result <- tryCatch({
      response <- httr2::request(url) |>
        httr2::req_method("POST") |>
        httr2::req_headers(`x-goog-api-key` = key) |>
        httr2::req_body_json(body, auto_unbox = TRUE) |>
        httr2::req_timeout(75) |>
        httr2::req_perform()
      obj <- httr2::resp_body_json(response, simplifyVector = FALSE)
      parts <- obj$candidates[[1]]$content$parts
      json_text <- paste(vapply(parts, function(p) if (is.null(p$text)) "" else p$text, character(1)), collapse = "")
      if (!nzchar(json_text)) stop("Empty model response")
      validation <- validate_llm_json(json_text)
      list(text = json_text, ok = validation$ok, reason = if (validation$ok) "" else validation$reason,
           prompt_tokens = obj$usageMetadata$promptTokenCount %||% NA_integer_,
           output_tokens = obj$usageMetadata$candidatesTokenCount %||% NA_integer_)
    }, error = function(e) {
      
      # Show the actual error without exposing the API key
      error_message <- conditionMessage(e)
      
      error_message <- gsub(
        key, "[REDACTED]",
        error_message, fixed = TRUE
      )
      
      message("Gemini error: ", error_message)
      
      list(
        text = "",
        ok = FALSE,
        reason = "request_failed",
        prompt_tokens = NA_integer_,
        output_tokens = NA_integer_
      )
    })
    if (!result$ok) message("Row ", i, " failed validation/request: ", result$reason)
    new <- data.frame(
      RESPID = as.character(row$RESPID), mention_number = as.integer(row$mention_number),
      Q22 = as.character(row$Q22), model = model,
      json_text = result$text, validation_ok = result$ok, validation_reason = result$reason,
      prompt_tokens = result$prompt_tokens, output_tokens = result$output_tokens,
      run_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), stringsAsFactors = FALSE
    )
    out <- rbind(out, new)
    readr::write_csv(out, output_path)
    message("Saved row ", i, "/", n, " | valid=", result$ok)
    if (i < n) Sys.sleep(pause_seconds)
  }
  invisible(out)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# First call: only one synthetic development example.
# run_gemini_development(n = 1L)
