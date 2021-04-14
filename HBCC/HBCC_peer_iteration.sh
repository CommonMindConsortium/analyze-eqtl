#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
do_iteration () {
    Rscript iterate_peer.R "covariateMatrix_${4}_${5}_${6}.txt" "PEER_${4}_${5}_${6}.txt" $1
    gzip "tmp_metadata_${1}.txt"
    echo "metadata complete..."
    QTLtools cis --vcf "chr${2}.merged.dose.vcf.gz" --bed "geneExpr_${4}_${5}_${6}.bed.gz" \
    --cov "tmp_metadata_${1}.txt.gz" --nominal 0.0001 --out "chr${2}.${5}.${6}.nominals.${1}.txt" \
    --normal --include-samples "$7"
    gzip "chr${2}.${5}.${6}.nominals.${1}.txt"
    synapse --configPath "/tmp/.synapseConfig" store "chr${2}.${5}.${6}.nominals.${1}.txt.gz" \
    --parentid "${8}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${2}"'", "tissue":"'"${5}"'", "cellType": "'"${6}"'", "peer":"'"${1}"'"}' \
    --used $3 $9 ${10} ${11}
    rm "chr${2}.${5}.${6}.nominals.${1}.txt.gz" "tmp_metadata_${1}.txt.gz"
}

export -f do_iteration

synapse --configPath "/tmp/.synapseConfig" get ${covariate_ID}
synapse --configPath "/tmp/.synapseConfig" get ${expression_ID}
synapse --configPath "/tmp/.synapseConfig" get ${peer_ID}
bgzip "geneExpr_${cohort}_${tissue}_${cellType}.bed"
tabix -p bed "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz"

for ((CHROM=1; CHROM<=22;CHROM++));
do
    echo "# Running chromosome: $CHROM"
    seq 0 50 | parallel do_iteration {} "$CHROM" "$ID" "$cohort" "$tissue" "$cellType" \
    "$samples_by_ancestry" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID"
done
rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz"
rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz.tbi"
rm "PEER_${cohort}_${tissue}_${cellType}.txt"
rm "covariateMatrix_${cohort}_${tissue}_${cellType}.txt"

