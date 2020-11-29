FROM debian:stable

RUN apt-get update && \
      apt-get install -y wget software-properties-common build-essential ccache && \
      wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

RUN echo "deb http://apt.llvm.org/buster/ llvm-toolchain-buster-11 main" > /etc/apt/sources.list.d/llvm.list && \
      apt-get update && \
      apt-get install -y llvm-11-dev

RUN apt-get update && \
      apt-get install -y \
      openssl \
      zlib1g-dev \
      libdbus-1-dev \
      libdouble-conversion-dev \
      libdrm-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
      libgbm-dev \
      libgl1-mesa-dev \
      libgles2-mesa-dev \
      libharfbuzz-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libjsoncpp-dev \
      libmtdev-dev \
      libpcre2-dev \
      libpng-dev \
      libproxy-dev \
      libsqlite3-dev \
      libssl-dev \
      libtiff5-dev \
      libudev-dev \
      libwayland-dev \
      libwebp-dev \
      libx11-dev \
      libx11-xcb-dev \
      libx11-xcb-dev \
      libxcb-dri2-0-dev \
      libxcb-dri3-dev \
      libxcb-glx0-dev \
      libxcb-icccm4-dev \
      libxcb-image0-dev \
      libxcb-keysyms1-dev \
      libxcb-present-dev \
      libxcb-randr0-dev \
      libxcb-render-util0-dev \
      libxcb-render0-dev \
      libxcb-shape0-dev \
      libxcb-shm0-dev \
      libxcb-sync-dev \
      libxcb-sync0-dev \
      libxcb-util0-dev \
      libxcb-xfixes0-dev \
      libxcb-xinerama0-dev \
      libxcb-xkb-dev \
      libxcb1-dev \
      libxext-dev \
      libxfixes-dev \
      libxi-dev \
      libxkbcommon-dev \
      libxkbcommon-x11-dev \
      libxrender-dev \
      libzstd-dev

RUN apt-get update && \
      apt-get install -y procps

RUN ln -s /usr/bin/ccache /usr/lib/ccache/cc & \
      ln -s /usr/bin/ccache /usr/lib/ccache/c++

ENV PATH="/usr/lib/ccache:${PATH}"

WORKDIR /work
