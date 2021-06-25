#!/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
samples_by_ancestry="MPP_european.exc"
for ((CHROM=1; CHROM<=22;CHROM++));
do
    echo "# Running chromosome: $CHROM"
    bcftools view -i "(R2 > .7)" -S "${samples_by_ancestry}" "chr${CHROM}.dose.vcf.gz" \
    | bcftools view -q 0.01:minor | bgzip > "chr${CHROM}.out.dose.vcf.gz"
    tabix -p vcf "chr${CHROM}.out.dose.vcf.gz"
done

CHROM="X"
bcftools view -i "(R2 > .7)" -S "${samples_by_ancestry}" "chr${CHROM}.dose.vcf.gz" \
| bcftools view -q 0.01:minor | bgzip > "chr${CHROM}.out.dose.vcf.gz"
tabix -p vcf "chr${CHROM}.out.dose.vcf.gz"
