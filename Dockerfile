FROM ubuntu:bionic

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install git curl unzip -y && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN groupadd -g 456 concord && \
    useradd --no-log-init -u 456 -g concord -m -s /sbin/nologin concord

COPY config /root/.provisio/config
COPY provisio* /root/.provisio

RUN mkdir -p /home/concord/.m2/repository && \
    chown -R concord:concord /home/concord
