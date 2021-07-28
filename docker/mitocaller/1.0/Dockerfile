FROM ubuntu:20.04

LABEL maintainer="Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update \
   &&  apt-get -y install --no-install-recommends \
   apt-utils \
   autoconf \
   wget \
   ca-certificates \
   &&  rm -rf /var/lib/apt/lists/*

ENV MITOCALLER_SHA512=6dbc52a61fe47034fe430ed06845226f658af3aa41b1cecbf4bced8d03fe05236a0dd186cec383db65998a1002f0aaf4b4159dd4ade21a9fcffbc0562ce2f0f1
RUN mkdir /MitoCaller/ \
   ## Using this to show where it is actually coming from
   && wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller.zip \
   && echo "${MITOCALLER_SHA512} mitoCaller.zip" | sha512sum --strict -c \
   && rm mitoCaller.zip

## copy mitocaller script from local because portal where zip file is pulled from crashes often, and too reduce image size
## make sure that the mitocaller folder is in the same directory tree as the Dockerfile
COPY mitoCaller /MitoCaller/
WORKDIR /MitoCaller/

RUN chmod 777 -R /MitoCaller

CMD ["/bin/bash"]


