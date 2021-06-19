FROM ubuntu:18.04 
#Note that ubuntu 20.04 will not work.  

LABEL maintainer="1)Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu> "

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update \
   &&  apt-get -y install --no-install-recommends \
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
   autoconf \
   wget \
   ca-certificates \
   &&  rm -rf /var/lib/apt/lists/*

RUN mkdir /src/
WORKDIR /src/

# Install bamql from Boutros Github & Establish directories 
RUN wget https://github.com/BoutrosLaboratory/bamql/archive/refs/tags/v1.6.tar.gz \
   && tar -xzvf v1.6.tar.gz \
   && rm v1.6.tar.gz

WORKDIR /src/bamql-1.6
RUN autoreconf -i \
   &&  ./configure \
   &&  make \
   &&  make install 

# Set environment variables
ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /

# Define default command
CMD ["/bin/bash"]
