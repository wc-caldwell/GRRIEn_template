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

# --- CHANGE STARTS HERE ---
# Instead of COPY ., clone the ISCE2 repository directly
WORKDIR /opt/isce2/src/isce2
RUN git clone https://github.com/isce-framework/isce2.git .
# --- CHANGE ENDS HERE ---

# build ISCE
# No change needed here, as the source is now in /opt/isce2/src/isce2
RUN set -ex \
 && cd /opt/isce2/src/isce2 \
 && mkdir build && cd build \
 && cmake .. \
        -DPYTHON_MODULE_DIR="$(python3 -c 'import site; print(site.getsitepackages()[-1])')" \
        -DCMAKE_INSTALL_PREFIX=install \
 && make -j8 install \
 && cpack -G DEB \
 && cp isce*.deb /tmp/

# --- (Rest of your Dockerfile, including the final stage with MintPy, unchanged) ---

# Stage 2: Final image - Install ISCE2 and add MintPy
FROM ubuntu:20.04

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV TZ US/Pacific
ARG DEBIAN_FRONTEND=noninteractive

# Install core runtime dependencies for ISCE2 + system dependencies for MintPy
RUN set -ex \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    libfftw3-3 \
    libgdal26 \
    libhdf4-0 \
    libhdf5-103 \
    libopencv-core4.2 \
    libopencv-highgui4.2 \
    libopencv-imgproc4.2 \
    python3-pip \
    python3-setuptools \
    libnetcdf-dev \
    python3-tk \
 && rm -rf /var/lib/apt/lists/* \
 && echo done

# install ISCE from DEB
COPY --from=builder /tmp/isce*.deb /tmp/isce2.deb
RUN dpkg -i /tmp/isce2.deb && rm /tmp/isce2.deb

RUN ln -s /usr/lib/python3.8/dist-packages/isce2 /usr/lib/python3.8/dist-packages/isce

# Install MintPy and its core Python dependencies using pip
RUN set -ex \
 && pip3 install --no-cache-dir \
    mintpy \
    jupyter \
    notebook \
    dask \
 && echo done

WORKDIR /app
EXPOSE 8888
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--allow-root", "--ip=0.0.0.0"]