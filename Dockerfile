#
# RHEL Universal Base Image (RHEL UBI) is a stripped down, OCI-compliant,
# base operating system image purpose built for containers. For more information
# see https://developers.redhat.com/products/rhel/ubi
#
FROM registry.access.redhat.com/ubi8/ubi:8.3
USER root

ARG container_version

# BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ARG BUILD_DATE

# VCS_REF=$(git rev-parse --short HEAD)
ARG VCS_REF

ARG FALCON_PKG

#
# Friendly reminder that generated container images are from an open source
# project, and not a formal CrowdStrike product.
#
LABEL maintainer="https://github.com/CrowdStrike/dockerfiles/" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.description="CrowdStrike's Containerized Falcon Linux Sensor" \
      org.label-schema.vendor="https://github.com/CrowdStrike/dockerfiles/" \
      org.label-schema.url="https://github.com/CrowdStrike/dockerfiles/" \
      org.label-schema.vcs-url="https://github.com/CrowdStrike/dockerfiles/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.docker.cmd="docker run -d --privileged -v /var/log:/var/log \
                                   --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
                                   --net=host --pid=host --uts=host --ipc=host \
                                   falcon-sensor" \
      org.label-schema.container_version=$container_version \
      io.openshift.tags="crowdstrike,falcon" \
      io.k8s.description="CrowdStrike's Containerized Falcon Linux Sensor"
#      io.openshift.min-memory       8Gi
#      io.openshift.min-cpu          4

#
# 1. Apply updates to base image and install dependencies
# 2. Copy Falcon Agent RPM into container & install it, then remove the RPM
#
COPY ./$FALCON_PKG /tmp/falcon-sensor.rpm
RUN yum -y update && \
    yum -y install --disablerepo=* \
    --enablerepo=ubi-8-appstream \
    --enablerepo=ubi-8-baseos \
    libnl3 net-tools zip openssl hostname iproute procps-ng && \
    rpm -ivh --nodigest --nofiledigest /tmp/falcon-sensor.rpm && \
    yum -y clean all && rm -rf /var/cache/yum && \
    rm -f /tmp/falcon-sensor.rpm

#
# Copy the entrypoint script into the container and make sure
# that its executable. Add the symlink for backwards compatability
#
COPY entrypoint.sh /

ENV PATH ".:/bin:/usr/bin:/sbin:/usr/sbin"
WORKDIR /opt/CrowdStrike

VOLUME /var/log
ENTRYPOINT ["/entrypoint.sh"]
