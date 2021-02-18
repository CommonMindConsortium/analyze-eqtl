######### Get input synapseId based on chromosome annotations
library("argparse")
parser <- ArgumentParser(
  description = "Get input Synapse id."
)
parser$add_argument("chromosome", type="character",
                    help="chromosome value from 1-22")
args <- parser$parse_args()

df <- read.table("SYNAPSE_TABLE_QUERY_72602897.csv", sep = ",", header = TRUE)
cat(as.character(df$id[df$chromosome == args$chromosome]))
