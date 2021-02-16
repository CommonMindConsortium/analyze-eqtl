#!/usr/bin/bash
export PATH="$PATH:/usr/bin/bcftools-1.10"

for ((CHROM=1;CHROM<=1;CHROM++));
do
   ID=$(Rscript parse_synid.R $CHROM)
   echo "# Running chromosome: $CHROM"
   tabix -p vcf "chr${CHROM}.dose.vcf.gz"
   parallel prog ::: $(for ((i=2;i<=30;i++))
   do;
      Rscript iterate_peer.R "covariateMatrix_MSSM_Penn_Pitt_ACC.txt" "PEERMSSM_Penn_Pitt_ACC.txt" $i
      gzip "tmp_metadata_${i}.txt"
      echo "metadata complete..."
      QTLtools cis --vcf "chr${CHROM}.dose.vcf.gz" --bed geneExpr_MSSM_Penn_Pitt_ACC.bed.gz --cov "tmp_metadata_${i}.txt.gz" --nominal 0.01 --out "chr${CHROM}.nominals.${i}.txt" --normal --include-samples MPP_european.exc
      gzip "chr${CHROM}.nominals.${i}.txt"
      synapse --configPath "/tmp/.synapseConfig" store "chr${CHROM}.nominals.${i}.txt.gz" --parentid syn24860516 --annotations '{"cohort":"MSSM-Penn-Pitt", "chromosome":"'"${CHROM}"'", "peer":"'"${i}"'"}' --used $ID syn24861211 syn24858339 syn24171143 syn23680096
      synapse --configPath "/tmp/.synapseConfig" store --parentid syn24861201 "tmp_metadata_${i}.txt.gz"
      rm "chr${CHROM}.nominals.${i}.txt.gz" "tmp_metadata_${i}.txt.gz";
    done)
done
