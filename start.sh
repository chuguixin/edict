#!/bin/bash
# 🏛️  三省六部 · 一键启动脚本

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 杀掉旧进程
echo "Stopping existing services..."
pkill -f "scripts/run_loop.sh" || true
pkill -f "dashboard/server.py" || true

# 2. 启动数据刷新循环 (后台)
echo "Starting sync loop..."
nohup bash "$REPO_DIR/scripts/run_loop.sh" > /tmp/edict_loop.log 2>&1 &

# 3. 启动总控台
echo "Starting Edict Dashboard at http://127.0.0.1:7891 ..."
cd "$REPO_DIR"
python3 dashboard/server.py
