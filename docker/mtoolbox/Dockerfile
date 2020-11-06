FROM ubuntu:16.04

LABEL maintainer="Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install zip unzip \
   &&  apt-get install -y apt-utils autotools-dev build-essential zlib1g-dev \
   &&  apt-get install -y unzip wget \
   &&  apt-get install -y openjdk-8-jre-headless \
   &&  apt-get install -y git \
   &&  apt-get install -y libncurses5-dev \
   &&  apt-get install -y libncursesw5-dev \
   &&  rm -rf /var/lib/apt/lists/* 
   
RUN mkdir -p /src/ 
WORKDIR /src/ 
RUN git clone https://github.com/mitoNGS/MToolBox.git
RUN chmod 777 -R /src/MToolBox/
WORKDIR /src/MToolBox/
RUN ./install.sh
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/src/MToolBox/MToolBox/

# Define default command
CMD ["/bin/bash"]
