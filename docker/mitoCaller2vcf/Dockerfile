FROM ubuntu:20.04
LABEL maintainer="Alfredo Enrique Gonzalez <fred23@g.ucla.edu>"
ENV MITOCALLER2VCF=0a27a58c8aea28fc730657c3def2f532bfae121d2df1aea0b20f8fd58c5e1c7e7f66237b025ab92a7a4e1a822cf45e42d91004e0148a1527c30ef97c11fd78d5

RUN apt-get update && apt-get -y install --no-install-recommends \
    python3.8 \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* 

RUN wget https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/download/mitoCaller2vcf.zip \
    echo "${MITOCALLER2VCF} mitoCaller2vcf.zip" | sha512sum --strict -c \
    && unzip mitoCaller2vcf.zip 

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mitoCaller2vcf/mitoCaller2vcf.py
