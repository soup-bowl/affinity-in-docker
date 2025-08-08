FROM docker.io/library/ubuntu:noble AS build

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    bison \
    build-essential \
    cabextract \
    curl \
    flex \
    g++-multilib \
    gcc-multilib \
    git \
    libc6-dev-i386 \
    libfreetype6-dev \
    libfreetype6-dev:i386 \
    libgcrypt20-dev \
    libgl1-mesa-dev:i386 \
    libglu1-mesa-dev:i386 \
    libgnutls28-dev \
    libgnutls28-dev:i386 \
    libx11-dev \
    libx11-dev:i386 \
    libxcomposite-dev:i386 \
    libxcursor-dev:i386 \
    libxext-dev:i386 \
    libxi-dev:i386 \
    libxinerama-dev:i386 \
    libxrandr-dev:i386 \
    libxrender-dev:i386 \
    libxxf86vm-dev:i386 \
    nettle-dev \
    nettle-dev:i386 \
    pkg-config \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Install Winetricks
    curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x winetricks && \
    mv winetricks /usr/local/bin/ && \
    mkdir -p /wineabc && \
    # Setup special Wine build for Affinity
    git clone https://gitlab.winehq.org/ElementalWarrior/wine.git && \
	cd wine && \
	git checkout affinity-photo2

ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

# Prep 64-bit Wine
RUN mkdir /wine64 && \
    cd /wine64 && \
    ../wine/configure --prefix=/opt/wine --enable-win64 && \
    make -j$(nproc) && \
    # Prep 32-bit Wine
    mkdir /wine32 && \
    cd /wine32 && \
    ../wine/configure --prefix=/opt/wine --with-wine64=../wine64 --enable-win32 && \
    make -j$(nproc) && \
    # Install Wine
    cd /wine64 && \
    make install && \
    cd /wine32 && \
    make install

# Setup the Wineprefix
ENV PATH="/opt/wine/bin:$PATH" \
    WINEPREFIX="/wineabc" \
    WINE="/opt/wine/bin/wine"

RUN curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x winetricks && \
    mv winetricks /usr/local/bin/ && \
    mkdir -p /wineabc && \
    wineboot && \
    winetricks -q dotnet48 corefonts renderer=vulkan
    
FROM docker.io/library/ubuntu:noble AS unpack

RUN apt-get update && \
    apt-get install -y \
    unzip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY Affinity /affinity
RUN cd /affinity && \
    mkdir affinity_unpack && \
    for app in designer photo publisher; do \
        msix_file=$(ls affinity-${app}-*.msix | head -n 1); \
        [ -f "$msix_file" ] || { echo "MSIX file for $app not found!"; exit 1; }; \
        unpack_dir="/tmp/affinity-unpack-$app"; \
        install_dir="/affinity_unpack/$(echo $app | sed 's/.*/\u&/') 2"; \
        mkdir -p "$unpack_dir" && \
        unzip "$msix_file" -d "$unpack_dir" && \
        mkdir -p "$install_dir" && \
        mv "$unpack_dir/App/"* "$install_dir/" && \
        cp "$unpack_dir/Package/AppLogo.targetsize-48.png" "$install_dir/logo.png" && \
        rm -rf "$unpack_dir"; \
    done

FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install  --no-install-recommends -y \
    cabextract \
    curl \
    libfreetype6 \
    libfreetype6:i386 \
    libgcrypt20 \
    libgl1 \
    libgl1:i386 \
    libglu1-mesa \
    libglu1-mesa:i386 \
    libgnutls30 \
    libhogweed6 \
    libnettle8 \
    libx11-6 \
    libx11-6:i386 \
    libxcomposite1 \
    libxcomposite1:i386 \
    libxcursor1 \
    libxcursor1:i386 \
    libxext6 \
    libxext6:i386 \
    libxi6 \
    libxi6:i386 \
    libxinerama1 \
    libxinerama1:i386 \
    libxrandr2 \
    libxrandr2:i386 \
    libxrender1 \
    libxrender1:i386 \
    unzip \
    winbind \
    xfce4 \
    xfce4-terminal \
    xubuntu-default-settings \
    xubuntu-icon-theme \
    zenity \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Install Winetricks
    curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x winetricks && \
    mv winetricks /usr/local/bin/ && \
    # Give the web view the SerifLabs icon - make it more recognisable.
    curl -o /usr/share/selkies/www/icon.png https://affinity.serif.com/favicon-16.png && \
    # XFCE4 Stuff
    rm -f /etc/xdg/autostart/xscreensaver.desktop

COPY --from=build /opt/wine /opt/wine
COPY --from=build --chown=1000:1000 /wineabc /wineabc
COPY --from=unpack --chown=1000:1000 ["/affinity_unpack", "/wineabc/drive_c/Program Files/Affinity/"]
COPY --chown=1000:1000 WinMetadata /wineabc/drive_c/windows/system32/WinMetadata
COPY  app /usr/share/applications/Affinity

COPY /root /

ENV TITLE="Affinity Suite" \
    PATH="/opt/wine/bin:$PATH" \
    WINEPREFIX="/wineabc" \
    WINE="/opt/wine/bin/wine"

EXPOSE 3000

VOLUME /config
