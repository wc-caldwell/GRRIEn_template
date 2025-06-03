# Use continuumio/miniconda3 as a parent image
FROM continuumio/miniconda3

# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Switch to root to install system packages
USER root

# Install system dependencies & common tools for development
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    git \
    openssh-client \
    # For VS Code features like port forwarding, git integration
    gnupg \
    lsb-release \
    # Dependencies for ISCE2
    build-essential \
    gfortran \
    libgdal-dev \
    gdal-bin \
    cmake \
    scons \
    libfftw3-dev \
    libhdf5-dev \
    libmotif-dev \
    libx11-dev \
    libxt-dev \
    libxm4 \
    cython3 \
    libglu1-mesa-dev \
    freeglut3-dev \
    mesa-common-dev \
    # Clean up apt cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for VS Code and general work
# You can change 'vscode' to your preferred username
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add to sudo group (optional, but often useful)
    && apt-get update && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create and configure the Conda environment
ENV CONDA_ENV_NAME insar
# Run conda operations as the user who will own the environment
# but first ensure /opt/conda is writable by the new user or a group they are in.
# Or, better, run conda create as root, then chown. For simplicity here:
RUN /opt/conda/bin/conda create -n $CONDA_ENV_NAME python=3.10 -y

# Set the default shell to bash and activate the conda environment for subsequent RUN, CMD, ENTRYPOINT
SHELL ["/opt/conda/bin/conda", "run", "-n", "$CONDA_ENV_NAME", "/bin/bash", "-c"]

# Install common Python packages
RUN conda install -c conda-forge --yes \
    numpy \
    scipy \
    matplotlib \
    h5py \
    gdal \
    cython \
    requests \
    pyyaml \
    lxml \
    setuptools \
    wheel \
    pip \
    && conda clean -tipy

# Install ISCE2
ENV CONDA_PREFIX /opt/conda/envs/$CONDA_ENV_NAME
RUN mkdir -p /usr/local/src/isce2 && \
    # Temporarily switch to root for installation into system-like paths if necessary, or ensure user has rights
    # For ISCE2, installing into the conda env prefix is usually fine
    # chown $USERNAME:$USERNAME -R /usr/local/src/isce2 # If creating as root and want user to own source
    # USER $USERNAME # If you want the build to run as the user
    git clone https://github.com/isce-framework/isce2.git /usr/local/src/isce2 && \
    cd /usr/local/src/isce2 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
             -DPYTHON_EXECUTABLE=$CONDA_PREFIX/bin/python \
             -DPYTHON_INCLUDE_DIR=$CONDA_PREFIX/include/python3.9 \
             -DPYTHON_LIBRARY=$CONDA_PREFIX/lib/libpython3.9.so && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /usr/local/src/isce2
    # USER root # Switch back if needed for subsequent root operations, then back to user

# Set ISCE_HOME and update PYTHONPATH for ISCE2
ENV ISCE_HOME $CONDA_PREFIX/isce
ENV PYTHONPATH $ISCE_HOME/applications:$ISCE_HOME/components:$PYTHONPATH
ENV PATH $ISCE_HOME/bin:$PATH

# Make ISCE environment settings persistent for interactive sessions within the conda env
RUN echo ". $ISCE_HOME/isce_env.sh" >> $CONDA_PREFIX/etc/conda/activate.d/isce_env.sh && \
    echo "unset ISCE_HOME PYTHONPATH" >> $CONDA_PREFIX/etc/conda/deactivate.d/isce_env.sh

# Install MintPy
RUN pip install --no-cache-dir git+https://github.com/insarlab/MintPy.git

# Install PyAPS
RUN pip install --no-cache-dir PyAPS

# Switch to the non-root user for VS Code
USER $USERNAME

# Set working directory for the user
WORKDIR /home/$USERNAME/workspace

# Reminder (this RUN command will execute as $USERNAME)
RUN echo "Successfully built ISCE2 and MintPy environment '$CONDA_ENV_NAME'." && \
    echo "The conda environment '$CONDA_ENV_NAME' should be active by default."

# The CMD is usually overridden by devcontainer.json, but good to have a default
CMD ["/bin/bash"]
