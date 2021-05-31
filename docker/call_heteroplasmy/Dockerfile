FROM ubuntu:20.04

LABEL maintainer="1) Alfredo Enrique Gonzalez <alfgonzalez@mednet.ucla.edu> \ 
2)Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>"

RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update \
   &&  apt-get -y install --no-install-recommends \
   apt-utils \
   autotools-dev \
   build-essential \
   zlib1g-dev \
   unzip \
   wget \
   less\
   &&  rm -rf /var/lib/apt/lists/*
 
RUN mkdir /src/ \
   && mkdir /src/script/

WORKDIR /src/script/

COPY call_heteroplasmy_mitocaller.pl /src/script/

# avoid promptsc
ENV PERL_MM_USE_DEFAULT=1

# install perl dependencies
RUN cpan -i YAML::PP
RUN cpan -i Path:Class
RUN cpan -i Hash::Diff
RUN cpan -i Log::ProgramInfo
RUN cpan -i strict
RUN cpan -i warnings
RUN cpan -i Getopt::Long
RUN cpan -i Carp
RUN cpan -i Pod::Usage
RUN cpan -i Path::Class
RUN cpan -i File::Spec
RUN cpan -i File::Basename
RUN cpan -i File::Path
RUN cpan -i Data::Dumper
RUN cpan -i Log::ProgramInfo

CMD ["/bin/bash"]