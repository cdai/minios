FROM ubuntu:latest
MAINTAINER dc_726@163.com

# Env
ENV http_proxy "$http_proxy"
ENV https_proxy "$https_proxy"


# Common prerequsite
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y build-essential openssh-server bash vim wget


# Specific: 32-bit dev support, nasm, gdb, bochs so  
RUN apt-get install -y libc6-dev libc6-dev-i386
RUN apt-get install -y nasm gdb
RUN apt-get install -y lib32stdc++6

# Install bochs & nasm & GDB
RUN mkdir Software
WORKDIR /Software
RUN wget http://sourceforge.net/projects/bochs/files/bochs/2.4.6/bochs-2.4.6.tar.gz
RUN tar -xzvf bochs-2.4.6.tar.gz
WORKDIR bochs-2.4.6
RUN ./configure --enable-debugger --enable-disasm --with-nogui
RUN make && make install


# Mount source dir
RUN mkdir Workspace
WORKDIR /Workspace
ADD . minios
WORKDIR minios

