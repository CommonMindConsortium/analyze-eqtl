# set num eqtls as annotations.
library(purrr)
library(dplyr)
library(ggplot2)
library(sagethemes)
library(readr)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
syn$login()
query_result <- syn$tableQuery("select * from syn24869959 where eqtls is null")

dat <- read_csv(query_result$filepath) %>% 
  select(-ROW_ID, -ROW_VERSION, -ROW_ETAG)

for (i in dat$id) {
  tmp <- read_delim(
    readLines(
      syn$get(i)$path
    ),
    col_names = FALSE,
    delim = " "
  )
  
  num <- tmp %>% summarize(n())
  
  annots <- syn$getAnnotations(i)
  annots['eqtls'] = num$`n()`
  
  syn$set_annotations(annots)
}
