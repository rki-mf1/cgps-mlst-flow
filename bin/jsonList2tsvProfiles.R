################################################################################
# Create (cg)MLST profiles for provided CGPS (cg)MLST output
#
# Author: Vladimir Bajić
# Date: 2025-10-27
#
# Description:
#   This script takes as input txt file with each line indicating
#   a paths to a json file produced by CGPS (cg)MLST
#   It combines all of them into single tsv profile
#   where empty hashes are replaced with 0
#
# Usage:
#
# To see help message
#   Rscript --vanilla jsonList2tsvProfiles.R --help
#
# To make hashed profile from json files
#   Rscript --vanilla jsonList2tsvProfiles.R -i /path_to/json_path_list.txt -o hashed_profile.tsv
#
################################################################################

# Load libraries ---------------------------------------------------------------
library(optparse)
suppressMessages(library(tidyverse))
suppressMessages(library(jsonlite))

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the txt file with each line indicating a paths to a json file produced by CGPS (cg)MLST", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Output name", metavar = "character")
)

# Parsing options --------------------------------------------------------------
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# TESSTING PURPOSES ONLY -------------------------------------------------------
# opt$i <- "/scratch/bajicv/projects/cgps-mlst-flow/tmp_json_list.txt"
# opt$o <- "/scratch/bajicv/projects/cgps-mlst-flow/X_test_out"

# Check the provided option and execute the corresponding code -----------------
if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Provide path to the directory with json files outputed by CGPS (cg)MLST.")
}

if (is.null(opt$o)) {
    print_help(opt_parser)
    stop("Provide output name.")
}

# Create out dir if it doesn't exist -------------------------------------------
if (!dir.exists(opt$o)) {
    cat("Creating output directory.\n")
    dir.create(opt$o)
}

# Read in the list of json file paths ------------------------------------------
files <- read_lines(opt$i)

# Extract basic info columns ---------------------------------------------------
basic_info_columns <- c("st", "scheme", "schemeName", "host", "schemeId", "type", "schemeSize")

# Extract basic info from all json files ---------------------------------------
info_tbl <-
    files %>%
    map_df(function(path) {
        json_data <- fromJSON(path)
        sample_id <- tools::file_path_sans_ext(basename(path))

        tibble(Sample_ID = sample_id) %>%
            bind_cols(as_tibble(json_data[basic_info_columns]))
    })

# Extract unique profile type from first json file -----------------------------
json_data_type <- unique(info_tbl$type)

if (length(json_data_type) != 1) {
    stop("Multiple profile types (i.e. cgMLST and MLST) found in the provided json files.")
}

# Function to process one JSON file with profile type option -------------------
# profile_type: "code" or "raw_code"
process_profile <- function(json_path, profile_type) {
    json_data <- fromJSON(json_path)
    sample_id <- tools::file_path_sans_ext(basename(json_path))

    # Split code into alleles and replace blanks
    alleles <- json_data[[profile_type]] %>%
        str_split("_") %>%
        unlist()
    alleles[alleles == ""] <- "0"

    # Create one-row tibble: sample_id + alleles spread by locus
    tibble(Sample_ID = sample_id) %>%
        bind_cols(
            tibble(Allele = alleles, Locus = json_data$genes) %>%
                pivot_wider(names_from = Locus, values_from = Allele)
        )
}

# Process all JSONs and combine ------------------------------------------------
profile_code <- map_dfr(files, ~ process_profile(., profile_type = "code"))
profile_hashes <- map_dfr(files, ~ process_profile(., profile_type = "raw_code"))

# Save tables ------------------------------------------------------------------
write_tsv(info_tbl, paste0(opt$o, "/", json_data_type, "_info.tsv"))
write_tsv(profile_hashes, paste0(opt$o, "/", json_data_type, "_profile_hashed.tsv"))
write_tsv(profile_code, paste0(opt$o, "/", json_data_type, "_profile.tsv"))
