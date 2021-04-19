FROM ubuntu:20.04
LABEL maintainer="Alfredo Enrique Gonzalez <fred23@g.ucla.edu>"

RUN apt-get update && apt-get -y install --no-install-recommends \
    python3.8 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/* 

RUN wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller2vcf.zip --no-check-certificate \
    && unzip mitoCaller2vcf.zip 

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mitoCaller2vcf/mitoCaller2vcf.py
