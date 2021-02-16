#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"

do_iteration () {
    Rscript iterate_peer.R "covariateMatrix_MSSM_Penn_Pitt_ACC.txt" "PEERMSSM_Penn_Pitt_ACC.txt" $1
    gzip "tmp_metadata_${1}.txt"
    echo "metadata complete..."
    QTLtools cis --vcf "chr${2}.dose.vcf.gz" --bed geneExpr_MSSM_Penn_Pitt_ACC.bed.gz \
    --cov "tmp_metadata_${1}.txt.gz" --nominal 0.01 --out "chr${2}.nominals.${1}.txt" \
    --normal --include-samples MPP_european.exc
    gzip "chr${2}.nominals.${1}.txt"
    synapse --configPath "/tmp/.synapseConfig" store "chr${2}.nominals.${1}.txt.gz" --parentid syn24860516 --annotations '{"cohort":"MSSM-Penn-Pitt", "chromosome":"'"${2}"'", "peer":"'"${1}"'"}' --used $3 syn24861211 syn24858339 syn24171143 syn23680096
    synapse --configPath "/tmp/.synapseConfig" store --parentid syn24861201 "tmp_metadata_{}.txt.gz"
    rm "chr${2}.nominals.${1}.txt.gz" "tmp_metadata_${1}.txt.gz"
}

export -f do_iteration

for ((CHROM=1;CHROM<=1;CHROM++));
do
   ID=$(Rscript parse_synid.R $CHROM)
   echo "# Running chromosome: $CHROM"
   tabix -p vcf "chr${CHROM}.dose.vcf.gz"
   seq 0 30 | parallel do_iteration {} "$CHROM" "$ID"
done
wait
