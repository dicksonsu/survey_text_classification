# Run from repository root: Rscript tests/test_classification.R
suppressPackageStartupMessages({library(dplyr); library(stringr); library(readr)})
source('R/classification_helpers.R')
# Independent expected labels for selected synthetic cases (not generated from classifier output).
examples <- data.frame(
  mention=c('joe rogan','youtube','mr beast','a few finance people',
            'a podcast about science','researchers on youtube','the news',
            'i cannot remember names','i follow nobody','myself'),
  expected=c('entity','platform_or_topic','entity','platform_or_topic',
             'platform_or_topic','platform_or_topic','platform_or_topic',
             'junk','junk','junk')
)
actual <- classify_q22(examples$mention)
fail <- which(is.na(actual) | actual != examples$expected)
if (length(fail)) {
  print(data.frame(examples[fail, ], actual=actual[fail]))
  stop(length(fail), ' classification check(s) failed')
}
message('PASS: ', nrow(examples), ' selected response classifications')
