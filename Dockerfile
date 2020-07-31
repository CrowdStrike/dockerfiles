#
# RHEL Universal Base Image (RHEL UBI) is a stripped down, OCI-compliant,
# base operating system image purpose built for containers. For more information
# see https://developers.redhat.com/products/rhel/ubi
#
from registry.access.redhat.com/ubi8/ubi
user root

#
# Friendly reminder that generated container images are from an open source
# project, and not a formal CrowdStrike product.
#
LABEL maintainer="https://github.com/CrowdStrike/openshift-falcon-daemonset"

#
# Apply updates to base image.
#
RUN yum -y update --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos && yum -y clean all && rm -rf /var/cache/yum

#
# Copy Falcon Agent RPM into container & install it, then remove the RPM
#
# TO DO: For now this script copies the full RPM and renames to /tmp/falcon-agent.rpm. This should be
#        changed to a parameter at some point.
#
COPY ./falcon-sensor-5.33.0-9808.el8.x86_64.rpm /tmp/falcon-agent.rpm
RUN yum -y install --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos /tmp/falcon-agent.rpm && yum -y clean all && rm -rf /var/cache/yum && rm /tmp/falcon-agent.rpm

#
# Copy the entrypoint script into the container and make sure
# that its executable. Add the symlink for backwards compatability
#
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /


ARG container_version
ARG BUILD_DATE              # BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ARG VCS_REF                 # VCS_REF=$(git rev-parse --short HEAD)

LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.schema-version "1.0"
LABEL org.label-schema.description "CrowdStrike Falcon Linux Sensor"
LABEL org.label-schema.vendor "https://github.com/CrowdStrike/openshift-falcon-daemonset"
LABEL org.label-schema.url="https://github.com/CrowdStrike/openshift-falcon-daemonset"
LABEL org.label-schema.vcs-url="https://github.com/CrowdStrike/openshift-falcon-daemonset"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.docker.cmd \
    "docker run -d --privileged -v /var/log:/var/log \
    --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
    --net=host --pid=host --uts=host --ipc=host \
    falcon-sensor"
LABEL org.label-schema.container_version $container_version

ENV PATH ".:/bin:/usr/bin:/sbin:/usr/sbin"
WORKDIR /opt/CrowdStrike

VOLUME /var/log
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
