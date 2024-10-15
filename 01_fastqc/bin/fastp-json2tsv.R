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

# This will pull out the summary and before/after filtering stats. Before filtering stats are given the prefix "raw."
myData <- fromJSON(file = JSON)
SAMPLE <- strsplit(basename(JSON), split = ".", fixed = TRUE)[[1]][1]
RUN <- strsplit(basename(JSON), split = ".", fixed = TRUE)[[1]][3]
logWrite(paste("Input:", JSON, "->", SAMPLE, RUN))

# Print the result.
names(myData)
(fastp_filt <- as_tibble(myData$filtering_result) %>% mutate(sample = SAMPLE, run = RUN) %>% relocate(sample, run))
raw <- as_tibble(myData$summary$before_filtering) %>% rename_with(~paste0("raw.", .x)) %>% mutate(sample = SAMPLE)
filt <- as_tibble(myData$summary$after_filtering) %>% mutate(sample = SAMPLE)

(fastp <- fastp_filt %>% left_join(raw))
(fastp <- fastp %>% left_join(filt, by = "sample"))

TSV <- paste0(JSON, ".tsv")
write.table(fastp, file = TSV, quote = FALSE, row.names = FALSE, sep = "\t")
logWrite(paste("Output:", TSV))
