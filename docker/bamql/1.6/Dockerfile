FROM ubuntu:18.04 
#Note that ubuntu 20.04 will not work.  

LABEL maintainer="Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>"

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
ENV BAMQL_SHA512=7b3208f1afd08131f7e1223251fe6b13d60a2970d55daf82c7c3153d6f707ff71bad774b5e9da5def797fd260902916c82c12dd32c26051e5af92fd0457e9414
RUN wget https://github.com/BoutrosLaboratory/bamql/archive/refs/tags/v1.6.tar.gz \
   && echo "${BAMQL_SHA512} v1.6.tar.gz" | sha512sum --strict -c \
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
