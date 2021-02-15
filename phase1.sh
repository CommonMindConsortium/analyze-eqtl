#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
for ((CHROM=7;CHROM<=22;CHROM++));
do
   echo "# Running chromosome: $CHROM"
   zcat "chr${CHROM}.dose.vcf.gz" | bgzip -c > "chr${CHROM}.dose.vcf.bgz"
   bcftools reheader -s MSSM-Penn-Pitt_genotyping_samples_rename.txt -o "renamed.chr${CHROM}.dose.vcf.bgz" "chr${CHROM}.dose.vcf.bgz"
   mv "renamed.chr${CHROM}.dose.vcf.bgz" "chr${CHROM}.dose.vcf.gz"
   tabix -p vcf "chr${CHROM}.dose.vcf.gz"
   QTLtools cis --vcf "chr${CHROM}.dose.vcf.gz" --bed geneExpr_MSSM_Penn_Pitt_ACC.bed.gz --cov covariateMatrix_MSSM_Penn_Pitt_ACC.txt.gz --nominal 1 --out "chr${CHROM}.nominals.txt"
   synapse --configPath "/tmp/.synapseConfig" store --parentid syn24175716 "chr${CHROM}.nominals.txt"
   synapse --configPath "/tmp/.synapseConfig" store --parentid syn22220486 --annotations '{"cohort":"MSSM-Penn-Pitt", "dataType":"genomicVariants","reference":"TOPMED","chromosome":"'"${CHROM}"'", "fileFormat":"vcf", "analysisType":"genotype imputation"}' "chr${CHROM}.dose.vcf.gz"
   rm "chr${CHROM}.nominals.txt"
   rm "chr${CHROM}.dose.vcf.gz" &
done
