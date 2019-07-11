FROM hub.bccvl.org.au/jupyter/base-notebook:0.9.4-11

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

RUN apt-get update \
 && mkdir -p /usr/share/man/man1 \
 && apt-get install -yq --no-install-recommends libnode-dev \
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
RUN pip3 install --no-cache-dir https://github.com/ausecocloud/jupyter-rsession-proxy/archive/ce3960642b6a26e1669a57dfa15cb0a43e7af733.zip

# Setup CRAN mirror
COPY Rprofile $HOME/.Rprofile
RUN chown $NB_USER:$NB_GID $HOME/.Rprofile

USER $NB_USER

# R wants some lcoale settings
RUN echo '\nexport LANG=C.UTF-8' >> /home/$NB_USER/.bashrc

# Install R environment and some useful packages
# TODO: pin R to latest 3.5
RUN ${CONDA_DIR}/bin/conda create --name r35 --yes \
      gcc_linux-64 \
      gdal \
      gfortran_linux-64 \
      gxx_linux-64 \
      jupyter_core \
      krb5 \
      libssh2 \
      nomkl \
      pkg-config \
      'r-base<3.6' \
      r-car \
      r-caret \
      r-data.table \
      r-devtools \
      r-dplyr \
      r-gridextra \
      r-hexbin \
      r-irkernel \
      r-jpeg \
      r-latticeExtra \
      r-mgcv \
      r-png \
      r-proc \
      r-r.utils \
      r-raster \
      r-randomforest \
      r-rcurl \
      r-reshape \
      r-sf \
      r-shiny \
      r-slam \
      r-sp \
      r-sparsem \
      r-tm \
      r-xml2 \
      r-zoo \
 && ${CONDA_DIR}/bin/conda clean -tipsy \
 && rm -fr /home/$NB_USER/{.cache,.conda,.npm}

# need this for some R packages... conda R defaults to /bin/gtar :(
ENV TAR=/bin/tar

# Install some ecology R packages
#    We need bash shell, otherwise condas activate script does not work properly
#    Do I need PKG_CFLAGS, PKG_CXXFLAGS? (C/C++ compile options)
#    PKG_CPPFLAGS ... C preprocessor options. (used by C++ as well?)
SHELL ["/bin/bash", "-c"]
RUN source activate r35 \
 && export PKG_LIBS="-L ${CONDA_PREFIX}/lib" \
 && export PKG_CPPFLAGS="-I ${CONDA_PREFIX}/include" \
 && Rscript --no-restore --no-save -e 'install.packages( \
      c("biomod2", "dismo", "rgdal", "rgeos", "proj4", \
        "ggdendro" ) \
    )' \
 && Rscript --no-restore --no-save -e 'install.packages("V8", configure.vars="INCLUDE_DIR=/usr/include LIB_DIR=/usr/lib")' \
 && Rscript --no-restore --no-save -e 'install.packages( \
      c("ALA4R", "rgbif") \
    )' \
 && Rscript --no-restore --no-save -e 'library(devtools); devtools::install_github("ternaustralia/ausplotsR", build_vignettes=TRUE)' \
 && Rscript --no-restore --no-save -e 'install.packages(c("googlesheets", "MuMIn", "doBy", "doSNOW", "gamm4"))' \
 && Rscript --no-restore --no-save -e 'library(devtools); devtools::install_github("beckyfisher/FSSgam_package")'

ENV DEFAULT_KERNEL_NAME=conda_r_r35
