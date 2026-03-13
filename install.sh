#!/bin/bash
# ══════════════════════════════════════════════════════════════
# 三省六部 · EDICT OpenClaw Multi-Agent System
# 统一安装与初始化脚本 (v2026.3)
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
  echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║       🏛️  三省六部 · EDICT 系统安装向导        ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
}

log()   { echo -e "${GREEN}✓ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; }
info()  { echo -e "${BLUE}i $1${NC}"; }

# ── Step 0: 依赖检查 ──────────────────────────────────────────
check_deps() {
  info "正在检查环境依赖..."
  
  if ! command -v openclaw &>/dev/null; then
    error "未找到 openclaw CLI。请访问 https://openclaw.ai 安装。"
    exit 1
  fi

  if ! command -v gh &>/dev/null; then
    warn "未找到 gh (GitHub CLI)。建议安装以启用自动化 Git 操作。"
  else
    if gh auth status &>/dev/null; then
      log "GitHub CLI 已授权: $(gh api user --jq .login 2>/dev/null || echo 'Authenticated')"
    else
      warn "GitHub CLI 未授权，部分自动化功能可能受限。"
    fi
  fi

  if [ ! -f "$OC_CFG" ]; then
    error "未找到 openclaw.json。请先运行 openclaw 完成基础初始化。"
    exit 1
  fi
}

# ── Step 1: 注册三省六部 Agents ───────────────────────────────
register_agents() {
  info "正在注册三省六部 Agents 架构..."
  
  # 备份当前配置
  cp "$OC_CFG" "$OC_CFG.bak.sansheng.$(date +%Y%m%d-%H%M%S)"

  python3 << 'PYEOF'
import json, pathlib, os

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

# 定义 2026 三省六部核心架构
AGENTS = [
    {"id": "taizi", "default": True, "subagents": {"allowAgents": ['zhongshu', 'menxia', 'gongbu', 'bingbu', 'hubu', 'libu', 'xingbu', 'hanlin', 'shangshu', 'libu_hr']}},
    {"id": "zhongshu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "menxia", "default": False, "subagents": {"allowAgents": []}},
    {"id": "shangshu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "bingbu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "hubu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "libu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "xingbu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "gongbu", "default": False, "subagents": {"allowAgents": []}},
    {"id": "hanlin", "default": False, "subagents": {"allowAgents": []}},
    {"id": "libu_hr", "default": False, "subagents": {"allowAgents": ['gongbu', 'bingbu', 'hubu', 'libu', 'xingbu', 'hanlin']}},
    {"id": "zaochao", "default": False, "subagents": {"allowAgents": []}}
]}},
    {"id": "zhongshu", "default": False, "subagents": {"allowAgents": ["menxia", "shangshu"]}},
    {"id": "menxia",   "default": False, "subagents": {"allowAgents": ["shangshu", "zhongshu"]}},
    {"id": "shangshu", "default": False, "subagents": {"allowAgents": ["hubu", "libu", "bingbu", "xingbu", "gongbu", "libu_hr", "hanlin"]}},
    {"id": "hubu",     "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "libu",     "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "bingbu",   "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "xingbu",   "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "gongbu",   "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "libu_hr",  "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "hanlin",   "default": False, "subagents": {"allowAgents": ["shangshu"]}},
    {"id": "zaochao",  "default": False, "subagents": {"allowAgents": []}},
]

agents_cfg = cfg.setdefault('agents', {})
agents_list = agents_cfg.get('list', [])

# 1. 过滤掉过时的 main agent
agents_list = [a for a in agents_list if a['id'] != 'main']

# 2. 确保所有 agent 都在列表中，并应用最新权限
existing_map = {a['id']: a for a in agents_list}

for ag in AGENTS:
    ag_id = ag['id']
    ws = str(pathlib.Path.home() / f'.openclaw/workspace-{ag_id}')
    
    if ag_id in existing_map:
        # 更新现有 Agent 的权限
        existing_map[ag_id]['subagents'] = ag['subagents']
        if ag.get('default'):
            existing_map[ag_id]['default'] = True
        else:
            existing_map[ag_id].pop('default', None)
    else:
        # 添加缺失的 Agent
        entry = {
            'id': ag_id, 
            'workspace': ws, 
            **{k:v for k,v in ag.items() if k!='id'}
        }
        agents_list.append(entry)

agents_cfg['list'] = agents_list
cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
PYEOF
  log "Agents 架构注册/更新完成（已移除 main）"
}

# ── Step 2: 初始化数据与同步 ──────────────────────────────────
sync_data() {
  info "执行首次数据同步与 SOUL.md 部署..."
  
  mkdir -p "$REPO_DIR/data"
  cd "$REPO_DIR"
  
  # 调用 python 脚本完成复杂的同步逻辑
  python3 scripts/sync_agent_config.py
  python3 scripts/refresh_live_data.py
  
  log "数据同步完成"
}

# ── Step 3: 前端构建 ──────────────────────────────────────────
build_ui() {
  if [ -d "$REPO_DIR/edict/frontend" ] && command -v npm &>/dev/null; then
    info "正在检测前端构建需求..."
    cd "$REPO_DIR/edict/frontend"
    if [ ! -d "node_modules" ]; then
        npm install --silent
    fi
    npm run build --silent
    cd "$REPO_DIR"
    log "前端看板构建成功"
  else
    warn "跳过前端构建 (npm 未找到或目录缺失)"
  fi
}

# ── Main ────────────────────────────────────────────────────
banner
check_deps
register_agents
sync_data
build_ui

echo -e "\n${GREEN}🏛️  三省六部系统安装/优化成功！${NC}"
echo "------------------------------------------------"
echo "启动建议："
echo "  1. 启动同步引擎:  bash scripts/run_loop.sh &"
echo "  2. 启动总控台:    python3 dashboard/server.py"
echo "  3. 访问看板:      http://127.0.0.1:7891"
echo "------------------------------------------------"
