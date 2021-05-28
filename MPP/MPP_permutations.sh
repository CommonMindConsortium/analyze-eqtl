#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"
export ancestry_file_name="MPP_european.exc"
do_iteration () {
    QTLtools cis --vcf "chr${1}.out.dose.vcf.gz" --bed "geneExpr_${4}_${5}_${11}.bed.gz" \
    --cov "tmp_metadata_${2}.txt.gz" --permute 10000 --out "chr${1}.${4}.${5}.${11}.permutations.txt" \
    --normal --include-samples "$6"
    Rscript ./qtltools/scripts/qtltools_runFDR_cis.R "chr${1}.${4}.${5}.${11}.permutations.txt" 0.05 "chr${1}.${4}.${5}.${11}.permutations" 
    awk '{ if($6 > 0) { print }}' "chr${1}.${4}.${5}.${11}.permutations.txt" > "tmp${1}.${4}.${5}.${11}.txt"
    cp "tmp${1}.${4}.${5}.${11}.txt" "chr${1}.${4}.${5}.${11}.permutations.txt"
    gzip "chr${1}.${4}.${5}.${11}.permutations.txt"
    gzip "chr${1}.${4}.${5}.${11}.permutations.significant.txt"
    gzip "chr${1}.${4}.${5}.${11}.permutations.thresholds.txt"
    synapse --configPath "/tmp/.synapseConfig" store "chr${1}.${4}.${5}.${11}.permutations.txt.gz" \
    --parentid "${7}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${1}"'", "tissue":"'"${5}"'","cellType": "'"${11}"'", "peer":"'"${2}"'", "fileType":"raw"}' \
    --used $3 $8 $9 ${10} ${12}
    synapse --configPath "/tmp/.synapseConfig" store "chr${1}.${4}.${5}.${11}.permutations.significant.txt.gz" \
    --parentid "${7}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${1}"'", "tissue":"'"${5}"'","cellType": "'"${11}"'", "peer":"'"${2}"'", "fileType":"significant"}' \
    --used $3 $8 $9 ${10} ${12}
    synapse --configPath "/tmp/.synapseConfig" store "chr${1}.${4}.${5}.${11}.permutations.thresholds.txt.gz" \
    --parentid "${7}" \
    --annotations '{"cohort":"'"${4}"'", "chromosome":"'"${1}"'", "tissue":"'"${5}"'","cellType": "'"${11}"'", "peer":"'"${2}"'", "fileType":"thresholds"}' \
    --used $3 $8 $9 ${10} ${12}
    rm "chr${1}.${4}.${5}.${11}.permutations.txt.gz" "chr${1}.${4}.${5}.${11}.permutations.thresholds.txt.gz" \
    "chr${1}.${4}.${5}.${11}.permutations.significant.txt.gz" "tmp${1}.${4}.${5}.${11}.txt"
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
"$ancestry_file_name" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID" \
"$cellType" "$samples_by_ancestry"

export CHROM="X"
do_iteration "$CHROM" "$numPeer" "$ID" "$cohort" "$tissue" \
"$ancestry_file_name" "$store_id" "$covariate_ID" "$expression_ID" "$peer_ID" \
"$cellType" "$samples_by_ancestry"

rm "tmp_metadata_${numPeer}.txt.gz"
rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz"
rm "geneExpr_${cohort}_${tissue}_${cellType}.bed.gz.tbi"
rm "PEER_${cohort}_${tissue}_${cellType}.txt"
rm "covariateMatrix_${cohort}_${tissue}_${cellType}.txt"

