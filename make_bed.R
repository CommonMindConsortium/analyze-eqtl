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
######### Mutable inputs ######### 
rna_metadata_synId <- "syn16816488"
snp_metadata_synId <- "syn16816490"
parent_folder <- "syn23679895"
gene_expression_synId <- "syn23567527"
new_names <- "syn24172496"
##################################
expr <- syn$get(gene_expression_synId)
md_rna <- syn$get(rna_metadata_synId)
md_snp <- syn$get(snp_metadata_synId)

snp <- get_synapse_data(md_snp) %>% 
  select(Individual_ID, `SNP_report:Genotyping_Sample_ID`) 
rna <- get_synapse_data(md_rna) %>% 
  select(Individual_ID, Sample_RNA_ID)
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
  bed, "geneExpr_MSSM_Penn_Pitt_ACC.bed", sep = "\t",
  row.names = FALSE, quote = FALSE
)

file <- ent$File(
  "geneExpr_MSSM_Penn_Pitt_ACC.bed",
  parent = "syn23679895"
)
syn$store(file, forceVersion = FALSE,
         used = c(rna_metadata_synId, snp_metadata_synId, gene_expression_synId),
         versionLabel = "addend complete cohort")
