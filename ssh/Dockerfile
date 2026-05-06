FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    chrony \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

RUN useradd -m -s /bin/bash tm_admin && \
    echo 'tm_admin:Admin2024!' | chpasswd && \
    usermod -aG sudo tm_admin

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY chrony.conf /etc/chrony.conf

EXPOSE 22 123/udp

CMD service chrony start && /usr/sbin/sshd -D
