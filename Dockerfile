# Loosely based on:
# https://github.com/CM2Walki/steamcmd 
# https://github.com/CM2Walki/CSGO/
# https://github.com/FragSoc/csgo-server-scrim

FROM debian:buster-slim

ENV USER=user
ENV HOME_DIR=/home/$USER
ENV STEAMCMD_DIR=$HOME_DIR/Steam \
    CSGO_DIR=$HOME_DIR/csgo-server

# Set up filesystem
RUN useradd -m $USER \
    && mkdir -p $STEAMCMD_DIR \
    && mkdir -p $CSGO_DIR/csgo

RUN apt-get update \
    # Install prerequisites
    #    lib32gcc1: prerequisite for steamcmd
    #    lib32stdc++6: prequisite for plugins 
    #    ca-certificates: required to trust downloads from the internet
    #    unzip: used to unzip get5 
    #    wget: used to download steam and plugins
    && apt-get install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        lib32stdc++6 \
        ca-certificates \
        unzip \
        wget \
    # Download and unpack steamcmd
    && wget -q -O - https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -zx -C $STEAMCMD_DIR \
    # Download and unpack plugins
    # MetaMod v1.11
    && wget -q -O - https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz | tar -xz -C $CSGO_DIR/csgo \
    # SourceMod v1.10
    && wget -q -O - https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6504-linux.tar.gz | tar -xz -C $CSGO_DIR/csgo \
    # Get5
    && wget -q https://github.com/splewis/get5/releases/download/0.7.2/get5_0.7.2.zip \
    && unzip -q get5_0.7.2.zip -d $CSGO_DIR/csgo \
    && rm get5_0.7.2.zip \
    # Set permissions
    && chown -R $USER:$USER $HOME_DIR \
    && chmod -R 755 $HOME_DIR \
    # Tidy up
    && apt-get purge -y unzip wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER $USER

# Copy install script
COPY server-scripts/server_update.sh $HOME_DIR/

# Install CSGO
RUN bash $HOME_DIR/server_update.sh

# Copy launch script
COPY server-scripts/server_launch.sh $HOME_DIR/

# Copy configs
COPY cfg/* $CSGO_DIR/csgo/cfg/

WORKDIR $HOME_DIR

# Set default values for environment variables
# Setting IP to 0 means that it is forced to listen on all interfaces
ENV IP="0" \
    PORT=27015 \
    GOTV_PORT=27020 \
    TICKRATE=128 \
    MAXPLAYERS=30 \
    GAMETYPE=0 \
    GAMEMODE=1 \
    MAPGROUP="mg_active" \
    MAP="de_mirage"

# Expose ports
EXPOSE $PORT/tcp \
       $PORT/udp \
       $GOTV_PORT/udp

# Run CSGO
CMD ["bash", "server_launch.sh"]
