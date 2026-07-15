FROM cm2network/steamcmd:steam

ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/palworld

# ============================================
# 在构建时下载 Palworld 服务端（关键改动）
# 这样镜像本身就包含最新游戏文件
# ============================================
RUN /home/steam/steamcmd/steamcmd.sh +force_install_dir "/opt/palworld" +login anonymous +app_update 2394010 validate +quit

# 记录版本号到文件（方便启动时显示）
RUN if [ -f /opt/palworld/version.txt ]; then \
        echo "Built with version: $(cat /opt/palworld/version.txt 2>/dev/null || echo 'unknown')"; \
    else \
        echo "Built version: $(date +%Y%m%d)" > /opt/palworld/version.txt; \
    fi

# ============================================
# 环境变量（保留原样，但 FORCE_UPDATE 不再需要）
# ============================================
# Container lifecycle（不再需要 FORCE_UPDATE，因为镜像已包含最新文件）
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

# ============================================
# 复制启动脚本并设置权限
# ============================================
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE ${GAME_PORT}/udp ${RCON_PORT}/tcp ${RESTAPI_PORT}/tcp

# 创建存档和MOD目录
RUN mkdir -p /opt/palworld/Pal/Saved
RUN mkdir -p /opt/palworld/Pal/Content/Paks/MOD

VOLUME [ "/opt/palworld/Pal/Saved", "/opt/palworld/Pal/Content/Paks/MOD" ]

ENTRYPOINT [ "/docker-entrypoint.sh" ]
