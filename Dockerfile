FROM hub.bccvl.org.au/jupyter/base-notebook:0.9.4-14

USER root

# install RStudio and Shiny-Server
# && apt-get install -yq --no-install-recommends fonts-dejavu \
RUN apt-get update \
 && apt-get install -yq --no-install-recommends gdebi-core xz-utils \
 && VERSION=1.2.1335 \
 && curl -LO https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${VERSION}-amd64.deb \
 && gdebi -n rstudio-server-${VERSION}-amd64.deb \
 && rm rstudio-server-${VERSION}-amd64.deb \
 && VERSION=1.5.9.923 \
 && curl -LO https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${VERSION}-amd64.deb \
 && gdebi -n shiny-server-${VERSION}-amd64.deb \
 && rm shiny-server-${VERSION}-amd64.deb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# setup shiny bookmarks folder


# install Maxent
ENV MAXENT=/opt/maxent.jar \
    MAXENT_VERSION=3.4.1

# TODO: we reallly should install java just for this...
#       either build maxent.jar somehwere else and load it into here,
#       or build it inside conda env which will need java anyway
RUN apt-get update \
 && mkdir -p /usr/share/man/man1 \
 && apt-get install -yq --no-install-recommends openjdk-11-jdk-headless \
 && sed -i'' -e 's/^[^#].*/#\0/' /etc/java-11-openjdk/accessibility.properties \
 && curl -LO https://github.com/mrmaxent/Maxent/archive/${MAXENT_VERSION}.zip \
 && unzip ${MAXENT_VERSION}.zip \
 && rm ${MAXENT_VERSION}.zip \
 && cd Maxent-${MAXENT_VERSION} \
 && make distribution \
 && cp maxent.jar /opt \
 && cd .. \
 && rm -fr Maxent-${MAXENT_VERSION} \
 && apt-get clean \
 && rm -fr /var/lib/apt/lists/*


# RUN pip3 install --no-cache-dir jupyter-rsession-proxy==1.0b6
RUN pip3 install --no-cache-dir https://github.com/ausecocloud/jupyter-rsession-proxy/archive/58570cf2c3fb309446740672461a3cfdf6cdd197.zip

# Add start up scripts
COPY files/bin/ /usr/local/bin/
# Setup CRAN mirror
COPY files/Rprofile $HOME/.Rprofile
RUN chown $NB_USER:$NB_GID $HOME/.Rprofile

USER $NB_USER

# R wants some lcoale settings
RUN echo '\nexport LANG=C.UTF-8' >> /home/$NB_USER/.bashrc

# Install R environment and some useful packages
# also add conda-forge channel to environment
RUN ${CONDA_DIR}/bin/conda create -c conda-forge --name r36 --yes \
      gcc_linux-64 \
      gdal \
      gfortran_linux-64 \
      gxx_linux-64 \
      jupyter_core \
      krb5 \
      libssh2 \
      nomkl \
      pkg-config \
      'r-base<3.7' \
      r-car \
      r-caret \
      r-data.table \
      r-devtools \
      r-dismo \
      r-dplyr \
      r-ggdendro \
      r-gridextra \
      r-hexbin \
      r-irkernel \
      r-jpeg \
      r-knitr \
      r-latticeExtra \
      r-mgcv \
      r-png \
      r-proc \
      r-proj4 \
      r-r.utils \
      r-raster \
      r-randomforest \
      r-rcurl \
      r-reshape \
      r-rgdal \
      r-rgeos \
      r-sf \
      r-sp \
      r-shiny \
      r-slam \
      r-sp \
      r-sparsem \
      r-tm \
      r-units \
      r-v8 \
      r-xml2 \
      r-zoo \
 && ${CONDA_DIR}/bin/conda clean -tipsy \
 && rm -fr /home/$NB_USER/{.cache,.conda,.npm}

# configure conda env
#    We need bash shell, otherwise condas activate script does not work properly
SHELL ["/bin/bash", "-c"]
RUN eval "$(conda shell.bash hook)" \
 && conda activate r36 \
 && conda config --env --add channels conda-forge


# TODO: some dependencies of these are probably available as conda pkgs.
# Install some ecology R packages
RUN eval "$(conda shell.bash hook)" \
 && conda activate r36 \
 && Rscript --no-restore --no-save -e 'install.packages( \
      c("biomod2", "ALA4R", "rgbif", "goeveg" \
        ) \
    )' \
 && Rscript --no-restore --no-save -e 'library(devtools); devtools::install_github("ternaustralia/ausplotsR", build_vignettes=TRUE)' \
 && Rscript --no-restore --no-save -e 'install.packages(c("googlesheets", "MuMIn", "doBy", "doSNOW", "gamm4"))' \
 && Rscript --no-restore --no-save -e 'library(devtools); devtools::install_github("beckyfisher/FSSgam_package")'


ENV DEFAULT_KERNEL_NAME=conda-env-r36-r
