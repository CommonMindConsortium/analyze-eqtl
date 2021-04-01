library(purrr)
library(dplyr)
library(ggplot2)
library(sagethemes)
library(readr)
synapseclient <- reticulate::import("synapseclient")
syn <- synapseclient$Synapse()
syn$login()
syn$tableQuery("select ROW_ID from syn24869959 limit 1")
Sys.sleep(5)

viz <- syn$tableQuery("SELECT * FROM syn24869959 where tissue = 'DLPFC'")

dat <- read_csv(viz$filepath, col_types = cols(.default = "c")) %>% 
  select(-ROW_ID, -ROW_VERSION, -ROW_ETAG)

dat <- dat %>%
  mutate(cellType = ifelse(is.na(cellType), "Bulk", cellType)) %>%
  mutate(genes = as.numeric(genes)) %>% 
  mutate(peer = as.numeric(peer))

dat <- dat[dat$cellType %in% c("Bulk", "GABA", "GLU"),]

dat_collapse <- dat %>% 
  group_by(peer, cellType) %>% 
  summarize(sum = sum(genes)) 

all <- ggplot(data = dat_collapse, aes(x = peer, y = sum, color = cellType)) + 
  geom_point(alpha = 0.5) +
  scale_color_manual(breaks = c("GABA", "GLU", "Olig", "MgAs", "Bulk"),
                     values = c("#66A61E", "#E6AB02", "#E7298A", "#7570B3", "#808080")) + 
  labs(
    x = "# PEER components", 
    y = "# eGenes at p < 1e-6"
  ) + 
  ylim(0, max(dat_collapse$sum)) + 
  theme(aspect.ratio=1) + 
  ggtitle("MSSM-Penn-Pitt eGenes of DLPFC")

all
