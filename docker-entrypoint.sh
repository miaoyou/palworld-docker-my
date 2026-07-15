#!/bin/bash

# ============================================
# 设置默认值
# ============================================
GAME_PORT=${GAME_PORT:-8211}
MAX_PLAYERS=${MAX_PLAYERS:-32}
LOG_FORMAT=${LOG_FORMAT:-text}
IS_PUBLIC=${IS_PUBLIC:-false}
ENABLE_MULTITHREAD=${ENABLE_MULTITHREAD:-false}
RCON_ENABLED=${RCON_ENABLED:-false}
RCON_PORT=${RCON_PORT:-25575}
RESTAPI_ENABLED=${RESTAPI_ENABLED:-false}
RESTAPI_PORT=${RESTAPI_PORT:-8212}

# ============================================
# 打印启动信息
# ============================================
echo "=========================================="
echo "Palworld Dedicated Server"
echo "=========================================="
echo "Game Port: $GAME_PORT"
echo "Max Players: $MAX_PLAYERS"
echo "Log Format: $LOG_FORMAT"
echo "Public Server: $IS_PUBLIC"
echo "Multithread: $ENABLE_MULTITHREAD"
echo "RCON Enabled: $RCON_ENABLED"
echo "REST API Enabled: $RESTAPI_ENABLED"
if [ -n "$SERVER_NAME" ]; then
    echo "Server Name: $SERVER_NAME"
fi
if [ -n "$SERVER_PASSWORD" ]; then
    echo "Server Password: [SET]"
fi
echo "=========================================="

# ============================================
# 切换到 Palworld 目录
# ============================================
cd /opt/palworld

if [ ! -f "./PalServer-Linux-Shipping" ]; then
    echo "ERROR: PalServer-Linux-Shipping not found!"
    echo "The server files may not be properly installed."
    exit 1
fi

# ============================================
# 构建启动参数
# ============================================
START_ARGS="-port=$GAME_PORT"
START_ARGS="$START_ARGS -players=$MAX_PLAYERS"
START_ARGS="$START_ARGS -logformat=$LOG_FORMAT"

# 是否公开服务器
if [ "$IS_PUBLIC" = "true" ]; then
    START_ARGS="$START_ARGS -publiclobby"
fi

# 公开 IP（仅当 IS_PUBLIC=true 时生效）
if [ -n "$PUBLIC_IP" ] && [ "$IS_PUBLIC" = "true" ]; then
    START_ARGS="$START_ARGS -publicip=$PUBLIC_IP"
fi

# 公开端口（仅当 IS_PUBLIC=true 时生效）
if [ -n "$PUBLIC_PORT" ] && [ "$IS_PUBLIC" = "true" ]; then
    START_ARGS="$START_ARGS -publicport=$PUBLIC_PORT"
fi

# 服务器名称
if [ -n "$SERVER_NAME" ]; then
    START_ARGS="$START_ARGS -servername=\"$SERVER_NAME\""
fi

# 服务器描述
if [ -n "$SERVER_DESC" ]; then
    START_ARGS="$START_ARGS -serverdesc=\"$SERVER_DESC\""
fi

# 服务器密码
if [ -n "$SERVER_PASSWORD" ]; then
    START_ARGS="$START_ARGS -serverpassword=\"$SERVER_PASSWORD\""
fi

# 管理员密码
if [ -n "$ADMIN_PASSWORD" ] && [ "$ADMIN_PASSWORD" != "changeme" ]; then
    START_ARGS="$START_ARGS -adminpassword=\"$ADMIN_PASSWORD\""
fi

# 多线程优化
if [ "$ENABLE_MULTITHREAD" = "true" ]; then
    START_ARGS="$START_ARGS -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
fi

# Worker 线程数
if [ -n "$WORKER_THREADS" ]; then
    START_ARGS="$START_ARGS -NumberOfWorkerThreadsServer=$WORKER_THREADS"
fi

# RCON
if [ "$RCON_ENABLED" = "true" ]; then
    START_ARGS="$START_ARGS -rcon -rconport=$RCON_PORT"
fi

# REST API
if [ "$RESTAPI_ENABLED" = "true" ]; then
    START_ARGS="$START_ARGS -restapienabled -restapiip=0.0.0.0 -restapiport=$RESTAPI_PORT"
fi

# 跨平台
if [ -n "$CROSSPLAY_PLATFORMS" ]; then
    START_ARGS="$START_ARGS -CrossplayPlatforms=$CROSSPLAY_PLATFORMS"
fi

# ============================================
# 生成 PalWorldSettings.ini（如果不存在）
# ============================================
SETTINGS_DIR="/opt/palworld/Pal/Saved/Config/LinuxServer"
SETTINGS_FILE="$SETTINGS_DIR/PalWorldSettings.ini"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Generating PalWorldSettings.ini..."
    mkdir -p "$SETTINGS_DIR"
    
    cat > "$SETTINGS_FILE" << EOF
[/Script/Pal.PalGameWorldSettings]
OptionSettings=(BaseCampMaxNum=${BASE_CAMP_MAX_NUM:-},BaseCampMaxNumInGuild=${BASE_CAMP_MAX_NUM_IN_GUILD:-4},BaseCampWorkerMaxNum=${BASE_CAMP_WORKER_MAX_NUM:-},ItemContainerForceMarkDirtyInterval=${ITEM_CONTAINER_FORCE_MARK_DIRTY_INTERVAL:-},MaxBuildingLimitNum=${MAX_BUILDING_LIMIT_NUM:-},PhysicsActiveDropItemMaxNum=${PHYSICS_ACTIVE_DROP_ITEM_MAX_NUM:-},ServerReplicatePawnCullDistance=${SERVER_REPLICATE_PAWN_CULL_DISTANCE:-},bIsUseBackupSaveData=${ENABLE_BACKUP_SAVE_DATA:-false})
EOF
    echo "PalWorldSettings.ini created."
fi

# ============================================
# 启动服务器
# ============================================
echo "Starting Palworld server with args: $START_ARGS"
echo "=========================================="

exec ./PalServer-Linux-Shipping $START_ARGS
