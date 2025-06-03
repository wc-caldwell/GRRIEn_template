# Use official Miniconda base image
FROM continuumio/miniconda3

# Set working directory inside the container
WORKDIR /.

# Copy environment file and install Conda environment
COPY environment.yml .
RUN conda env create -n test -f environment.yml && \
    conda clean -a

# Set default shell to use the Conda env
SHELL ["conda", "run", "-n", "test", "/bin/bash", "-c"]

# Copy the rest of your repo (including setup.sh, code/, etc.)
COPY . .

# Run setup.sh when the container starts (optional)
CMD ["bash", "setup.sh"]