FROM ubuntu:20.04

LABEL maintainer="zoocityboy"

ENV ANDROID_SDK_TOOLS_VERSION 6858069
ENV ANDROID_SDK_TOOLS_CHECKSUM 87f6dcf41d4e642e37ba03cb2e387a542aa0bd73cb689a9e7152aad40a6e7a08

ENV ANDROID_HOME "/opt/android-sdk-linux"
ENV ANDROID_SDK_ROOT $ANDROID_HOME
ENV PATH $PATH:$ANDROID_HOME/cmdline-tools:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/platform-tools

ENV FLUTTER_VERSION="2.10.5"
ENV FLUTTER_HOME "/home/zoo/.flutter-sdk"
ENV PATH $PATH:$FLUTTER_HOME/bin
ENV PATH $PATH:$FLUTTER_HOME/bin/cache/dart-sdk/bin

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.UTF-8

# Add base environment
RUN apt-get -qq update \
    && apt-get -qqy --no-install-recommends install \
    apt-utils \
    openjdk-11-jdk \
    openjdk-11-jre-headless- \
    software-properties-common \
    build-essential \
    lib32stdc++6 \
    libstdc++6 \
    libpulse0 \
    libglu1-mesa \
    openssh-server \
    unzip \
    curl \
    lldb \
    libglfw3-dev locales \
    curl \
    clang \
    ca-certificates \
    git-core \
    supervisor \
    curl \
    scrot \
    unzip \
    rsync \
    file \
    gcc \
    cmake \
    ninja-build \
    libgtk-3.0 \
    xvfb \
    pkg-config \
    libgtk-3-dev \
    libblkid-dev \
    libglvnd-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev\
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libgles2 \
    libxext6 libx11-6 \
    lsb-release \
    gnupg \    
    git > /dev/null \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# AZ CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null 
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update &&\
    apt-get install azure-cli

# Download and unzip Android SDK Tools
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip > /tools.zip \
    && echo "$ANDROID_SDK_TOOLS_CHECKSUM ./tools.zip" | sha256sum -c \
    && unzip -qq /tools.zip -d $ANDROID_HOME \
    && rm -v /tools.zip

# Accept licenses
RUN mkdir -p $ANDROID_HOME/licenses/ \
    && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license --licenses \
    && yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT}

# Add non-root user 
RUN groupadd -r zoo \
    && useradd --no-log-init -r -g zoo zoo \
    && mkdir -p /home/zoo/.android \
    && mkdir -p /home/zoo/.flutter-sdk \
    && mkdir -p /home/zoo/app \
    && touch /home/zoo/.android/repositories.cfg \
    && chown --recursive zoo:zoo /home/zoo \
    && chown --recursive zoo:zoo /home/zoo/app \
    && chown --recursive zoo:zoo $FLUTTER_HOME \
    && chown --recursive zoo:zoo $ANDROID_HOME

# Set non-root user as default      
ENV HOME /home/zoo
USER zoo
WORKDIR $HOME/app

# Install Android packages
ADD packages.txt $HOME
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager --update  --sdk_root=${ANDROID_SDK_ROOT} \
    && while read -r pkg; do PKGS="${PKGS}${pkg} "; done < $HOME/packages.txt \
    && $ANDROID_HOME/cmdline-tools/bin/sdkmanager $PKGS > /dev/null --sdk_root=${ANDROID_SDK_ROOT} \
    && rm $HOME/packages.txt


# Locales    
RUN sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

# Download and extract Flutter SDK
RUN cd $FLUTTER_HOME \
    && curl --fail --remote-time --silent --location -O https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    && tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz --strip-components=1 \
    && rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

RUN flutter precache
RUN flutter config --enable-linux-desktop
RUN flutter doctor -v