#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
names="HBCC_h1m_genotyping_samples_rename.txt"
parent="syn22220656"
query="SELECT * FROM syn23667032 where cohort = 'HBCC' and genotypingArray = 'H1M' and fileFormat = 'vcf'"
synapse --configPath "/tmp/.synapseConfig" get -q ${query}
for ((CHROM=1;CHROM<=22;CHROM++));
do
   echo "# Running chromosome: $CHROM"
   zcat "chr${CHROM}.dose.vcf.gz" | bgzip -c > "chr${CHROM}.dose.vcf.bgz"
   bcftools reheader -s ${names} -o "renamed.chr${CHROM}.dose.vcf.bgz" "chr${CHROM}.dose.vcf.bgz"
   mv "renamed.chr${CHROM}.dose.vcf.bgz" "chr${CHROM}.dose.vcf.gz"
   synapse --configPath "/tmp/.synapseConfig" store --parentid ${parent} "chr${CHROM}.dose.vcf.gz" &
done
