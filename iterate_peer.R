######### This script will take the base covariate matrix and append i number of
######### PEER factors
library(readr)
library(dplyr)
library(argparse)
library(glue)

# create argument options
parser <- ArgumentParser(
  description = "Append x PEER factors to covariate matrix"
)
parser$add_argument("covariates", type="character",
                    help="path to txt with covariate matrix")
parser$add_argument("peer", type="character",
                    help="path to PEER factor matrix")
parser$add_argument("iteration", type = "double",
                    help = "number of PEER factor to include")
args <- parser$parse_args()

covars <- read_tsv(args$covariates)
peer <- read_tsv(args$peer)

dat <- bind_rows(covars, peer[0:args$iteration,])

write.table(
  dat,
  glue("tmp_metadata_{args$iteration}.txt"),
  sep = "\t", 
  row.names = FALSE, 
  quote = FALSE
  )