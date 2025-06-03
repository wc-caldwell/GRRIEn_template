#!/bin/bash --login
# setup.sh – initialize GRRIEn reproducible environment
# -------------------------------------------

# Strict error handling after conda is ready
set +euo pipefail

# 1. Source Conda (needed in Docker & bash --login)
source /opt/conda/etc/profile.d/conda.sh

# 2. Activate the Conda environment (created in Dockerfile)
conda activate test

# Enable strict mode now that we're in a known environment
set -euo pipefail

# 3. Create a temporary working data folder on user's machine
mkdir -p ./temp_data
echo "[GRRIEn Setup] Created temp_data directory at ./temp_data"

# 4. Optional: install any Python packages not handled by Conda
# pip install -r ./requirements.txt

# 5. Confirm environment
echo "[GRRIEn Setup] Conda environment 'test' is active"
conda list

# 6. Export software and environment info (for provenance tracking)
echo "[GRRIEn Setup] Exporting environment specs..."
conda env export > ./temp_data/env_export.yml
pip freeze > ./temp_data/pip_freeze.txt
echo "[GRRIEn Setup] Environment specs saved to temp_data/"

# 7. Ready for running pipeline
echo "[GRRIEn Setup] Environment initialized. Ready to run pipeline scripts."
echo "Next step: python code/run.py or bash code/pipeline.sh"

# Optional: run initial command or launch shell
# exec python code/run.py
