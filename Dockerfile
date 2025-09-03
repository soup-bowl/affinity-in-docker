FROM ghcr.io/soup-bowl/affinity-in-docker/wine:latest AS wineprep

RUN curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
	chmod +x winetricks && \
	mv winetricks /usr/local/bin/ && \
	mkdir -p /wineabc

# Setup the Wineprefix
ENV PATH="/opt/wine/bin:$PATH" \
	WINEPREFIX="/wineabc" \
	WINE="/opt/wine/bin/wine"

RUN wineboot && \
	winetricks -q dotnet48 corefonts renderer=vulkan
	
FROM docker.io/library/ubuntu:noble AS unpack

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
	apt-get install --no-install-recommends -y \
	unzip \
	&& apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY Affinity /affinity

RUN mkdir affinity_unpack
WORKDIR /affinity
RUN for app in designer photo publisher; do \
		msix_file=$(ls affinity-${app}-*.msix | head -n 1) && \
		[ -f "$msix_file" ] && \
		unpack_dir="/tmp/affinity-unpack-$app" && \
		install_dir="/affinity_unpack/$(echo $app | sed 's/.*/\u&/') 2" && \
		mkdir -p "$unpack_dir" && \
		unzip "$msix_file" -d "$unpack_dir" && \
		mkdir -p "$install_dir" && \
		mv "$unpack_dir/App/"* "$install_dir/" && \
		cp "$unpack_dir/Package/AppLogo.targetsize-48.png" "$install_dir/logo.png" && \
		rm -rf "$unpack_dir" || { echo "MSIX file for $app not found!"; exit 1; }; \
	done

FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

RUN dpkg --add-architecture i386 && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive \
	apt-get install --no-install-recommends -y \
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
	rm -f /etc/xdg/autostart/xscreensaver.desktop && \
	mv /usr/bin/thunar /usr/bin/thunar-real

COPY --from=wineprep /opt/wine /opt/wine
COPY --from=wineprep --chown=1000:1000 /wineabc /wineabc
COPY --from=unpack --chown=1000:1000 ["/affinity_unpack", "/wineabc/drive_c/Program Files/Affinity/"]
COPY --chown=1000:1000 WinMetadata /wineabc/drive_c/windows/system32/WinMetadata

COPY /root /

ENV TITLE="Affinity Suite" \
	PATH="/opt/wine/bin:$PATH" \
	WINEPREFIX="/wineabc" \
	WINE="/opt/wine/bin/wine"

EXPOSE 3000

VOLUME /config
