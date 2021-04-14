######### This script takes observed expression and queries biomart for relative
######### gene annotations. The output file format is bed.
# This implementaiton of genetic data queries ensembl version 

# load helper functions
source("utils/utilities.R")
# http://apr2019.archive.ensembl.org
library(reticulate)
library(tidyverse)
library(tools)
library(data.table)
library(biomaRt)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
ent <- synapseclient$entity
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
ent <- synapseclient$entity
# login to Synapse
syn$login()
make_bed <- function(rna_metadata_synId, snp_metadata_synId, parent_folder,
                     gene_expression_synId, new_names, exclude_column){
  expr <- syn$get(gene_expression_synId)
  md_rna <- syn$get(rna_metadata_synId)
  md_snp <- syn$get(snp_metadata_synId)
  
  snp <- get_synapse_data(md_snp) %>% 
    filter(is.na(!!sym(exclude_column))) %>% 
    dplyr::select(Individual_ID, `SNP_report:Genotyping_Sample_ID`)
  
  rna <- get_synapse_data(md_rna) %>% 
    dplyr::select(Individual_ID, Sample_RNA_ID)
  md <- inner_join(rna, snp)
  
  new <- read_tsv(syn$get(new_names)$path, col_names = FALSE)
  
  md <- md[md$`SNP_report:Genotyping_Sample_ID` %in% new$X1,]
  
  df <- get_synapse_data(expr)
  
  # Mutate sample Ids to
  remap <- t(df)
  remap <- as.data.frame(remap)
  remap <- rownames_to_column(remap, var = "key")
  remap <- right_join(md, remap, by = c("Sample_RNA_ID" = "key"))
  remap <- column_to_rownames(remap, var = "SNP_report:Genotyping_Sample_ID")
  remap$Individual_ID <- NULL
  remap$Sample_RNA_ID <- NULL
  
  df <- t(remap)
  annots <- get_gene_positions(
    df, host = "apr2019.archive.ensembl.org", organism = "hsa"
  )
  row_ids <- convert_geneids(df)
  
  dat <- dplyr::mutate(as.data.frame(df), gid = row_ids)
  
  bed <- dplyr::left_join(annots, dat)
  
  write.table(
    bed, glue("{file_path_sans_ext(basename(expr$get('path')))}.bed"), sep = "\t",
    row.names = FALSE, quote = FALSE
  )
  
  file <- ent$File(
    glue("{file_path_sans_ext(basename(expr$get('path')))}.bed"),
    parent = "syn23679895"
  )
  syn$store(file, forceVersion = FALSE,
            used = c(rna_metadata_synId, snp_metadata_synId, gene_expression_synId)
  )
  
}

files <- syn$getChildren("syn23572820") %>% 
  reticulate::iterate(.) %>%
  purrr::map(dplyr::as_tibble) %>%
  dplyr::bind_rows() %>% 
  mutate(cohort = map_chr(name, ~gsub(" .*", "", .)))

# map MSSM-Penn-Pitt observed expression only
ids <- files %>% 
  filter(cohort %in% c("NIMH-HBCC", "NIMH-HBCC-5"))
ids <- ids[grepl("Observed expression", ids$name),]

map(
  ids$id, 
  ~make_bed(
    rna_metadata_synId = "syn16816488",
    snp_metadata_synId = "syn16816490",
    parent_folder = "syn23679895",
    gene_expression_synId = .,
    new_names = "syn25322148", 
    exclude_column = "SNP_report:Exclude?"
  )
)
