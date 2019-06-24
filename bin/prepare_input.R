#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

## Library
if (!(require(data.table))) install.packages("data.table")

#-------------------------------------------------
# args:
#-------------------------------------------------
## sampleID is a string, each sampleID sepearted by ","
sampleID = unlist(strsplit(args[1], ","))
## TODO: the output fold should be exist or need to create here
output_prefix = args[2]
## THe copy number variation input file: "data_cna_hg19.seg" in the cbioportal datasets
cnv_file = args[3]
## The mutation input : "data_mutations_mskcc.txt" in the cbioportal datasets
mut_file= args[4]
#-------------------------------------------------

#-------------------------------------------------
# Input for DeBug
#-------------------------------------------------
## MSKCC
# sampleID_list = c("P-0002463-T01-IM3", "P-0002463-T02-IM5")
# sampleID = sampleID_list[1]
# output_prefix = "tsv/mskcc_"

# cnv_file = "../../../../../../data/crc_msk_2017/data_cna_hg19.seg"
# mut_file = "../../../../../../data/crc_msk_2017/data_mutations_mskcc.txt"


preparing_pyclone_input = function(cnv_file, mut_file, sampleID, output_prefix) {

    # Create the output dir 
    dir.create(dirname(paste0(output_prefix, "//")), recursive = T, showWarnings = F)


    # read file
    cnv = fread(cnv_file)
    mut = fread(mut_file)

    # extract data for specific sample
    cnv_p = cnv[ID == sampleID]
    mut_p = mut[Tumor_Sample_Barcode == sampleID]


    # pre-PyClone input
    pre_pc_input = mut_p[, .(
        mutation_id = paste0(Hugo_Symbol, "_", HGVSc), 
        chr = Chromosome,
        pos = Start_Position,
        ref_counts = t_ref_count,
        var_counts = t_alt_count
        )]

    # Annote the CNV for specific mutation
    get_cnv = function(qchr, qpos, cnv_tab) {
        #         qchr = 9
        #         qpos = 98211549
        #         cnv_tab = cnv_p

        seg_mean = cnv_tab[chrom == qchr & loc.start <= qpos & loc.end >= qpos, seg.mean]
        if (length(seg_mean) == 0) {
            seg_mean = 0
        }
        round(2^seg_mean * 2, 0)
    }

    # Annotting the CNV of mutations
    pre_pc_input[, major_cn := get_cnv(chr, pos, cnv_p), by = mutation_id]
    # TODO: if a mutation has no CNV information?
    pre_pc_input[, minor_cn := 0]

    # Assume the normal copy number of a loci always be 2
    pre_pc_input[, .(mutation_id, ref_counts, var_counts, normal_cn = 2, major_cn, minor_cn)]

    fwrite(pre_pc_input[, .(mutation_id, ref_counts, var_counts, normal_cn = 2, major_cn, minor_cn)], paste0(output_prefix, sampleID, ".tsv"), sep="\t")
}

for (sampleID_x in sampleID) {
    preparing_pyclone_input(cnv_file, mut_file, sampleID_x, output_prefix)
}

