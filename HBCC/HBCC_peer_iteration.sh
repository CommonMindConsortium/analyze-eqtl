#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
do_iteration () {
    Rscript iterate_peer.R "covariateMatrix_${4}_${5}.txt" "PEER_${4}_${5}.txt" $1
    gzip "tmp_metadata_${1}.txt"
    echo "metadata complete..."
    QTLtools cis --vcf "chr${2}.merged.dose.vcf.gz" --bed "geneExpr_${4}_${5}.bed.gz" \
    --cov "tmp_metadata_${1}.txt.gz" --nominal 0.0001 --out "chr${2}.${5}.nominals.${1}.txt" \
    --normal --include-samples "$6"
    gzip "chr${2}.${5}.nominals.${1}.txt"
    synapse --configPath "/tmp/.synapseConfig" store "chr${2}.${5}.nominals.${1}.txt.gz" \
    --parentid "${7}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${2}"'", "tissue":"'"${5}"'", "peer":"'"${1}"'"}' \
    --used $3 $8 $9 ${10}
    rm "chr${2}.${5}.nominals.${1}.txt.gz" "tmp_metadata_${1}.txt.gz"
}

export -f do_iteration

synapse --configPath "/tmp/.synapseConfig" get ${covariate_ID}
synapse --configPath "/tmp/.synapseConfig" get ${expression_ID}
synapse --configPath "/tmp/.synapseConfig" get ${peer_ID}
bgzip "geneExpr_${cohort}_${tissue}.bed"
tabix -p bed "geneExpr_${cohort}_${tissue}.bed.gz"

for ((CHROM=1; CHROM<=22;CHROM++));
do
    echo "# Running chromosome: $CHROM"
    seq 0 50 | parallel do_iteration {} "$CHROM" "$ID" "$cohort" "$tissue" \
    "$samples_by_ancestry" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID"
done
rm "geneExpr_${cohort}_${tissue}.bed.gz"
rm "geneExpr_${cohort}_${tissue}.bed.gz.tbi"
rm "PEER_${cohort}_${tissue}.txt"
rm "covariateMatrix_${cohort}_${tissue}.txt"

