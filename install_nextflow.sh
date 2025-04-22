#!/bin/bash

# Script to set up Java and NextFlow environment on TACC
# Installs software to $WORK and prepares for running jobs from $SCRATCH
echo "=========================================================="
echo "Setting up Java and NextFlow environment on TACC"
echo "=========================================================="
echo "Creating directory structure in $WORK..."
mkdir -p $WORK/software/nextflow_env
mkdir -p $WORK/software/nextflow_env/bin
mkdir -p $WORK/software/nextflow_env/java

# SDKMAN Check and Install
if [ ! -d "$WORK/software/sdkman" ]; then
    echo "Installing SDKMAN to $WORK/software/sdkman..."
    export SDKMAN_DIR="$WORK/software/sdkman"
    curl -s https://get.sdkman.io | bash
    
    # Modify SDKMAN config to use $WORK for installations
    sed -i "s|sdkman_auto_answer=false|sdkman_auto_answer=true|g" $SDKMAN_DIR/etc/config
    sed -i "s|sdkman_auto_selfupdate=false|sdkman_auto_selfupdate=false|g" $SDKMAN_DIR/etc/config
fi

# Source SDKMAN
export SDKMAN_DIR="$WORK/software/sdkman"
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Java Check and Install
if ! sdk list java | grep -q "17.0.10-tem"; then
    echo "Installing Java 17.0.10-tem via SDKMAN..."
    sdk install java 17.0.10-tem
fi

sdk use java 17.0.10-tem
echo "Java version:"
java -version | grep version

# NextFlow Check and Install
if [ ! -f "$WORK/software/nextflow_env/bin/nextflow" ]; then
    echo "Installing NextFlow to $WORK/software/nextflow_env/bin..."
    cd $WORK/software/nextflow_env/bin
    curl -s https://get.nextflow.io | bash
    chmod +x nextflow
fi

# Add NextFlow to PATH for this session
export PATH=$WORK/software/nextflow_env/bin:$PATH
alias nextflow="$WORK/software/nextflow_env/bin/nextflow"
echo "NextFlow version:"
nextflow -version | grep version

# Ask user which pipeline(s) to install
echo ""
echo "Which NextFlow pipeline(s) would you like to install?"
echo "1) nf-core/mag"
echo "2) epi2me-labs/wf-metagenomics"
echo "3) Both pipelines"
echo "4) None (skip pipeline installation)"
echo ""
echo -n "Enter your choice [1-4]: "
read pipeline_choice

# Install selected pipeline(s)
cd $WORK/software/nextflow_env/
case $pipeline_choice in
    1)
        echo "Installing nf-core/mag pipeline..."
        nextflow pull nf-core/mag -r 3.4.0
        ;;
    2)
        echo "Installing epi2me/wf-metagenomic pipeline..."
        nextflow pull epi2me-labs/wf-metagenomics
        ;;
    3)
        echo "Installing both pipelines..."
        nextflow pull nf-core/mag -r 3.4.0
        nextflow pull epi2me-labs/wf-metagenomics
        ;;
    4)
        echo "Skipping pipeline installation."
        ;;
    *)
        echo "Invalid choice. Skipping pipeline installation."
        ;;
esac


# Create a setup script for environment initialization
cat > $WORK/software/nextflow_env/setup.sh << EOF
#!/bin/bash

# Initialize SDKMAN
export SDKMAN_DIR="$WORK/software/sdkman"
source "\$SDKMAN_DIR/bin/sdkman-init.sh"

# Use Java 17
sdk use java 17.0.10-tem

# Add NextFlow to PATH and make sure it's first in the PATH
export PATH=$WORK/software/nextflow_env/bin:\$PATH

# Create an alias to make sure we're using the right nextflow
alias nextflow="$WORK/software/nextflow_env/bin/nextflow"

echo "NextFlow environment initialized!"
echo "Java version: \$(java -version | grep version)"
echo "NextFlow version: \$(nextflow -version | grep version)"
echo "NextFlow pipelines: \$(nextflow list)"
echo "Software location: $WORK/software/nextflow_env"
echo "Job execution directory: \$SCRATCH/nextflow_runs"
EOF
chmod +x $WORK/software/nextflow_env/setup.sh

# Create a brief README with TACC best practices
cat > $WORK/software/nextflow_env/README.txt << EOF
TACC NextFlow Best Practices:

1. Always run NextFlow jobs from \$SCRATCH:
   cd \$SCRATCH/nextflow_runs
   mkdir my_analysis && cd my_analysis

2. Copy input data to \$SCRATCH before running:
   cp \$WORK/my_data/* \$SCRATCH/nextflow_runs/my_analysis/

3. Run NextFlow pipelines:
   nextflow run nf-core/mag -r 3.4.0 -work-dir \$PWD/work
   OR
   nextflow run epi2me/wf-metagenomic -work-dir \$PWD/work

4. After completion, copy important results back to \$WORK:
   cp -r results/ \$WORK/my_results/

5. Remember that files in \$SCRATCH not accessed for 10 days may be purged
EOF

echo "=========================================================="
echo "Setup complete!"
echo "To use this environment:"
echo "  source $WORK/software/nextflow_env/setup.sh"
echo ""
echo "NextFlow is installed in $WORK/software"
echo "See $WORK/software/nextflow_env/README.txt for TACC best practices"
echo "Remember to copy data to $SCRATCH and run jobs from $SCRATCH"
echo "=========================================================="
