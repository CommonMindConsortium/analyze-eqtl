# analyze-eqtl
Expression quantitative trait loci (eQTL) analysis 

In this repo, QTLtools (permutations, conditional, nominal) is called in shell scripts, with custom code for two cohorts called HBCC and MPP (See subfolders HBCC and MPP). QTLtools requires file munging (merged (bcftools), zipped (bgzip,gzip), indexed (tabix)). Those steps are called sequentially in the shell scripts.  
- Inputs are defined as exported variables in scripts with the substring "define_inputs". These files were created automatically from a table on Synapse (syn25421421). [Here is the list of input vcf files.](https://www.synapse.org/#!Synapse:syn23667032/tables/)
- vcfs are merged, filtered (0.01:minor) and samples retained based off of the ancestry vector (HBCC:syn25315989, MPP:syn24861211). [HBCC merge script](https://github.com/CommonMindConsortium/analyze-eqtl/blob/main/HBCC/merge_hbcc_vcfs.sh).
- QTLtools is called in either nominal, conditional or permuatation mode.
- Rscript dependencies are stored in the utils subfolder.
- the visualize subfolder contains scripts for summarizing QTLtools output.
- [Dockerfile provided with all environment dependencies](https://github.com/CommonMindConsortium/analyze-eqtl/blob/main/Dockerfile).
