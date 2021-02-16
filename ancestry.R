######### This script preserves samples from clusters A and B
library(readr)
library(dplyr)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
ent <- synapseclient$entity
# login to Synapse
syn$login()
ancestry_synId <- "syn2511399"
new_names <- "syn24172496"

ancestry <- read_tsv(syn$get(ancestry_synId)$path) %>% 
  filter(Cluster %in% c("A", "B", "E", "F", "G"))

new <- read_tsv(syn$get(new_names)$path, col_names = FALSE)

eu_samples <- new$X1[
  new$X1 %in% ancestry$DNA_report..Genotyping.Sample_ID
  ]

write.table(
  eu_samples,
  "MPP_european.exc",
  sep = "\t", 
  row.names = FALSE, 
  col.names = FALSE,
  quote = FALSE
  )

file <- ent$File(
  "MPP_european.exc",
  parent = "syn23682444"
)

synids <- c(new_names,ancestry_synId)

syn$store(
  file, 
  forceVersion = FALSE, 
  activityName = "Add clusters E, F, G to A, B",
  used = synids
)
