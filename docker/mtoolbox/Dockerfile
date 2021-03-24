FROM ubuntu:18.04 AS stage_1

LABEL maintainer="Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install --no-install-recommends -y \
        zip \
        unzip \
        wget \
        openjdk-8-jre-headless \
        apt-utils \
        autotools-dev \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libncursesw5-dev \
    &&  rm -rf /var/lib/apt/lists/* 

WORKDIR /src/ 
RUN wget https://github.com/mitoNGS/MToolBox/archive/refs/tags/v1.2.1.tar.gz \
    && tar -xf v1.2.1.tar.gz \
    && chmod 777 -R /src/MToolBox-1.2.1/
WORKDIR /src/MToolBox-1.2.1/
RUN ./install.sh \
    -g 2018-07-04 \
    -a 2-4.2.0 \
    -z 1.2.8 \
    -m 3.8.31 \
    -s 1.3 \
    -k 15 \
    && rm -r ./gmapdb \
    && rm -r ./genome_fasta \
    && rm -r ./test \
    && rm test_rCRS_config.sh 

RUN apt-get update &&  apt-get -y upgrade \
    && apt-get install -y python2.7

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/src/MToolBox/MToolBox/
