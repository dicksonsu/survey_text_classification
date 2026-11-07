# Run Gemini prompt-v2 on a versioned request file; saves EACH attempt immediately.
# Set dataset='development' or 'holdout'; n is first N rows (safe resumable prefix).
source('R/llm_output_validation.R')

run_gemini_v2 <- function(dataset=c('development','holdout'),n=NULL,
                          model='gemini-3.5-flash-lite',pause_seconds=13) {
  dataset <- match.arg(dataset)
  if (!requireNamespace('readr',quietly=TRUE) || !requireNamespace('httr2',quietly=TRUE))
    stop('Install readr and httr2')
  key <- Sys.getenv('GEMINI_API_KEY')
  if (!nzchar(key)) stop('Missing GEMINI_API_KEY (set in ~/.Renviron)')
  inpath <- if (dataset=='development') 'output/llm_classification/dev_requests_v2_114.csv' else
    'output/llm_classification/holdout_requests_v2_105.csv'
  outpath <- if (dataset=='development') 'output/llm_classification/gemini_dev_v2_history.csv' else
    'output/llm_classification/gemini_holdout_v2_history.csv'
  if (!file.exists(inpath)) stop('Missing requests: ',inpath)
  reqs <- readr::read_csv(inpath,show_col_types=FALSE)
  stopifnot(all(c('RESPID','mention_number','Q22','prompt_version','system_prompt','user_prompt') %in% names(reqs)),
            !anyDuplicated(reqs[c('RESPID','mention_number')]),
            length(unique(reqs$prompt_version))==1L,
            identical(unique(reqs$prompt_version),'gemini_prompt_v2_2026-11-07'))
  if (is.null(n)) n <- nrow(reqs)
  if (length(n)!=1L || is.na(n) || n<1L || n>nrow(reqs)) stop('n must be between 1 and ',nrow(reqs))
  prior <- if (file.exists(outpath)) readr::read_csv(outpath,show_col_types=FALSE) else NULL
  if (!is.null(prior)) {
    needed <- c('RESPID','mention_number','model','prompt_version','validation_ok')
    if (!all(needed %in% names(prior))) stop('Unexpected history file format')
    if (any(prior$prompt_version != unique(reqs$prompt_version),na.rm=TRUE))
      stop('History file includes a DIFFERENT prompt version: refuse to mix attempts')
  }
  out <- if (is.null(prior)) data.frame() else as.data.frame(prior)
  for (i in seq_len(n)) {
    row <- reqs[i,]
    if (nrow(out)>0L && any(out$RESPID==row$RESPID & out$mention_number==row$mention_number &
                             out$model==model & out$prompt_version==row$prompt_version &
                             out$validation_ok %in% TRUE,na.rm=TRUE)) {
      message('Skipping previously validated row ',i); next
    }
    body <- list(systemInstruction=list(parts=list(list(text=row$system_prompt))),
                 contents=list(list(role='user',parts=list(list(text=row$user_prompt)))),
                 generationConfig=list(responseMimeType='application/json',temperature=0,
                                       maxOutputTokens=500))
    url <- paste0('https://generativelanguage.googleapis.com/v1beta/models/',model,':generateContent')
    result <- tryCatch({
      response <- httr2::request(url) |>
        httr2::req_method('POST') |>
        httr2::req_headers(`x-goog-api-key`=key) |>
        httr2::req_body_json(body,auto_unbox=TRUE) |>
        httr2::req_timeout(75) |>
        httr2::req_perform()
      obj <- httr2::resp_body_json(response,simplifyVector=FALSE)
      parts <- obj$candidates[[1]]$content$parts
      content <- paste(vapply(parts,function(p) if (is.null(p$text)) '' else p$text,character(1)),collapse='')
      if (!nzchar(content)) stop('Empty model response')
      v <- validate_llm_json(content)
      list(text=content,ok=v$ok,reason=if (v$ok) '' else v$reason,
           prompt_tokens=if(is.null(obj$usageMetadata$promptTokenCount)) NA_integer_ else obj$usageMetadata$promptTokenCount,
           output_tokens=if(is.null(obj$usageMetadata$candidatesTokenCount)) NA_integer_ else obj$usageMetadata$candidatesTokenCount)
    },error=function(e){
      msg <- gsub(key,'[REDACTED]',conditionMessage(e),fixed=TRUE)
      message('Gemini error on row ',i,': ',msg)
      list(text='',ok=FALSE,reason='request_failed',prompt_tokens=NA_integer_,output_tokens=NA_integer_)
    })
    new <- data.frame(RESPID=as.character(row$RESPID),mention_number=as.integer(row$mention_number),
                      Q22=as.character(row$Q22),model=model,prompt_version=as.character(row$prompt_version),
                      json_text=result$text,validation_ok=result$ok,validation_reason=result$reason,
                      prompt_tokens=result$prompt_tokens,output_tokens=result$output_tokens,
                      run_utc=format(Sys.time(),tz='UTC',usetz=TRUE))
    out <- rbind(out,new)
    readr::write_csv(out,outpath)
    message('Saved row ',i,'/',n,' | valid=',result$ok)
    if (i<n) Sys.sleep(pause_seconds)
  }
  invisible(out)
}
# No automatic API call when sourcing.
