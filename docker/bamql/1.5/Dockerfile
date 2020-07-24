FROM ubuntu:18.04

MAINTAINER Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>
ENV TERM=vt100

RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install -y autotools-dev build-essential libhts-dev libtool libpcre++-dev llvm-dev pkg-config uuid-dev zlib1g-dev \
   &&  apt-get install -y autoconf wget \
   &&  rm -rf /var/lib/apt/lists/*

RUN mkdir /src/
WORKDIR /src/

RUN wget https://github.com/BoutrosLaboratory/bamql/archive/v1.5.tar.gz \
   && tar -xzvf v1.5.tar.gz \
   && rm v1.5.tar.gz
WORKDIR /src/bamql-1.5
RUN autoreconf -i \
   &&  ./configure \
   &&  make \
   &&  make install 

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /

CMD ["/bin/bash"]
