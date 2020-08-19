FROM ubuntu:16.04

MAINTAINER Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>
MAINTAINER Andrew Park <andrewjpark@mednet.ucla.edu>
ENV TERM=vt100

RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install -y apt-utils autotools-dev build-essential zlib1g-dev \
   &&  apt-get install -y unzip wget \
   &&  apt-get install -y openjdk-8-jre-headless \
   && apt-get install -y python \
   &&  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /src/ExtractReads
WORKDIR /src/
# probably delete the ref genomes from the original archive and use one from config
ADD MToolBox-1.0.0-with-dependencies/ /src/

RUN ./install.sh -g 2018-07-04 -a 2-4.2.0

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/src/MToolBox/

CMD ["/bin/bash"]
