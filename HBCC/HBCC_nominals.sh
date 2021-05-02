#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
do_iteration () {
    QTLtools cis --vcf "chr${1}.merged.dose.vcf.gz" --bed "geneExpr_${4}_${5}_${11}.bed.gz" \
    --cov "tmp_metadata_${2}.txt.gz" --nominal 1 --out "chr${1}.${4}.${5}.${11}.nominals.txt" \
    --normal --include-samples "$6"
    gzip "chr${1}.${4}.${5}.${11}.nominals.txt"
    synapse --configPath "/tmp/.synapseConfig" store "chr${1}.${4}.${5}.${11}.nominals.txt.gz" \
    --parentid "${7}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${1}"'", "tissue":"'"${5}"'","cellType": "'"${11}"'", "peer":"'"${2}"'", "type":"nominals"}' \
    --used $3 $8 $9 ${10}
    rm "chr${1}.${4}.${5}.${11}.nominals.txt.gz" "tmp_metadata_${2}.txt.gz"
}

export -f do_iteration

synapse --configPath "/tmp/.synapseConfig" get ${covariate_ID}
synapse --configPath "/tmp/.synapseConfig" get ${expression_ID}
synapse --configPath "/tmp/.synapseConfig" get ${peer_ID}
bgzip "geneExpr_${cohort}_${tissue}_${cellType}.bed"
tabix -p bed "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz"
Rscript iterate_peer.R "covariateMatrix_${cohort}_${tissue}_${cellType}.txt" "PEER_${cohort}_${tissue}_${cellType}.txt" ${numPeer}
gzip "tmp_metadata_${numPeer}.txt"


seq 1 22 | parallel do_iteration {} "$numPeer" "$ID" "$cohort" "$tissue" \
"$samples_by_ancestry" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID" \
"$cellType"

export CHROM="X"
do_iteration "$CHROM" "$numPeer" "$ID" "$cohort" "$tissue" \
"$samples_by_ancestry" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID" \
"$cellType"

rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz"
rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz.tbi"
rm "PEER_${cohort}_${tissue}_${cellType}.txt"
rm "covariateMatrix_${cohort}_${tissue}_${cellType}.txt"
