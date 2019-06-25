#!/usr/bin/env perl6

use YAMLish;

sub MAIN ($output-fold, $sampleID, $dataset-fold, $config-yaml-temp = "./config/config.yaml.temp") {

    my @sampleID = $sampleID.split(",");
    my $seg-file = $dataset-fold ~ "/data_cna_hg19.seg";
    my $mutation-file = $dataset-fold ~ "/data_mutations_mskcc.txt";
    my $tsv-fold = $output-fold ~ "/tsv/";
    my $yaml-fold = $output-fold ~ "/yaml/";
    my $config-yaml-file = $output-fold ~ "/config.yaml";
    my $tables-fold = $output-fold ~ "/tables/";
    my $tables-file-name = $tables-fold ~ "mutation_cluster.tsv";

    mkdir $output-fold;
    mkdir $tables-fold;

    # Run:
    ## Step1. Prepare the mutation & cnv table using cbioportal datasets
    my %sample-info = prepare-tsv(@sampleID, $seg-file, $mutation-file, $tsv-fold);

    ## Step2. Infer mutation cluster using PyClone 
    for %sample-info.kv -> $sampleID, %info {
        %sample-info{$sampleID}<yaml-file> = prepare-sample-mutation-yaml($sampleID, %info<tsv-file>, $yaml-fold);
    }

#    prepare-pyclone-config(%sample-info, $config-yaml-temp, $config-yaml-file, $output-fold);
#    run-pyclone($config-yaml-file);
    pyclone-build-table($config-yaml-file, $tables-file-name);

}


## Step1. Prepare the mutation & cnv table using cbioportal datasets
sub prepare-tsv (@sampleID, $seg-file, $mutation-file, $tsv-fold) {
    my $sampleID = @sampleID.join(",");
    shell "Rscript ./bin/prepare_input.R $sampleID $tsv-fold $seg-file $mutation-file";
    
    my %sample-info;
    for @sampleID -> $sampleID {
        %sample-info{$sampleID}<tsv-file> = $tsv-fold ~ $sampleID ~ ".tsv";
    }
    return %sample-info;
}


## Step2. Infer mutation cluster using PyClone 

## Preparing the mutation yaml
sub build-mutations-file ($in-file, $out-file, $prior) {
#    "PyClone build_mutations_file --in_file tsv/$tsv-file --out_file $yaml-fold/$yaml-file --prior total_copy_number";
    shell "PyClone build_mutations_file --in_file $in-file --out_file $out-file --prior $prior";
}

sub prepare-sample-mutation-yaml ($sampleID, $tsv-file, $yaml-fold) {
    my $yaml-file-name = "$sampleID" ~ ".yaml";
    my $out-file = "$yaml-fold/$yaml-file-name";
    build-mutations-file($tsv-file, $out-file, "total_copy_number");
    return $yaml-fold ~ $sampleID ~ ".yaml";
}


## Preparing PyClone config.yaml
sub prepare-pyclone-config (%sample-info, $config-yaml-temp, $config-yaml-file, $workfold) {
    my %pyclonal-config = load-yaml($config-yaml-temp.IO.slurp);
    %pyclonal-config<samples> = {};
    %pyclonal-config<working_dir> = $workfold;
    for %sample-info.kv -> $sampleID, %info {
        %pyclonal-config<samples>{$sampleID} = {
            # TODO: The tumour content & error rate estimation
            "mutations_file" => "%info<yaml-file>",
            "tumour_content" => {value => 1.0},
            "error_rate" => 0.001
        };
    }

    $config-yaml-file.IO.spurt(save-yaml(%pyclonal-config));
}


## Run Pyclone
sub run-pyclone ($config-yaml-file) {
    shell "PyClone run_analysis --config_file $config-yaml-file";
}

## Build loci tables
sub pyclone-build-table ($config-yaml-file, $tables-file-name) {
    shell "PyClone build_table --config_file $config-yaml-file --out_file $tables-file-name --table_type loci";
}
