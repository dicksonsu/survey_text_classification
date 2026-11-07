# Parse only successful prompt-v2 JSON replies; keep full request history separately.
parse_gemini_v2 <- function(dataset=c('development','holdout')) {
  dataset <- match.arg(dataset)
  if (!requireNamespace('readr',quietly=TRUE) || !requireNamespace('jsonlite',quietly=TRUE))
    stop('Install readr and jsonlite')
  path <- if (dataset=='development') 'output/llm_classification/gemini_dev_v2_history.csv' else
    'output/llm_classification/gemini_holdout_v2_history.csv'
  target <- if (dataset=='development') 'output/llm_classification/gemini_dev_v2_parsed.csv' else
    'output/llm_classification/gemini_holdout_v2_parsed.csv'
  expected <- if (dataset=='development') 114L else 105L
  if (!file.exists(path)) stop('Missing history: ',path)
  d <- readr::read_csv(path,show_col_types=FALSE)
  d <- d[!is.na(d$validation_ok) & d$validation_ok & d$model=='gemini-3.5-flash-lite' &
         d$prompt_version=='gemini_prompt_v2_2026-11-07',,drop=FALSE]
  d <- d[!duplicated(d[c('RESPID','mention_number')],fromLast=TRUE),,drop=FALSE]
  if(nrow(d)==0L) stop('No successful v2 responses found')
  fields <- c('response_type','entity_clean','resolution_status','nonresponse_subtype','review_flag','review_reason')
  j <- lapply(d$json_text,function(s) jsonlite::fromJSON(s,simplifyVector=TRUE))
  to_chr <- function(x) if (is.null(x) || length(x)==0L) NA_character_ else as.character(x)
  for (f in fields) {
    if (f=='review_flag') d[[f]] <- vapply(j,function(x) isTRUE(x[[f]]),logical(1))
    else d[[f]] <- vapply(j,function(x) to_chr(x[[f]]),character(1))
  }
  readr::write_csv(d,target,na='')
  cat('Saved ',nrow(d),' unique valid ',dataset,' v2 responses; expected ',expected,'\n',sep='')
  if(nrow(d)!=expected) warning('Incomplete predictions; do not evaluate until all are present')
  invisible(d)
}
