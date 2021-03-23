######### This script preserves samples from clusters A and B
library(readr)
library(dplyr)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
ent <- synapseclient$entity
# login to Synapse
syn$login()
ancestry_synId <- "syn9922992"
new_names <- c("syn25299009", "syn25299006", "syn25298986")

ancestry <- read_delim(syn$get(ancestry_synId)$path, delim = " ") %>% 
  filter(Population %in% c("Caucasian"))

new <- map(new_names, ~ read_tsv(syn$get(.)$path, col_names = FALSE)) %>% 
  reduce(bind_rows)

eu_samples <- new$X1[
  new$X1 %in% ancestry$ID
  ]

write.table(
  eu_samples,
  "HBCC_european.exc",
  sep = "\t", 
  row.names = FALSE, 
  col.names = FALSE,
  quote = FALSE
  )

file <- ent$File(
  "HBCC_european.exc",
  parent = "syn23682444"
)

synids <- c(new_names,ancestry_synId)

syn$store(
  file, 
  forceVersion = FALSE, 
  activityName = "Subset and include caucasian population only",
  used = synids
)
