FROM hub.bccvl.org.au/jupyter/base-notebook:0.9.4-1

USER root

# install RStudio
# && apt-get install -yq --no-install-recommends fonts-dejavu \
RUN apt-get update \
 && apt-get install -yq --no-install-recommends gdebi-core \
 && VERSION=1.1.456 \
 && curl -LO https://download2.rstudio.org/rstudio-server-stretch-${VERSION}-amd64.deb \
 && gdebi -n rstudio-server-stretch-${VERSION}-amd64.deb \
 && rm rstudio-server-stretch-${VERSION}-amd64.deb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# install Maxent
ENV MAXENT=/opt/maxent.jar \
    MAXENT_VERSION=3.4.1

RUN apt-get update \
 && mkdir -p /usr/share/man/man1 \
 && apt-get install -yq --no-install-recommends libv8-3.14-dev \
 && apt-get install -yq --no-install-recommends openjdk-8-jdk-headless \
 && sed -i'' -e 's/^[^#].*/#\0/' /etc/java-8-openjdk/accessibility.properties \
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

# nbrsessionproxy ... nb and lab extension
RUN cd /tmp \
 && REV=44162f6ac5c0a3ba614cdde85a5543dc5c15e650 \
 && pip3 install --no-cache-dir https://github.com/ausecocloud/nbrsessionproxy/archive/${REV}.zip \
 && jupyter serverextension enable  --py --sys-prefix nbrsessionproxy \
 && jupyter nbextension     install --py --sys-prefix nbrsessionproxy \
 && jupyter nbextension     enable  --py --sys-prefix nbrsessionproxy \
 && curl -LO https://github.com/ausecocloud/nbrsessionproxy/archive/${REV}.zip \
 && unzip ${REV}.zip \
 && cd nbrsessionproxy-${REV}/jupyterlab-rsessionproxy \
 && jlpm install \
 && jlpm run build \
 && jlpm pack \
 && NODE_OPTIONS=--max-old-space-size=4096 jupyter labextension install jupyterlab-rsessionproxy-extension-*.tgz \
 && cd /tmp \
 && rm -fr nbrsessionproxy-${REV} \
 && rm -fr ${REV}.zip \
 && cd \
 && rm -fr /usr/local/share/jupyter/lab/staging \
 && rm -fr /usr/local/share/.cache \
 && rm -fr ~/{.cache,.conda,.npm} \
 && chown -R $NB_USER:$NB_GID $HOME

# Setup CRAN mirror
COPY Rprofile $HOME/.Rprofile
RUN chown $NB_USER:$NB_GID $HOME/.Rprofile

USER $NB_USER

# Install R environment and some useful packages
# TODO: pin R to latest 3.5
RUN conda create --name r35 --yes \
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
      r-shiny \
      r-slam \
      r-sp \
      r-sparsem \
      r-tm \
      r-xml2 \
      r-zoo \
 && conda clean -tipsy \
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
 && Rscript --no-restore --no-save -e 'library(devtools); devtools::install_github("GregGuerin/ausplotsR", build_vignettes=TRUE)'

ENV DEFAULT_KERNEL_NAME=conda_r_r35
