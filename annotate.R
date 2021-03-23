# set num eqtls as annotations.
library(purrr)
library(dplyr)
library(ggplot2)
library(readr)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
syn$login()
syn$tableQuery("select ROW_ID from syn24869959 limit 1")
query_result <- syn$tableQuery("SELECT * FROM syn24869959 where tissue = 'DLPFC' and cellType = 'MgAs'")

dat <- read_csv(query_result$filepath)
p_value <- 1e-6
for (i in dat$id) {
  file <- syn$get(i)$path
  cmd <- paste(
    "zcat", 
    file, 
    "| awk '{if($15== 1 && $12 < ", 
    p_value, 
    ") print $1}' | wc -l"
    )
  tmp <- fread(cmd = cmd)
  num <- tmp$V1
  annots <- syn$getAnnotations(i)
  annots['genes'] = num
  syn$set_annotations(annots)
}
