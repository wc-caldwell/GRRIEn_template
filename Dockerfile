FROM ubuntu:20.04 as builder

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV TZ US/Pacific
ARG DEBIAN_FRONTEND=noninteractive

RUN set -ex \
 && apt-get update \
 && apt-get install -y \
    cmake \
    cython3 \
    gfortran \
    git \
    libfftw3-dev \
    libgdal-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libopencv-dev \
    ninja-build \
    python3-gdal \
    python3-h5py \
    python3-numpy \
    python3-scipy \
 && echo done

# copy repo
COPY . /opt/isce2/src/isce2

# build ISCE
RUN set -ex \
 && cd /opt/isce2/src/isce2 \
 && mkdir build && cd build \
 && cmake .. \
        -DPYTHON_MODULE_DIR="$(python3 -c 'import site; print(site.getsitepackages()[-1])')" \
        -DCMAKE_INSTALL_PREFIX=install \
 && make -j8 install \
 && cpack -G DEB \
 && cp isce*.deb /tmp/

FROM ubuntu:20.04

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV TZ US/Pacific
ARG DEBIAN_FRONTEND=noninteractive

RUN set -ex \
 && apt-get update \
 && apt-get install -y \
    libfftw3-3 \
    libgdal26 \
    libhdf4-0 \
    libhdf5-103 \
    libopencv-core4.2 \
    libopencv-highgui4.2 \
    libopencv-imgproc4.2 \
    python3-gdal \
    python3-h5py \
    python3-numpy \
    python3-scipy \
 && echo done

# install ISCE from DEB
COPY --from=builder /tmp/isce*.deb /tmp/isce2.deb

RUN dpkg -i /tmp/isce2.deb

RUN ln -s /usr/lib/python3.8/dist-packages/isce2 /usr/lib/python3.8/dist-packages/isce

# Stage 2: Final image - Install ISCE2, Miniconda, and MintPy
# Start from a base image that includes Conda/Mambaforge for easier management
FROM condaforge/mambaforge:latest AS final_conda

# Install ISCE2's system dependencies (the ones that aren't Python packages)
# Note: You'll still need ISCE2's runtime system dependencies like libfftw3-3, etc.
# These might be slightly different versions or names in conda-forge.
RUN set -ex \
 && apt-get update && apt-get install -y --no-install-recommends \
    libfftw3-3 \
    libgdal26 \
    libhdf4-0 \
    libhdf5-103 \
    libopencv-core4.2 \
    libopencv-highgui4.2 \
    libopencv-imgproc4.2 \
    # Potentially other ISCE2 system deps that aren't part of conda-forge ISCE2
 && rm -rf /var/lib/apt/lists/* \
 && echo "System dependencies for ISCE2 installed."

# Install ISCE from DEB (compiled in the builder stage)
COPY --from=builder /tmp/isce*.deb /tmp/isce2.deb
RUN dpkg -i /tmp/isce2.deb && rm /tmp/isce2.deb

# Create symlink for ISCE2
RUN ln -s /usr/lib/python3.8/dist-packages/isce2 /usr/lib/python3.8/dist-packages/isce

# Create a Conda environment for MintPy and other tools
# It's highly recommended to use an environment.yml file for this.
COPY environment.yml /tmp/environment.yml
RUN mamba env update -n base -f /tmp/environment.yml && \
    mamba clean --all -f -y && \
    rm -rf /tmp/environment.yml

# Set environment variables for ISCE2 (if not already handled by Conda or installation)
# Ensure the ISCE2 path is discoverable.
ENV ISCE_HOME=/usr/lib/python3.8/dist-packages/isce2 
ENV PATH=$ISCE_HOME/bin:$PATH
ENV PYTHONPATH=$ISCE_HOME/lib:$PYTHONPATH

# Set working directory
WORKDIR /app
EXPOSE 8888
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--allow-root", "--ip=0.0.0.0"]