FROM ubuntu

ENV TZ=Asia/Dubai EXECUTION_CTX=docker
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG DEBIAN_FRONTEND=noninteractive
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections


WORKDIR /opt
RUN apt update -y && apt install batctl net-tools sudo git nano gcc python3-dev python3-yaml iproute2 iw wireless-tools isc-dhcp-client inetutils-ping lsb-release systemd iptables wget -y

RUN /bin/sh -c 'set -ex && \
    ARCH=`uname -m` && \
    if [ "$ARCH" = "aarch64" ]; then \
       wget https://github.com/tiiuae/wpa/raw/arm64_binaries/arm64/wpasupplicant_2.9.0-20_arm64.deb && \
       wget https://github.com/tiiuae/wpa/raw/arm64_binaries/arm64/hostapd_2.9.0-20_arm64.deb && \
       apt install -y libpcsclite-dev libnl-route-3-200 && \
       dpkg -i wpasupplicant_2.9.0-20_arm64.deb hostapd_2.9.0-20_arm64.deb; \
    else \
       wget https://artifactory.ssrc.fi:443/artifactory/debian-public-local/wpasupplicant_2.9.0-20-6~git20210701.43d8971_amd64.deb && \
       apt install -y libpcsclite-dev libnl-route-3-200 hostapd && \
       dpkg -i wpasupplicant_2.9.0-20-6~git20210701.43d8971_amd64.deb; \
    fi'

RUN wget -L https://github.com/tiiuae/mesh_com/raw/develop/modules/sc-mesh-secure-deployment/install.sh
RUN chmod 777 install.sh
RUN /bin/bash /opt/install.sh
WORKDIR /opt/mesh_com/modules/sc-mesh-secure-deployment/
