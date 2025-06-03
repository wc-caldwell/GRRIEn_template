#!/bin/bash --login
# setup.sh – initialize GRRIEn reproducible environment

# 0) Relax strict mode until conda is loaded
set +euo pipefail

# 1) Source conda’s initialization script
source /opt/conda/etc/profile.d/conda.sh

# 2) Activate the 'grrien' environment
conda activate grrien

# 3) Enable strict mode from here onward
set -euo pipefail

# 4) Create a temporary working folder on the host (mounted into /app)
mkdir -p /app/temp_data
echo "[GRRIEn Setup] Created temp_data at /app/temp_data"

# 5) (Optional) Install any pip-only deps not covered by environment.yml
# pip install -r /app/requirements.txt

# 6) Confirm & export environment for provenance
echo "[GRRIEn Setup] Conda env 'grrien' is active"
conda list
echo "[GRRIEn Setup] Exporting environment spec to temp_data/"
conda env export > /app/temp_data/env_export.yml
pip freeze > /app/temp_data/pip_freeze.txt

# 7) Ready to run your pipeline. You can now call:
#       python code/run.py
#    or any other script under code/
echo "[GRRIEn Setup] Environment initialized. You can now run your pipeline scripts."