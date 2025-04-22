# tacc-script

A shell script for setting up [NextFlow](https://nextflow.io/docs/latest/index.html) and Java environments on TACC HPC systems following best practices for file system usage.

## Features
- Installs NextFlow in your $WORK directory (following TACC recommendations)
- Installs Java 17.0.10-tem via SDKMAN
- Option to install [nf-core/mag](https://nf-co.re/mag/3.4.0/) and/or [epi2me-labs/wf-metagenomics](https://github.com/epi2me-labs/wf-metagenomics) pipelines
- Generates initialization script for easy environment setup in future sessions
- Follows TACC's I/O and file system usage best practices

## Usage
1. Save the script to $HOME on TACC
2. Open idev and make it executable: `chmod +x install_nextflow.sh`
3. Run the script: `./install_nextflow.sh`
4. For future sessions, initialize the environment with:
   ```bash
   source $WORK/software/nextflow_env/setup.sh```