FROM ubuntu:bionic

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install git curl unzip -y && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY tools /root/.provisio/tools
COPY libexec /root/.provisio/libexec
COPY provisio* /root/.provisio/
