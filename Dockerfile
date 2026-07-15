FROM cm2network/steamcmd:steam

ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/palworld

# ============================================
# 使用重试逻辑下载 Palworld 服务端
# ============================================
# 第一步：初始化 SteamCMD
RUN /home/steam/steamcmd/steamcmd.sh +login anonymous +quit

# 第二步：带重试的下载（最多尝试3次）
RUN for i in 1 2 3; do \
        echo "Attempt $i to download Palworld server..." && \
        /home/steam/steamcmd/steamcmd.sh +force_install_dir "/opt/palworld" +login anonymous +app_update 2394010 validate +quit && \
        echo "Download completed successfully!" && \
        break; \
    done && \
    if [ ! -f /opt/palworld/PalServer-Linux-Shipping ]; then \
        echo "ERROR: Palworld server files not found after multiple attempts!"; \
        exit 1; \
    fi

# 记录构建时间
RUN echo "Built on: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" > /opt/palworld/version.txt

# ============================================
# 环境变量（保留原有配置）
# ============================================
# Container lifecycle
ENV FORCE_UPDATE=false

# PalServer startup
ENV GAME_PORT=8211
ENV MAX_PLAYERS=32
ENV LOG_FORMAT=text
ENV IS_PUBLIC=false
ENV PUBLIC_IP=
ENV PUBLIC_PORT=

# Server identity and access
ENV SERVER_NAME="Default Palworld Server"
ENV SERVER_DESC="Default Palworld Server"
ENV SERVER_PASSWORD=

# Remote administration
ENV ADMIN_PASSWORD=changeme
ENV RCON_ENABLED=false
ENV RCON_PORT=25575
ENV RESTAPI_ENABLED=false
ENV RESTAPI_PORT=8212

# Crossplay
ENV CROSSPLAY_PLATFORMS=Steam,Xbox,PS5,Mac

# Performance
ENV ENABLE_MULTITHREAD=false
ENV WORKER_THREADS=
ENV BASE_CAMP_MAX_NUM=
ENV BASE_CAMP_MAX_NUM_IN_GUILD=4
ENV BASE_CAMP_WORKER_MAX_NUM=
ENV ITEM_CONTAINER_FORCE_MARK_DIRTY_INTERVAL=
ENV MAX_BUILDING_LIMIT_NUM=
ENV PHYSICS_ACTIVE_DROP_ITEM_MAX_NUM=
ENV SERVER_REPLICATE_PAWN_CULL_DISTANCE=

# Backups
ENV ENABLE_BACKUP_SAVE_DATA=

# 复制启动脚本
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE ${GAME_PORT}/udp ${RCON_PORT}/tcp ${RESTAPI_PORT}/tcp

# 创建存档和MOD目录
RUN mkdir -p /opt/palworld/Pal/Saved
RUN mkdir -p /opt/palworld/Pal/Content/Paks/MOD
VOLUME [ "/opt/palworld/Pal/Saved", "/opt/palworld/Pal/Content/Paks/MOD" ]

ENTRYPOINT [ "/docker-entrypoint.sh" ]
