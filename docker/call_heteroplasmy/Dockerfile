FROM ubuntu:20.10

MAINTAINER Takafumi Yamaguchi <tyamaguchi@mednet.ucla.edu>
ENV TERM=vt100

RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
   &&  apt-get update &&  apt-get -y upgrade \
   &&  apt-get install -y apt-utils autotools-dev build-essential zlib1g-dev \
   &&  apt-get install -y unzip wget less\
   &&  rm -rf /var/lib/apt/lists/*
 
RUN mkdir /src/
WORKDIR /src/

# avoid prompts
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


# add the validation script
#ADD bin/validate_dataset.pl /usr/local/bin/

CMD ["/bin/bash"]