FROM ubuntu:latest
MAINTAINER dc_726@163.com

# Env
ENV http_proxy "$http_proxy"
ENV https_proxy "$https_proxy"

# Prerequsite
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y build-essential openssh-server bash vim wget

# Create dir
RUN mkdir Software
RUN mkdir Workspace

# Install bochs & nasm & GDB
WORKDIR /Software
RUN wget http://sourceforge.net/projects/bochs/files/bochs/2.4.6/bochs-2.4.6.tar.gz
RUN tar -xzvf bochs-2.4.6.tar.gz

WORKDIR bochs-2.4.6
RUN ./configure --enable-debugger --enable-disasm --with-nogui
RUN make && make install

RUN apt-get install -y nasm
# RUN apt-get install -y gdb

# Download source code
WORKDIR /Workspace
ADD . minios
WORKDIR minios

