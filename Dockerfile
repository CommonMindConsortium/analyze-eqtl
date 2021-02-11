# versioned base image
FROM rocker/tidyverse:4.0.3

# -- metadata --
LABEL maintainer="Kelsey Montgomery <kelsey.montgomery@sagebase.org>"
LABEL base_image="rocker/tidyverse:4.0.3"
LABEL about.summary="Docker image to run synapseclient with reticulate"
LABEL about.license="SPDX:Apache-2.0"

# WE EXPORT PATH FOR CONDA
ENV PATH="/opt/conda/bin:${PATH}"

# UPDATE A SERIES OF PACKAGES
RUN apt-get update --fix-missing \
 && apt-get install -y \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev

# INSTALL PYTHON 3 AND ANACONDA
RUN apt-get install -y \
    python3-pip \
    python3-dev \
 && pip3 install virtualenv \
 && wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh -O ~/anaconda.sh \
 && /bin/bash ~/anaconda.sh -b -p /opt/conda && rm ~/anaconda.sh \
 && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
 && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# ACTIVATE CONDA ENVIRONMENT
RUN echo "source activate base" > ~/.bashrc

# INSTALL SYNAPSECLIENT
RUN python3 -m venv "/opt/conda/bin" \
 && pip install synapseclient

# WRITE RETICULATE_PYTHON VARIABLE IN .Renviron
RUN echo "RETICULATE_PYTHON = '/opt/conda/bin'" > .Renviron

# INSTALL R PACKAGE reticulate
RUN R -e "install.packages('reticulate')"

# SCRIPT WOULD BE RUN AS:
# RUN Rscript ./build.R

