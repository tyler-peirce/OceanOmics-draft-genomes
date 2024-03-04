#!/usr/bin/env Rscript
# Load libraries
library(tidyverse)
library(rjson)



settings <- list(outlog = stdout())
version <- "v0.1.0"
logWrite <- function(logstr) {
  writeLines(paste0("[", date(), "] ", logstr), con = settings$outlog)
}


args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("No JSON file provided.")
}


JSON <- args[1]


busco <- fromJSON(file = JSON)
SAMPLE <- (JSON)
SAMPLE <- gsub(".json$", "", SAMPLE)


logWrite(paste("Input:", JSON, "->", SAMPLE))


results <- as_tibble(busco$results) %>% 
            select(-1) %>% 
  mutate(sample = SAMPLE) %>%
  relocate(sample, .before = 1)




TSV <- paste0(JSON, ".tsv")
write.table(results, file = TSV, quote = FALSE, row.names = FALSE, sep = "\t")
logWrite(paste("Output:", TSV))
