FROM ubuntu:latest
MAINTAINER dc_726@163.com

ENV http_proxy "$http_proxy"
# ENV https_proxy $https_proxy

# RUN apt-get update -y

ADD . minios/
WORKDIR minios/

