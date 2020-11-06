FROM ubuntu:16.04

LABEL maintainer="1) Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
2)Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install -y apt-utils autotools-dev build-essential zlib1g-dev \
   &&  apt-get install -y unzip wget\
   &&  rm -rf /var/lib/apt/lists/*

# Set workdir
RUN mkdir /src/
WORKDIR /src/

# probably delete the ref genomes from the original archive and use one from config
RUN wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller.zip \
   && unzip mitoCaller.zip \
   && rm mitoCaller.zip

# Set workdir to mitocaller folder
WORKDIR /src/mitoCaller-package/mitoCaller/
RUN make
RUN ln -s /src/mitoCaller-package/mitoCaller/bin/mitoCaller /usr/local/bin/mitoCaller

WORKDIR /

CMD ["/bin/bash"]


# Question about previous commands
# ENV TERM=vt100
