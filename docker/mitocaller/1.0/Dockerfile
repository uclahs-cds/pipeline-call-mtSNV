FROM ubuntu:20.04


LABEL maintainer="1) Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu>\ 
2)Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

RUN mkdir /mitocaller2/
COPY mitoCaller /mitocaller2/



# Install utilities
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install -y apt-utils \
   &&  apt-get install -y autoconf wget \
   &&  rm -rf /var/lib/apt/lists/*

RUN wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller.zip -no-check-certificate \
   && rm mitoCaller.zip

WORKDIR /mitocaller2/

RUN chmod 777 -R /mitocaller2

CMD ["/bin/bash"]


