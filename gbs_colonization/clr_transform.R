library(compositions)
library(phyloseq)
library(microbiome)

setwd("~/Dropbox/CUA_GBS_study/SR13/qiime2-2021.2/feature_tables")

table2 = read.table("species-no_day0-3000-final-table.tsv", header = TRUE, row.names = 1)

OTU = otu_table(table2, taxa_are_rows = TRUE)
physeq = phyloseq(OTU)
xt <- microbiome::transform(physeq, 'clr')

otu<-as(otu_table(xt),"matrix") 
write.table(otu_table(xt), "species-no_day0-3000-final-table-clr.tsv",sep="\t", row.names=TRUE, col.names=NA, quote=FALSE)
            