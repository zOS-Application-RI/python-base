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
    dnf install -y dnf-plugins-core ; \
    dnf config-manager --set-disabled epel ; \
    sudo dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm && \
    dnf config-manager --set-enabled powertools ; \
    dnf module enable -y python39-devel ; \
    dnf clean all ; \
    rm -rf /var/cache/{dnf,yum} ; \
    rm -rf /var/lib/dnf/history.* ; \
    rm -rf /var/log/* ; \
  fi

RUN dnf -y update && dnf install -y 'dnf-command(config-manager)' && \
  dnf config-manager --set-enabled crb && \
  dnf install -y \
#  acl \
  cargo \
#  gcc \
#  gcc-c++ \
  glibc-langpack-en \
  krb5-devel \
  krb5-workstation \
#  libffi-devel \
#  libtool-ltdl-devel \
  python3-devel \
  python3-gssapi \  
  python3-pip \
  python3-wheel \
#  python3-psycopg2 \
#  python3-setuptools \  
#  xmlsec1-openssl \
#  xmlsec1-devel \
#  xmlsec1-openssl-devel \
  && dnf install -y --allowerasing libcurl libcurl-devel openssl-devel libxml2 libxml2-devel libxslt libxslt-devel \
  && dnf clean all \
  && rm -rf /var/cache/{dnf,yum} \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*

# Upgrade pip to fix wheel cache for locally built wheels.
# See https://github.com/pypa/pip/issues/6852
RUN python3 -m pip install --no-cache-dir -U pip \
    && python3 -m pip install --no-cache-dir -U pip setuptools \
    && python3 -m pip install --no-cache-dir -U pip setuptools-rust

RUN dnf update -y \
  && dnf install -y gcc \
  && pip3 install dumb-init --no-cache-dir -c constraints.txt \
  # && dnf remove -y gcc \
  && dnf clean all \
  && rm -rf /var/cache/{dnf,yum} \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*

WORKDIR /
RUN rm -rf $REMOTE_SOURCE_DIR

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
