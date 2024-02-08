# This Dockerfile is based on https://github.com/Tiryoh/docker-ros2-desktop-vnc/blob/master/rolling/Dockerfile
# which is released under the Apache-2.0 license.

FROM ubuntu:jammy-20230816

ARG TARGETPLATFORM

SHELL ["/bin/bash", "-c"]

# Upgrade OS
RUN apt-get update -q && \
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install Ubuntu Mate desktop
RUN apt-get update -q && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ubuntu-mate-desktop && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Add Package
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  tigervnc-standalone-server tigervnc-common \
  supervisor wget curl gosu git sudo python3-pip tini \
  build-essential vim sudo lsb-release locales \
  bash-completion tzdata terminator && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# noVNC and Websockify
RUN git clone https://github.com/AtsushiSaito/noVNC.git -b add_clipboard_support /usr/lib/novnc
RUN pip install git+https://github.com/novnc/websockify.git@v0.10.0
RUN ln -s /usr/lib/novnc/vnc.html /usr/lib/novnc/index.html

# Set remote resize function enabled by default
RUN sed -i "s/UI.initSetting('resize', 'off');/UI.initSetting('resize', 'remote');/g" /usr/lib/novnc/app/ui.js

# Disable auto update and crash report
RUN sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
RUN sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

# Enable apt-get completion
RUN rm /etc/apt/apt.conf.d/docker-clean

# Install Firefox
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:mozillateam/ppa -y && \
  echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
  echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
  echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
  apt-get update -q && \
  apt-get install -y \
  firefox && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install VSCodium
RUN wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
  | gpg --dearmor \
  | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg && \
  echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
  | tee /etc/apt/sources.list.d/vscodium.list && \
  apt-get update -q && \
  apt-get install -y codium && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install ROS
ENV ROS_DISTRO rolling
# desktop or ros-base
ARG INSTALL_PACKAGE=desktop

RUN apt-get update -q && \
  apt-get install -y curl gnupg2 lsb-release && \
  curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
  apt-get update -q && \
  apt-get install -y ros-${ROS_DISTRO}-${INSTALL_PACKAGE} \
  python3-argcomplete \
  python3-colcon-common-extensions \
  python3-rosdep python3-vcstool && \
  rosdep init && \
  rm -rf /var/lib/apt/lists/*

RUN rosdep update

COPY ./entrypoint.sh /
ENTRYPOINT [ "/bin/bash", "-c", "/entrypoint.sh" ]

ENV USER ubuntu
ENV PASSWD ubuntu

# Install Rust
ENV RUSTUP_HOME /usr/local/rustup
ENV CARGO_HOME /usr/local/cargo
ENV PATH $PATH:/usr/local/cargo/bin
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
RUN chmod 777 ${CARGO_HOME}

# Install ament-cmake-vendor-package to build rmw_zenoh
RUN apt-get update -q && \
  apt-get install -y ros-${ROS_DISTRO}-ament-cmake-vendor-package && \
  rm -rf /var/lib/apt/lists/*