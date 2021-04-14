######### Utility functions for eQTL data munging
# read in Synapse data; accepts RDS format
get_synapse_data <- function(dat) {
  if (file_ext(dat$get("path")) == "RDS") {
    dat <- readRDS(dat$path)
  } else {
    dat <- fread(dat$path)
  }
}
# get BioMart dataset 
biomart_obj <- function(organism, host) {
  message("Connecting to BioMart ...")
  ensembl <- biomaRt::useMart("ENSEMBL_MART_ENSEMBL", host = host)
  ds <- biomaRt::listDatasets(ensembl)[, "dataset"]
  ds <- grep(paste0("^", organism), ds, value = TRUE)
  if (length(ds) == 0) {
    stop(paste("Mart not found for:", organism))
  } else if (length(ds) > 1) {
    message("Found several marts")
    sapply(ds, function(d) message(paste(which(ds == d), d, sep = ": ")))
    n <- readline(paste0("Choose mart (1-", length(ds), ") : "))
    ds <- ds[as.integer(n)]
  }
  ensembl <- biomaRt::useDataset(ds, mart = ensembl)
  ensembl
}
# get ENSEMBL gene Id without version number appended 
convert_geneids <- function(count_df) {
  if (any(grepl("\\.", rownames(count_df)))) {
    geneids <- tibble::tibble(ids = rownames(count_df)) %>%
      tidyr::separate(.data$ids, c("ensembl_gene_id", "position"), sep = "\\.")
    geneids$ensembl_gene_id
  } else {
    rownames(count_df)
  }
}
# query biomart for gene annotations
get_gene_positions <- function(count_df, host, organism) {
  # Get available datset from Ensembl
  ensembl <- biomart_obj(organism, host)
  
  # Parse gene IDs to use in query
  gene_ids <- convert_geneids(count_df)
  
  message(paste0("Downloading sequence",
                 ifelse(length(gene_ids) > 1, "s", ""), " ..."))
  
  if (length(gene_ids) > 100)
    message("This may take a few minutes ...")
  
  attrs <- c("chromosome_name", "start_position", "end_position",
             "ensembl_gene_id", "ensembl_gene_id", "strand")
  
  coords <- biomaRt::getBM(filters = "ensembl_gene_id",
                           attributes = attrs,
                           values = gene_ids,
                           mart = ensembl,
                           useCache = FALSE)
  
  # mutate strand to + and -
  coords <- dplyr::mutate(
    coords,
    strand = ifelse(strand == -1, "-", "+")
  )
  
  # columns names constrained by bed format
  coords <- coords %>%
    dplyr::rename(
      gid = `ensembl_gene_id.1`,
      pid = `ensembl_gene_id`,
      `#chrom` = chromosome_name
    )
  
  # Negative strand needs positions reordered
  # coords <- coords %>%
  #   group_by(strand) %>%
  #   nest() %>%
  #   mutate(
  #     data = map_if(
  #       data,
  #       strand %in% c("-"),
  #       flip_coordinates
  #     )
  #   ) %>%
  #   unnest(cols = data)
  
  # filter for 22 chromosomes, X, Y and MT
  coords <- dplyr::filter(
    coords, `#chrom` %in% c(1:22, "X", "Y", "MT")
  )
  
  # order by position
  coords <- coords[with(coords, order(`#chrom`, start_position)),]
  
  # chromosome needs chr appended
  res <- dplyr::mutate(
    coords, `#chrom` = paste0("chr", `#chrom`)
  )
  
  # set up order
  res <- dplyr::select(
    res,
    `#chrom`, start_position,
    end_position, pid, gid, strand,
    everything()
  )
  res
}