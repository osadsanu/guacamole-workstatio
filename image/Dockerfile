# Workstation image for the Guacamole PCAI framework.
#
# A Linux "virtual machine" reached through Apache Guacamole:
#   - XFCE desktop served by xrdp (RDP, port 3389)
#   - OpenSSH server (port 22) for the browser terminal
#   - Docker Engine (dockerd, needs a privileged container)
#   - minikube, kubectl, helm
#   - Firefox ESR to browse in-cluster services from inside the desktop
#
# Build & push (adjust the registry):
#   docker build -t <registry>/guacamole-workstation:0.1.0 .
#   docker push  <registry>/guacamole-workstation:0.1.0
FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH=amd64
ARG HELM_VERSION=v3.19.0
# "stable" resolves to the latest stable kubectl; pin e.g. v1.33.4 for reproducible builds
ARG KUBECTL_VERSION=stable
# "latest" resolves to the latest minikube; pin e.g. v1.36.0 for reproducible builds
ARG MINIKUBE_VERSION=latest

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# --- Base OS, desktop, remote access, browser, dev tooling -------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg sudo locales tzdata procps psmisc \
      iproute2 iputils-ping dnsutils net-tools iptables openssl \
      openssh-server supervisor dbus dbus-x11 \
      xfce4 xfce4-terminal xfce4-screenshooter thunar-archive-plugin \
      xrdp xorgxrdp x11-xserver-utils x11-utils xdg-utils \
      firefox-esr fonts-dejavu fonts-liberation \
      git vim nano less jq unzip zip bash-completion htop tmux \
 && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# --- Docker Engine (official apt repository) ---------------------------------
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
      > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

# --- kubectl, helm, minikube -------------------------------------------------
RUN set -eux; \
    if [ "${KUBECTL_VERSION}" = "stable" ]; then KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; fi; \
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" -o /usr/local/bin/kubectl; \
    chmod 0755 /usr/local/bin/kubectl; \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz -C /tmp; \
    install -m 0755 "/tmp/linux-${TARGETARCH}/helm" /usr/local/bin/helm; \
    rm -rf "/tmp/linux-${TARGETARCH}"; \
    curl -fsSL "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-${TARGETARCH}" -o /usr/local/bin/minikube; \
    chmod 0755 /usr/local/bin/minikube; \
    kubectl completion bash > /etc/bash_completion.d/kubectl; \
    helm completion bash > /etc/bash_completion.d/helm; \
    minikube completion bash > /etc/bash_completion.d/minikube

# --- xrdp / Xorg / sshd configuration ----------------------------------------
COPY startwm.sh /etc/xrdp/startwm.sh
RUN chmod 0755 /etc/xrdp/startwm.sh \
    # xrdp-sesman starts Xorg as the logged-in (non-root) user
 && if [ -f /etc/X11/Xwrapper.config ]; then sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config; fi \
    # keep disconnected desktops alive so a browser reconnect resumes the session
 && sed -i 's/^KillDisconnected=.*/KillDisconnected=false/' /etc/xrdp/sesman.ini \
    # password login over SSH is what Guacamole uses for the "Terminal" connection
 && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config \
    # host keys are generated per deployment by the entrypoint
 && rm -f /etc/ssh/ssh_host_* \
 && mkdir -p /run/sshd /var/run/xrdp

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# Docker data root and the user's home are expected to be volumes.
VOLUME ["/var/lib/docker"]

EXPOSE 22 3389

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
