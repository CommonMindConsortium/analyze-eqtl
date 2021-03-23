#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
samples_by_ancestry="HBCC_european.exc"
for ((CHROM=1; CHROM<=22;CHROM++));
do
    echo "# Running chromosome: $CHROM"
    bcftools view -i "(R2 > .7)" -o "H1M/tmp.vcf.gz" "H1M/chr${CHROM}.dose.vcf.gz"
    bcftools view -i "(R2 > .7)" -o "H5M4/tmp.vcf.gz" "H5M4/chr${CHROM}.dose.vcf.gz"
    bcftools view -i "(R2 > .7)" -o "H650K/tmp.vcf.gz" "H650K/chr${CHROM}.dose.vcf.gz"
    bcftools merge "H1M/tmp.vcf.gz" "H5M4/tmp.vcf.gz" "H650K/tmp.vcf.gz" \
    | bcftools view -q 0.01:minor -S "${samples_by_ancestry}" | bgzip > "chr${CHROM}.out.dose.vcf.gz"
done
