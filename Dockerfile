# Base image with conda + pip support
FROM continuumio/miniconda3

# Install any system‐level libraries MintPy needs (e.g. GDAL)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libgdal-dev gdal-bin \
      && apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch to /app (where your repo will be mounted)
WORKDIR /app

# Copy only the environment spec
COPY environment.yml .

# Create a conda env called "grrien" with MintPy
RUN conda env create -n grrien -f environment.yml && \
    conda clean -a

# Ensure subsequent commands use that env
SHELL ["conda", "run", "-n", "grrien", "/bin/bash", "-c"]

# Copy the rest of your repo (including setup.sh, code/, etc.)
COPY . .

# When the container launches, run setup.sh
CMD ["bash", "setup.sh"]
