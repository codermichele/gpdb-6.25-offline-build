#!/bin/bash

# apt-get update
# apt-get install -y \
# python-dev \
#	python-pip \
#	python-psutil \
#	python-yaml \
# openssl \
# autoconf \
#	zlib1g-dev \
# ccache \
#	cmake \
# curl \
#	gcc \
# g++ \
#	libssl-dev \
# locales-all \
#	inetutils-ping \
#	cgroup-tools \
#	bison \
#	flex \
# libreadline-dev \
#	libzstd-dev \
# libkrb5-dev \
#	python-gssapi \
# libevent-dev \
# libapr1-dev \
# libtool \
# libyaml-dev \
# libperl-dev \
#	libbz2-dev \
#	libcurl4-gnutls-dev \
#	libpam-dev \
# wget \
#	git-core \
#	krb5-kdc \
#	krb5-admin-server \
#	locales \
#	net-tools \
#	ninja-build \
# libpq-dev
  
#pip install conan
dpkg -i  /gpdb_src/greenplum-oss/greenplum-oss-debs/*.deb


tee -a /etc/sysctl.conf << EOF
kernel.shmmax = 5000000000000
kernel.shmmni = 32768
kernel.shmall = 40000000000
kernel.sem = 1000 32768000 1000 32768
kernel.msgmnb = 1048576
kernel.msgmax = 1048576
kernel.msgmni = 32768

net.core.netdev_max_backlog = 80000
net.core.rmem_default = 2097152
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

vm.overcommit_memory = 2
vm.overcommit_ratio = 95
EOF

sysctl -p

mkdir -p /etc/security/limits.d
tee -a /etc/security/limits.d/90-greenplum.conf << EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF

ulimit -n 65536
