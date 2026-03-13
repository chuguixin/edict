#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# 三省六部 · 一键安装脚本（仅 bailian 版）
# 适用于没有 baidu-int，只有 bailian（阿里云百炼）的 OpenClaw 实例
#
# 用法：
#   bash install_bailian.sh
#
# 会做什么：
#   1. 检查依赖（openclaw / python3 / node）
#   2. 备份现有 ~/.openclaw/openclaw.json
#   3. 向 openclaw.json 注入 bailian provider + 三省六部 agents 配置
#   4. 创建所有 workspace 目录，写入 SOUL.md
#   5. 初始化 data 目录
#   6. 构建 React 前端（需 Node.js 18+）
#   7. 首次数据同步
#   8. 重启 Gateway
# ══════════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  🏛️  三省六部 · OpenClaw 一键安装（bailian 版）  ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ── Step 0: 依赖检查 ─────────────────────────────────────────────
check_deps() {
  info "检查依赖..."

  command -v openclaw &>/dev/null || error "未找到 openclaw CLI。请先安装: https://openclaw.ai"
  log "OpenClaw: $(openclaw --version 2>/dev/null || echo 'OK')"

  command -v python3 &>/dev/null || error "未找到 python3"
  log "Python3: $(python3 --version)"

  [ -f "$OC_CFG" ] || error "未找到 $OC_CFG。请先运行 openclaw 完成初始化。"
  log "openclaw.json: $OC_CFG"
}

# ── Step 1: 备份 openclaw.json ───────────────────────────────────
backup_config() {
  BACKUP="$OC_CFG.bak.sansheng-$(date +%Y%m%d-%H%M%S)"
  cp "$OC_CFG" "$BACKUP"
  log "已备份配置: $BACKUP"
}

# ── Step 2: 注入 bailian provider + 三省六部 agents ──────────────
patch_openclaw_json() {
  info "注入 bailian provider + 三省六部 agent 配置..."

  python3 - "$OC_CFG" "$REPO_DIR" << 'PYEOF'
import json, sys, pathlib

cfg_path = pathlib.Path(sys.argv[1])
repo_dir = sys.argv[2]
cfg = json.loads(cfg_path.read_text())
home = str(pathlib.Path.home())

# ── 1. 注入 bailian provider ──────────────────────────────────────
providers = cfg.setdefault('models', {}).setdefault('providers', {})
if 'bailian' not in providers:
    providers['bailian'] = {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey":  "【请替换为本机 bailian apiKey】",
        "api": "openai-completions",
        "models": [
            {"id":"qwen3.5-plus",          "name":"qwen3.5-plus",          "reasoning":False,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":1000000,"maxTokens":65536},
            {"id":"qwen3-max-2026-01-23",   "name":"qwen3-max-2026-01-23",  "reasoning":False,"input":["text"],       "cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":262144, "maxTokens":65536},
            {"id":"qwen3-coder-next",        "name":"qwen3-coder-next",       "reasoning":False,"input":["text"],       "cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":262144, "maxTokens":65536},
            {"id":"qwen3-coder-plus",        "name":"qwen3-coder-plus",       "reasoning":False,"input":["text"],       "cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":1000000,"maxTokens":65536},
            {"id":"glm-5",                   "name":"glm-5",                   "reasoning":False,"input":["text"],       "cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":202752, "maxTokens":16384},
            {"id":"kimi-k2.5",              "name":"kimi-k2.5",              "reasoning":False,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":262144, "maxTokens":32768},
        ]
    }
    print("  + bailian provider 已注入")
else:
    print("  ~ bailian provider 已存在，跳过")

# ── 2. 注入三省六部 agents ────────────────────────────────────────
AGENTS = [
    {"id":"taizi",    "default":True,  "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3-max-2026-01-23",
     "allowAgents":["zhongshu","menxia","gongbu","bingbu","hubu","libu","xingbu","hanlin","shangshu","libu_hr"]},
    {"id":"zhongshu", "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3-max-2026-01-23", "allowAgents":[]},
    {"id":"menxia",   "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3.5-plus",          "allowAgents":[]},
    {"id":"shangshu", "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3-max-2026-01-23", "allowAgents":[]},
    {"id":"bingbu",   "default":False, "primary":"bailian/glm-5",             "fallback":"bailian/kimi-k2.5",             "allowAgents":[]},
    {"id":"hubu",     "default":False, "primary":"bailian/qwen3.5-plus",      "fallback":"bailian/glm-5",                 "allowAgents":[]},
    {"id":"libu",     "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3.5-plus",          "allowAgents":[]},
    {"id":"xingbu",   "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3-max-2026-01-23", "allowAgents":[]},
    {"id":"gongbu",   "default":False, "primary":"bailian/glm-5",             "fallback":"bailian/qwen3.5-plus",          "allowAgents":[]},
    {"id":"hanlin",   "default":False, "primary":"bailian/kimi-k2.5",         "fallback":"bailian/qwen3.5-plus",          "allowAgents":[]},
    {"id":"libu_hr",  "default":False, "primary":"bailian/qwen3.5-plus",      "fallback":"bailian/glm-5",
     "allowAgents":["gongbu","bingbu","hubu","libu","xingbu","hanlin"]},
    {"id":"zaochao",  "default":False, "primary":"bailian/glm-5",             "fallback":"bailian/qwen3.5-plus",          "allowAgents":[]},
]

agents_cfg  = cfg.setdefault('agents', {})
agents_list = agents_cfg.setdefault('list', [])
existing    = {a['id'] for a in agents_list}

# 确保 defaults.models 包含 bailian 模型
defaults_models = agents_cfg.setdefault('defaults', {}).setdefault('models', {})
for m in ["bailian/qwen3.5-plus","bailian/qwen3-max-2026-01-23","bailian/qwen3-coder-next",
          "bailian/qwen3-coder-plus","bailian/glm-5","bailian/kimi-k2.5"]:
    defaults_models.setdefault(m, {})

added = 0
for ag in AGENTS:
    aid = ag['id']
    ws  = f"{home}/.openclaw/workspace-{aid}"
    if aid not in existing:
        entry = {
            "id": aid,
            "workspace": ws,
            "model": {"primary": ag['primary'], "fallbacks": [ag['fallback']]},
            "subagents": {"allowAgents": ag['allowAgents']},
        }
        if ag['default']:
            entry['default'] = True
        agents_list.append(entry)
        added += 1
        print(f"  + added: {aid}")
    else:
        # 已存在的 agent，只更新模型（保留其他配置）
        for e in agents_list:
            if e['id'] == aid:
                e['model'] = {"primary": ag['primary'], "fallbacks": [ag['fallback']]}
                e.setdefault('subagents', {})['allowAgents'] = ag['allowAgents']
                if ag['default']:
                    e['default'] = True
        print(f"  ~ updated model: {aid}")

# tools & agentToAgent
cfg.setdefault('tools', {}).setdefault('agentToAgent', {})['enabled'] = True

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f"\n三省六部 agents 注入完成（新增 {added} 个）")
PYEOF

  log "openclaw.json 注入完成"
}

# ── Step 3: 创建 workspace + 写入 SOUL.md ────────────────────────
create_workspaces() {
  info "创建 Agent Workspace + 写入 SOUL.md..."

  AGENTS=(taizi zhongshu menxia shangshu hubu libu bingbu xingbu gongbu hanlin libu_hr zaochao)
  for agent in "${AGENTS[@]}"; do
    ws="$OC_HOME/workspace-$agent"
    mkdir -p "$ws/skills"

    if [ -f "$REPO_DIR/agents/$agent/SOUL.md" ]; then
      if [ -f "$ws/SOUL.md" ]; then
        cp "$ws/SOUL.md" "$ws/SOUL.md.bak.$(date +%Y%m%d-%H%M%S)"
      fi
      sed "s|__REPO_DIR__|$REPO_DIR|g" "$REPO_DIR/agents/$agent/SOUL.md" > "$ws/SOUL.md"
      log "SOUL.md → workspace-$agent"
    else
      warn "未找到 agents/$agent/SOUL.md，跳过"
    fi
  done
}

# ── Step 4: 初始化 data 目录 ─────────────────────────────────────
init_data() {
  info "初始化数据目录..."
  mkdir -p "$REPO_DIR/data"
  for f in live_status.json agent_config.json model_change_log.json; do
    [ -f "$REPO_DIR/data/$f" ] || echo '{}' > "$REPO_DIR/data/$f"
  done
  echo '[]' > "$REPO_DIR/data/pending_model_changes.json"
  if [ ! -f "$REPO_DIR/data/tasks_source.json" ]; then
    echo '[{"id":"JJC-DEMO-001","title":"🎉 系统初始化完成","org":"工部","state":"Done","now":"三省六部系统已就绪","eta":"-","block":"无","output":"","ac":"系统正常运行","flow_log":[]}]' \
      > "$REPO_DIR/data/tasks_source.json"
  fi
  log "数据目录: $REPO_DIR/data"
}

# ── Step 5: 构建前端 ─────────────────────────────────────────────
build_frontend() {
  info "构建 React 前端..."
  if ! command -v node &>/dev/null; then
    warn "未找到 node，跳过前端构建（看板将使用预构建版本）"
    return
  fi
  if [ -f "$REPO_DIR/edict/frontend/package.json" ]; then
    cd "$REPO_DIR/edict/frontend"
    npm install --silent 2>/dev/null || npm install
    npm run build
    cd "$REPO_DIR"
    [ -f "$REPO_DIR/dashboard/dist/index.html" ] && log "前端构建完成" || warn "前端构建可能失败，请手动检查"
  else
    warn "未找到 edict/frontend/package.json，跳过"
  fi
}

# ── Step 6: 首次数据同步 ─────────────────────────────────────────
first_sync() {
  info "首次数据同步..."
  cd "$REPO_DIR"
  REPO_DIR="$REPO_DIR" python3 scripts/sync_agent_config.py 2>/dev/null || warn "sync_agent_config 有警告，不影响运行"
  python3 scripts/refresh_live_data.py 2>/dev/null || warn "refresh_live_data 有警告，不影响运行"
  log "首次同步完成"
}

# ── Step 7: 重启 Gateway ─────────────────────────────────────────
restart_gateway() {
  info "重启 OpenClaw Gateway..."
  if openclaw gateway restart 2>/dev/null; then
    log "Gateway 重启成功"
  else
    warn "Gateway 重启失败，请手动执行: openclaw gateway restart"
  fi
}

# ── Step 8: 提示填写 apiKey ──────────────────────────────────────
remind_apikey() {
  echo ""
  echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  ⚠️  还差最后一步：填写 bailian apiKey            ${NC}"
  echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
  echo ""
  echo "  打开文件："
  echo "    $OC_CFG"
  echo ""
  echo "  找到这一行："
  echo '    "apiKey": "【请替换为本机 bailian apiKey】"'
  echo ""
  echo "  替换为你的真实 apiKey，保存后运行："
  echo "    openclaw gateway restart"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────────
banner
check_deps
backup_config
patch_openclaw_json
create_workspaces
init_data
build_frontend
first_sync
restart_gateway
remind_apikey

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉  三省六部安装完成！                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "启动："
echo "  1. bash scripts/run_loop.sh &      # 数据刷新循环"
echo "  2. python3 dashboard/server.py     # 看板服务器"
echo "  3. open http://127.0.0.1:7891      # 打开看板"
echo ""
