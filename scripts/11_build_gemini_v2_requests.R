# Build prompt-v2 requests without labels. NO API calls.
# source('scripts/11_build_gemini_v2_requests.R') then build_gemini_v2_requests('development')
# Only build holdout after freezing prompt-v2 and settings.
source('R/llm_prompt.R')

build_gemini_v2_requests <- function(dataset = c('development', 'holdout')) {
  dataset <- match.arg(dataset)
  if (!requireNamespace('readr', quietly=TRUE) || !requireNamespace('dplyr', quietly=TRUE) ||
      !requireNamespace('jsonlite', quietly=TRUE)) stop('Install readr, dplyr and jsonlite')
  if (dataset == 'development') {
    x <- readr::read_csv('data/reference/reference_coding_workbook.csv', show_col_types=FALSE)
    stopifnot(nrow(x) == 114L)
    path <- 'output/llm_classification/dev_requests_v2_114.csv'
  } else {
    # EXCLUDE entire responses with frozen preparation segmentation errors, just like rule-v2 benchmark.
    ref <- readr::read_csv('data/holdout/holdout_reference_final_109.csv', na='', show_col_types=FALSE)
    frozen <- readr::read_csv('data/holdout/holdout_preparation_frozen_113.csv', na='', show_col_types=FALSE)
    stopifnot(nrow(ref)==109L,nrow(frozen)==113L,all(ref$review_status=='human_verified'))
    seq_rows <- function(d) d |>
      dplyr::arrange(.data$RESPID,.data$mention_number) |>
      dplyr::group_by(.data$RESPID) |>
      dplyr::summarise(n=dplyr::n(),original=paste(unique(.data$Q22_original),collapse=' || '),
                       mentions=paste(.data$Q22,collapse=' || '),.groups='drop')
    a <- seq_rows(ref); b <- seq_rows(frozen)
    matches <- dplyr::inner_join(a,b,by='RESPID',suffix=c('_ref','_frozen')) |>
      dplyr::filter(.data$n_ref==.data$n_frozen,.data$original_ref==.data$original_frozen,
                    .data$mentions_ref==.data$mentions_frozen)
    stopifnot(nrow(matches)==96L)
    x <- ref |> dplyr::filter(.data$RESPID %in% matches$RESPID)
    stopifnot(nrow(x)==105L)
    path <- 'output/llm_classification/holdout_requests_v2_105.csv'
  }
  required <- c('RESPID','mention_number','Q22','Q22_original')
  stopifnot(all(required %in% names(x)), !anyDuplicated(x[required[1:2]]))
  # Deliberately select only input fields: never expose reference_type or reference_entity.
  x <- x[, required]
  x$prompt_version <- llm_prompt_version()
  x$system_prompt <- llm_system_prompt()
  x$user_prompt <- vapply(seq_len(nrow(x)),function(i) llm_user_prompt(x$Q22[i],x$Q22_original[i]),character(1))
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  readr::write_csv(x,path)
  cat('Created',nrow(x),dataset,'requests at',path,'(no API calls)\n')
  invisible(x)
}
