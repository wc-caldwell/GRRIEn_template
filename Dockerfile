# Use Miniconda base image for conda + pip
FROM continuumio/miniconda3

# Switch to /app and create the 'insar' conda environment
WORKDIR /app
COPY env.yml .
RUN conda env create -n insar -f env.yml && \
    conda clean -a

# Ensure all subsequent commands run inside 'insar' env
SHELL ["conda", "run", "-n", "insar", "/bin/bash", "-c"]

# Copy in the rest of the repository (including setup.sh, code/, etc.)
COPY . .

# Default to running setup.sh when the container starts
CMD ["bash", "setup.sh"]
