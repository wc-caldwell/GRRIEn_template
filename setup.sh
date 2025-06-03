#!/bin/bash --login
# setup.sh – initialize MintPy environment, create temp_data

# 1) Don’t fail until conda is ready
set +euo pipefail

# 2) Source & activate the "grrien" env
source /opt/conda/etc/profile.d/conda.sh
conda activate grrien

# 3) Enable strict mode now that conda is active
set -euo pipefail

# 4) Create a local temp_data folder (host‐mounted under /app)
mkdir -p /app/temp_data
echo "[Setup] Created /app/temp_data"

# 5) (Optional) export environment specs for provenance
echo "[Setup] Exporting environment spec"
conda list > /app/temp_data/conda_list.txt
pip freeze > /app/temp_data/pip_freeze.txt

echo "[Setup] MintPy environment ready. You can now run:"
echo "    mintpy smallbaselineApp.py <path_to_hyp3_stack.h5> --dofile config.txt"