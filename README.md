# **CGPS-MLST-Flow**  - A nextflow wrapper for running CGPS-MLST

CGPS-MLST-Flow is a Nextflow wrapper for [CGPS (cg)MLST](https://github.com/pathogenwatch-oss/mlst). 

--------------------------------------------------------------------------------

## Usage

To run the pipeline, provide the following arguments directly via command line or in `params.yaml` file:
- `indexed_scheme_dir`: Path to the directory with indexed (cg)MLST schemes in PathogenWatch format.
- `scheme_name`: `shortname` of the (cg)MLST scheme to be used (should match `shortname` defined the indexed schemes).
- `input_dir`: Path to the directory with FASTA files for (cg)MLST analysis.
- `publish_dir`: Path to the output directory where results will be stored.

Example execution with parameters defined on the command line:
```bash
nextflow run cpgs-mlst-flow.nf \
    -profile singularity \
    --indexed_scheme_dir /path/to/indexed_schemes \
    --scheme_name mycobacterium_1 \
    --input_dir /path/to/input_fastas \
    --publish_dir /path/to/output_directory
```

Example execution with parameters defined in the `params.yaml`:
```bash
nextflow run cpgs-mlst-flow.nf \
    -profile singularity \
    -params-file params.yaml
```

--------------------------------------------------------------------------------

## Output

The pipeline will output two sub-directories in defined `--publish_dir`: `jsons` and `profile_summary`.

1. `jsons` directory stores per sample `.json` files generated during (cg)MLST typing.

2. `profile_summary` directory stores combined summary tables generated from all JSON files: 
   - `*_info.tsv` contains general information for each sample, including the sequence type (ST) and details about the (cg)MLST scheme used.
   - `*_profile.tsv` contains the (cg)MLST allele profiles for all samples, in which `0`'s indicate missing loci, known alleles are represented by their original numeric identifiers from the scheme, and novel alleles are represented by hash values.
   - `*_profile_hased.tsv` is similar to `_profile.tsv`, but **all** alleles (both known and novel) are represented by **hashes**.

--------------------------------------------------------------------------------

# Credits

Many thanks to Maximiliar Povill Driller and Lucas Florin for their extensive assistance in the development of this pipeline.

We thank the PathogenWatch team for developing and maintaining [CGPS (cg)MLST](https://github.com/pathogenwatch-oss/mlst) and [typing-databases](https://github.com/pathogenwatch-oss/typing-databases) tools. 

Special thanks to Corin Yets and Khalil Abu-Dahab for their support and guidance regarding the usage of CGPS (cg)MLST and typing-databases.

--------------------------------------------------------------------------------