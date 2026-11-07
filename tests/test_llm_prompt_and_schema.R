source("R/llm_prompt.R")
source("R/llm_output_validation.R")
stopifnot(grepl("named_source", llm_system_prompt(), fixed = TRUE))
stopifnot(grepl("Alex", llm_system_prompt(), fixed = TRUE))
stopifnot(grepl("prepared_mention", llm_user_prompt("npr", "I watch NPR"), fixed = TRUE))
valid <- '{"response_type":"entity","entity_clean":null,"resolution_status":"unresolved","nonresponse_subtype":null,"review_flag":true,"review_reason":"Only a first name supplied"}'
invalid <- '{"response_type":"entity","entity_clean":"Alex Famous","resolution_status":"unresolved","nonresponse_subtype":null,"review_flag":false,"review_reason":null}'
stopifnot(isTRUE(validate_llm_json(valid)$ok))
stopifnot(!validate_llm_json(invalid)$ok)
cat("PASS: prompt builder and structured-output validator\n")
