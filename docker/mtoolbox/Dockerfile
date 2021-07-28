FROM ubuntu:20.04

LABEL maintainer="Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu> \ 
Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update \
   &&  apt-get -y install --no-install-recommends \
   zip \
   unzip \
   apt-utils \
   autotools-dev \
   automake \
   build-essential \
   libhts-dev \
   libtool \
   libpcre++-dev \
   llvm-dev \
   pkg-config \
   uuid-dev \
   zlib1g-dev \
   wget \
   openjdk-8-jre-headless \
   git \
   libncurses5-dev \
   libncursesw5-dev \
   ca-certificates \
   &&  rm -rf /var/lib/apt/lists/* 
   
WORKDIR /src/ 
RUN wget https://github.com/mitoNGS/MToolBox/archive/b52269e98c694d3e4ba25eb80f27b74b48985ddb.zip \
    && unzip b52269e98c694d3e4ba25eb80f27b74b48985ddb.zip \
    && mv MToolBox-b52269e98c694d3e4ba25eb80f27b74b48985ddb MToolBox \
    && chmod 777 -R /src/MToolBox/

WORKDIR /src/MToolBox/
RUN ./install.sh \
    -g 2021-03-08 \
    -a 2-4.2.0 \
    && rm -r ./gmapdb \
    && rm -r ./genome_fasta \    
    && rm -r ./test \
    && rm test_rCRS_config.sh 

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/src/MToolBox/MToolBox/