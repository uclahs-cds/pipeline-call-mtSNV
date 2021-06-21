FROM ubuntu:20.04

LABEL maintainer="1) Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
2)Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update \
   &&  apt-get -y install --no-install-recommends \
   apt-utils \
   autoconf \
   wget \
   ca-certificates \
   &&  rm -rf /var/lib/apt/lists/*

RUN mkdir /MitoCaller/ \
   ## Using this to show where it is actually coming from
   && wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller.zip \
   && rm mitoCaller.zip

## copy mitocaller script from local because portal where zip file is pulled from crashes often, and too reduce image size
## make sure that the mitocaller folder is in the same directory tree as the Dockerfile
COPY mitoCaller /MitoCaller/
WORKDIR /MitoCaller/

RUN chmod 777 -R /MitoCaller

CMD ["/bin/bash"]


