# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG CONTAINER_IMAGE=quay.io/centos/centos:stream9
ARG REMOTE_SOURCE=.
ARG REMOTE_SOURCE_DIR=/remote-source

FROM $CONTAINER_IMAGE
# ============================================================================
ARG CONTAINER_IMAGE
ARG REMOTE_SOURCE_DIR

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN echo "install_weak_deps=False" >> /etc/dnf/dnf.conf \
    && echo "tsflags=nodocs" >> /etc/dnf/dnf.conf

RUN if [[ "$CONTAINER_IMAGE" =~ "centos" ]] ; then \
    dnf update -y ; \
    dnf install -y epel-release dnf-plugins-core ; \
    dnf config-manager --set-disabled epel ; \
    dnf config-manager --set-enabled powertools ; \
    dnf module enable -y python310-devel ; \
    dnf clean all ; \
    rm -rf /var/cache/{dnf,yum} ; \
    rm -rf /var/lib/dnf/history.* ; \
    rm -rf /var/log/* ; \
  fi

RUN dnf update -y \
  && dnf install -y glibc-langpack-en python3-pip \
  && dnf clean all \
  && rm -rf /var/cache/{dnf,yum} \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*

# NOTE(pabelanger): We do this to allow users to install python36 but not
# change python3 to python36.
#RUN alternatives --set python3 /usr/bin/python3.10

# Upgrade pip to fix wheel cache for locally built wheels.
# See https://github.com/pypa/pip/issues/6852
RUN python3 -m pip install --no-cache-dir -U pip

RUN dnf update -y \
  && dnf install -y gcc \
  && pip3 install dumb-init --no-cache-dir -c constraints.txt \
  && dnf remove -y gcc \
  # && dnf clean all \
  && rm -rf /var/cache/{dnf,yum} \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*
# Install runtime requirements
RUN dnf -y update && dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf -y install acl \
    git-core \
    git-lfs \
    glibc-langpack-en \
    krb5-workstation \
    nginx \
    postgresql \
    python3-devel \
    python3-libselinux \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools \
    rsync \
    "rsyslog >= 8.1911.0" \
    subversion \
    sudo \
    vim-minimal \
    which \
    unzip \
    xmlsec1-openssl && \
    dnf -y clean all
RUN dnf -y update && dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
    cargo \
    gcc \
    gcc-c++ \
    git-core \
    gettext \
    glibc-langpack-en \
	krb5-devel \
    libffi-devel \
    libtool-ltdl-devel \
    make \
    nss \
    openssl-devel \
    openldap-devel \
    patch \
    python3-devel \
	python3-gssapi \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools \
    swig \
    unzip \
    xmlsec1-devel \
    xmlsec1-openssl-devel
RUN pip3 install -U pip && python3 -m pip install -U pip setuptools && python3 -m pip install -U pip setuptools-rust

WORKDIR /
RUN rm -rf $REMOTE_SOURCE_DIR

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
