######### This script transposes the data frames to meet the required format
######### of QTLtools. Additionally, the sample identifier is remapped from
######### Sample_RNA_ID to Genotyping_Sample_ID to match the identifier in
######### the vcf files.

# load helper functions
source("utils/utilities.R")
# load packages
library(dplyr)
library(readr)
library(reticulate)
library(tibble)
library(tools)
library(glue)
library(data.table)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
ent <- synapseclient$entity
# login to Synapse
syn$login()

format_metadata <- function(covariate_synId, rna_metadata_synId, 
                            snp_metadata_synId, new_names, parent_folder,
                            exclude_column) {
  covars <- syn$get(covariate_synId)
  md_rna <- syn$get(rna_metadata_synId)
  md_snp <- syn$get(snp_metadata_synId)
  
  dat <- get_synapse_data(covars) %>% 
    as.data.frame() %>% 
    rownames_to_column(var = "sample")
  
  snp <- get_synapse_data(md_snp) %>% 
    filter(is.na(!!sym(exclude_column))) %>% 
    dplyr::select(Individual_ID, `SNP_report:Genotyping_Sample_ID`)
  
  rna <- get_synapse_data(md_rna) %>% 
    dplyr::select(Individual_ID, Sample_RNA_ID)
  
  new <- read_tsv(syn$get(new_names)$path, col_names = FALSE)
  
  md <- inner_join(rna, snp)
  
  md <- md[md$`SNP_report:Genotyping_Sample_ID` %in% new$X1,]
  
  dat <- right_join(md, dat, by = c("Sample_RNA_ID" = "sample"))
  
  if (
    !(
      identical(
        character(0),
        dat$Individual_ID[is.na(dat$`SNP_report:Genotyping_Sample_ID`)]
      )
    )
  ) {
    print(dat$Individual_ID[is.na(dat$`SNP_report:Genotyping_Sample_ID`)])
    stop("MISSING VALUES")
  }
  
  # set schema
  dat <- dat %>%
    dplyr::select(-Individual_ID, -Sample_RNA_ID) %>%
    rename(sample = `SNP_report:Genotyping_Sample_ID`)
  
  dat <- as.data.frame(dat) %>% 
    column_to_rownames(var = "sample")
  dat$sample <- NULL
  
  t_dat <- data.table::transpose(dat)
  colnames(t_dat) <- rownames(dat)
  rownames(t_dat) <- colnames(dat)
  t_dat$id <- colnames(dat)
  
  t_dat <- dplyr::select(t_dat, id, everything())
  
  write.table(
    t_dat, glue("{file_path_sans_ext(basename(covars$get('path')))}.txt"),
    sep = "\t", row.names = FALSE, quote = FALSE
  )
  
  file <- ent$File(
    glue("{file_path_sans_ext(basename(covars$get('path')))}.txt"),
    parent = parent_folder
  )
  
  synids <- c(new_names,covariate_synId,rna_metadata_synId,snp_metadata_synId)
  
  syn$store(
    file, 
    forceVersion = FALSE, 
    activityName = "Amend 50 PEER factors",
    used = synids
  )
}

files <- syn$getChildren("syn23572820") %>% 
  reticulate::iterate(.) %>%
  purrr::map(dplyr::as_tibble) %>%
  dplyr::bind_rows() %>% 
  mutate(cohort = map_chr(name, ~gsub(" .*", "", .)))

# map MSSM-Penn-Pitt latent and covariate variables only

ids <- files %>% 
  filter(cohort %in% c("NIMH-HBCC", "NIMH-HBCC-5"))
ids <- ids[grepl("Covariates|Latent", ids$name),]

map(
  ids$id, 
  ~format_metadata(
    covariate_synId = ., 
    rna_metadata_synId = "syn16816488",
    snp_metadata_synId = "syn16816490",
    new_names = "syn25322148",
    parent_folder = "syn23682444", 
    exclude_column = "SNP_report:Exclude?"
    )
  )
