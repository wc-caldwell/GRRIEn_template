# Use a Miniconda‐based image so we have conda + pip out-of-the-box
FROM continuumio/miniconda3

# Install all OS-level build tools for ISCE2, GDAL, etc.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git wget curl \
      build-essential cmake gfortran scons \
      libfftw3-dev libboost-all-dev \
      libgdal-dev gdal-bin \
      libpng-dev libjpeg-dev libxml2-dev libxm4 \
      bzip2 ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 1) Build and install ISCE2 from source into /opt/isce2
WORKDIR /opt
RUN git clone https://github.com/isce-framework/isce2.git && \
    cd isce2 && \
    scons install

# Expose ISCE2 to both shell and Python
ENV PATH="/opt/isce2/applications:${PATH}"
ENV PYTHONPATH="/opt/isce2:${PYTHONPATH}"

# 2) Switch back to /app and create the conda environment
WORKDIR /app
COPY env.yml .
RUN conda env create -n grrien -f env.yml && \
    conda clean -a

# All subsequent RUN/CMD will use the 'grrien' env by default
SHELL ["conda", "run", "-n", "grrien", "/bin/bash", "-c"]

# 3) Copy everything else (including setup.sh, code/, etc.)
COPY . .

# 4) When container starts, run setup.sh
CMD ["bash", "setup.sh"]
