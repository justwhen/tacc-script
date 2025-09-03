#!/bin/bash

# Script to install Oxford Nanopore's Dorado on TACC
# Installs to $WORK and sets up environment for GPU usage
echo "=========================================================="
echo "Installing Oxford Nanopore Dorado on TACC"
echo "=========================================================="

# Create directory structure
echo "Creating directory structure in $WORK..."
mkdir -p $WORK/software/dorado
mkdir -p $WORK/software/dorado/bin
mkdir -p $WORK/software/dorado/models

cd $WORK/software/dorado

# Determine architecture and download appropriate version
echo "Detecting system architecture..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    echo "Detected x86_64 architecture"
    DORADO_VERSION="0.8.0"  # Latest stable version as of early 2024
    DORADO_URL="https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-x64.tar.gz"
    DORADO_DIR="dorado-${DORADO_VERSION}-linux-x64"
else
    echo "Architecture $ARCH not supported for precompiled Dorado"
    echo "You may need to compile from source"
    exit 1
fi

# Download and extract Dorado
echo "Downloading Dorado ${DORADO_VERSION}..."
if [ ! -f "dorado-${DORADO_VERSION}-linux-x64.tar.gz" ]; then
    wget $DORADO_URL
    if [ $? -ne 0 ]; then
        echo "Download failed. Trying curl..."
        curl -L -o "dorado-${DORADO_VERSION}-linux-x64.tar.gz" $DORADO_URL
    fi
fi

echo "Extracting Dorado..."
tar -xzf "dorado-${DORADO_VERSION}-linux-x64.tar.gz"

# Move binaries and libraries to our directories
echo "Setting up Dorado binaries and libraries..."
cp -r ${DORADO_DIR}/bin/* $WORK/software/dorado/bin/
cp -r ${DORADO_DIR}/lib $WORK/software/dorado/
chmod +x $WORK/software/dorado/bin/*

# Test installation
echo "Testing Dorado installation..."
export PATH=$WORK/software/dorado/bin:$PATH
export LD_LIBRARY_PATH=$WORK/software/dorado/lib:$LD_LIBRARY_PATH

if $WORK/software/dorado/bin/dorado --version > /dev/null 2>&1; then
    echo "Dorado installed successfully!"
    $WORK/software/dorado/bin/dorado --version
else
    echo "Dorado installation may have issues. Check manually."
fi

# Models can be downloaded later using: dorado download --model <model_name>
echo "Models can be downloaded later as needed using:"
echo "  dorado download --model <model_name>"

# Create setup script
cat > $WORK/software/dorado/setup.sh << 'EOF'
#!/bin/bash

# Add Dorado to PATH and set library path
export PATH=$WORK/software/dorado/bin:$PATH
export LD_LIBRARY_PATH=$WORK/software/dorado/lib:$LD_LIBRARY_PATH

# Set model directory
export DORADO_MODELS_DIR=$WORK/software/dorado/models

echo "Dorado environment initialized!"
echo "Dorado version: $(dorado --version)"
echo "Dorado location: $WORK/software/dorado"
echo "Models location: $DORADO_MODELS_DIR"
echo ""
echo "Available models:"
ls -la $DORADO_MODELS_DIR/ 2>/dev/null || echo "No models downloaded yet"
EOF

chmod +x $WORK/software/dorado/setup.sh

# Create SLURM job template for GPU usage
cat > $WORK/software/dorado/dorado_gpu_template.slurm << 'EOF'
#!/bin/bash
#SBATCH -J dorado_basecall
#SBATCH -o dorado_%j.out
#SBATCH -e dorado_%j.err
#SBATCH -p gpu-a100
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH -t 02:00:00
#SBATCH --gres=gpu:1

# Initialize Dorado environment
source $WORK/software/dorado/setup.sh

# Change to your working directory (should be in $SCRATCH)
cd $SCRATCH/dorado_runs

# Example Dorado basecalling command (modify as needed)
# For DNA:
# dorado basecaller dna_r10.4.1_e8.2_400bps_hac@v5.0.0 /path/to/pod5_files/ > basecalls.bam

# For RNA:
# dorado basecaller rna004_130bps_hac@v5.0.0 /path/to/pod5_files/ > basecalls.bam

# Add your specific Dorado command here:
echo "Add your Dorado basecalling command here"
echo "Example: dorado basecaller <model> <pod5_directory> > output.bam"
EOF

# Create README with usage instructions
cat > $WORK/software/dorado/README.txt << 'EOF'
TACC Dorado Usage Guide:

1. Initialize the environment:
   source $WORK/software/dorado/setup.sh

2. For GPU basecalling, use the GPU nodes:
   - Copy the template: cp $WORK/software/dorado/dorado_gpu_template.slurm $SCRATCH/
   - Edit the template to add your specific command
   - Submit: sbatch dorado_gpu_template.slurm

3. Basic Dorado commands:
   - List available models: dorado download --list
   - Download a model: dorado download --model <model_name>
   - Basecall: dorado basecaller <model> <pod5_dir> > output.bam
   - Demultiplex: dorado demux --kit-name <kit> <input.bam> --output-dir demuxed/

4. Performance tips:
   - Use GPU nodes for basecalling (much faster)
   - Keep POD5 files on local storage during processing
   - Use appropriate batch size for your GPU memory

5. Common models:
   - DNA HAC: dna_r10.4.1_e8.2_400bps_hac@v5.0.0
   - DNA SUP: dna_r10.4.1_e8.2_400bps_sup@v5.0.0  
   - RNA HAC: rna004_130bps_hac@v5.0.0
   - RNA SUP: rna004_130bps_sup@v5.0.0

Remember: Always run jobs from $SCRATCH and copy results back to $WORK!
EOF

echo "=========================================================="
echo "Dorado installation complete!"
echo ""
echo "To use Dorado:"
echo "  source $WORK/software/dorado/setup.sh"
echo ""
echo "For GPU basecalling jobs:"
echo "  cp $WORK/software/dorado/dorado_gpu_template.slurm $SCRATCH/"
echo "  # Edit the template with your specific command"
echo "  sbatch dorado_gpu_template.slurm"
echo ""
echo "See $WORK/software/dorado/README.txt for detailed usage instructions"
echo "=========================================================="