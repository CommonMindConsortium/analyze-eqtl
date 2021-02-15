######### Utility functions for eQTL data munging
get_synapse_data <- function(dat) {
  if (file_ext(dat$get("path")) == "RDS") {
    dat <- readRDS(dat$path)
  } else {
    dat <- fread(dat$path)
  }
}
