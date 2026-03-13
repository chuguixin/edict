<h1 align="center">⚔️ 三省六部 · Edict</h1>

<p align="center">
  <strong>Fork 自 cft0808/edict · 对原有多 Agent 架构做了两层扁平化重构，新增翰林院，升级总控台动态组织架构图</strong>
</p>

<p align="center">
  <a href="https://github.com/cft0808/edict">
    <img src="https://img.shields.io/badge/Forked_from-cft0808/edict-blue?style=flat-square" alt="Forked from cft0808/edict">
  </a>
  <img src="https://img.shields.io/badge/OpenClaw-Required-blue?style=flat-square" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Agents-13_Specialized-8B5CF6?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/Dashboard-Real--time-F59E0B?style=flat-square" alt="Dashboard">
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Frontend-React_18-61DAFB?style=flat-square&logo=react&logoColor=white" alt="React">
  <img src="https://img.shields.io/badge/Backend-stdlib_only-EC4899?style=flat-square" alt="Zero Backend Dependencies">
</p>

<p align="center">
  <a href="#-demo">🎬 看 Demo</a> ·
  <a href="#-快速体验">🚀 快速体验</a> ·
  <a href="#-架构">🏛️ 架构</a> ·
  <a href="#-功能全景">📋 看板功能</a> ·
  <a href="docs/task-dispatch-architecture.md">📚 架构文档</a> ·
  <a href="CONTRIBUTING.md">参与贡献</a>
</p>

---

## 🔀 这个 Fork 做了什么

本 fork 在原版三省六部架构的基础上，针对执行效率和信息损耗做了深度优化。

### ① 架构重构：从三层流水线到两层扁平

原架构采用严格的流水线模式（太子 -> 中书 -> 门下 -> 尚书 -> 六部），每道圣旨都必须走完所有环节。这在处理简单任务时延迟较高，且尚书省容易成为信息传递的瓶颈。

我们认为，古代三省六部的分层是权力制衡的产物，不是效率最优解。AI Agent 不需要权力制衡，需要的是职责清晰和通信最短路径。

**新设计：**
- **太子作为唯一入口和全程协调中心**，直接指挥所有 Agent。
- **三省（中书、门下、尚书）转为“按需调用的专家”**。简单任务直接由太子分派给六部，复杂任务才请三省出面规划或审核。
- **六部直接向太子汇报**，消除了尚书省的中间人角色，信息传递路径缩短 50%。

### ② 新增翰林院 Agent

| 字段 | 值 |
|---|---|
| ID | `hanlin` |
| 职责 | 调研 / 搜索 / 信息收集 |
| 定位 | 太子直属，并行执行层 |

原六部侧重于“执行”，缺乏专职“调研”的角色。复杂任务往往需要先调研再执行，翰林院的加入填补了这一空白。

### ③ 总控台升级：动态组织架构图

省部调度页新增实时 SVG 组织架构图：
- **实时状态感知**：每个节点通过颜色和动画展示状态（running 绿色脉冲 / idle / offline / unconfigured）以及最后活跃时间。
- **动态连线**：SVG 连线准确反映两层扁平布局，不再有误导性的三层视觉。
- **流光粒子动画**：当有活跃协同任务时，对应连线会变亮并产生流光效果（SVG animateMotion），直观展示数据流向。

---

## 🎬 Demo

<p align="center">
  <video src="docs/Agent_video_Pippit_20260225121727.mp4" width="100%" autoplay muted loop playsinline controls>
    您的浏览器不支持视频播放，请查看下方 GIF 或 <a href="docs/Agent_video_Pippit_20260225121727.mp4">下载视频</a>。
  </video>
  <br>
  <sub>🎥 三省六部 AI 多 Agent 协作全流程演示</sub>
</p>

<details>
<summary>📸 GIF 预览（加载更快）</summary>
<p align="center">
  <img src="docs/demo.gif" alt="三省六部 Demo" width="100%">
  <br>
  <sub>飞书下旨 → 太子分拣 → 中书省规划 → 门下省审议 → 六部并行执行 → 奏折回报（30 秒）</sub>
</p>
</details>

---

## 🤔 为什么是三省六部？

大多数 Multi-Agent 框架的套路是让几个 AI 自己聊，聊完把结果给你。你拿到一坨不知道经过了什么处理的结果，无法复现，也无法干预。

三省六部的思路完全不同。我们借鉴了中国古代的制度智慧，核心在于**制度性审核**和**分权制衡**。

| | CrewAI | MetaGPT | AutoGen | **三省六部 (本 Fork)** |
|---|:---:|:---:|:---:|:---:|
| **审核机制** | ❌ 无 | ⚠️ 可选 | ⚠️ Human-in-loop | **✅ 门下省专职审核 · 可封驳** |
| **实时看板** | ❌ | ❌ | ❌ | **✅ 动态 SVG 架构图 + 看板** |
| **任务干预** | ❌ | ❌ | ❌ | **✅ 叫停 / 取消 / 恢复** |
| **流转审计** | ⚠️ | ⚠️ | ❌ | **✅ 完整奏折存档** |
| **两层扁平架构** | — | — | — | **✅ 消除中间层延迟** |

**门下省审核是杀手锏**：每一个复杂方案在执行前，必须经过门下省的质量评审。不合格的方案会被直接封驳（打回重做），确保执行层拿到的始终是高质量指令。1300 年前唐太宗就想明白了，不受制约的权力必然会出错。

---

## ✨ 功能全景

### 🏛️ 十三部制 Agent 架构
- **太子** 消息分拣：闲聊自动回复，旨意才建任务。
- **三省**（中书、门下、尚书）：按需负责规划、审议、汇总。
- **八部**（户、礼、兵、刑、工、翰林、吏 + 早朝官）：负责专项并行执行。
- 严格的权限矩阵：谁能给谁发消息，白纸黑字。
- 每个 Agent 独立 Workspace、独立 Skills、独立模型。
- **旨意数据清洗**：标题和备注自动剥离文件路径、元数据、无效前缀。

### 📋 军机处看板（10 个功能面板）

<table>
<tr><td width="50%">

**📋 旨意看板 · Kanban**
- 按状态列展示全部任务
- 省部过滤 + 全文搜索
- 心跳徽章（🟢活跃 🟡停滞 🔴告警）
- 任务详情 + 完整流转链
- 叫停 / 取消 / 恢复操作

</td><td width="50%">

**🔭 省部调度 · Monitor**
- 可视化各状态任务数量
- 部门分布横向条形图
- Agent 健康状态实时卡片
- **动态 SVG 组织架构图**

</td></tr>
<tr><td>

**📜 奏折阁 · Memorials**
- 已完成旨意自动归档为奏折
- 五阶段时间线：圣旨→中书→门下→六部→回奏
- 一键复制为 Markdown
- 按状态筛选

</td><td>

**📜 旨库 · Template Library**
- 9 个预设圣旨模板
- 分类筛选 · 参数表单 · 预估时间和费用
- 预览旨意 → 一键下旨

</td></tr>
<tr><td>

**👥 官员总览 · Officials**
- Token 消耗排行榜
- 活跃度 · 完成数 · 会话统计

</td><td>

**📰 天下要闻 · News**
- 每日自动采集科技/财经资讯
- 分类订阅管理 + 飞书推送

</td></tr>
<tr><td>

**⚙️ 模型配置 · Models**
- 每个 Agent 独立切换 LLM
- 应用后自动重启 Gateway（~5秒生效）

</td><td>

**🛠️ 技能配置 · Skills**
- 各省部已安装 Skills 一览
- 查看详情 + 添加新技能

</td></tr>
<tr><td>

**💬 小任务 · Sessions**
- OC-* 会话实时监控
- 来源渠道 · 心跳 · 消息预览

</td><td>

**🎬 上朝仪式 · Ceremony**
- 每日首次打开播放开场动画
- 今日统计 · 3.5秒自动消失

</td></tr>
</table>

---

## 🖼️ 截图

### 旨意看板
![旨意看板](docs/screenshots/01-kanban-main.png)

<details>
<summary>📸 展开查看更多截图</summary>

### 省部调度
![省部调度](docs/screenshots/02-monitor.png)

### 任务流转详情
![任务流转详情](docs/screenshots/03-task-detail.png)

### 模型配置
![模型配置](docs/screenshots/04-model-config.png)

### 技能配置
![技能配置](docs/screenshots/05-skills-config.png)

### 官员总览
![官员总览](docs/screenshots/06-official-overview.png)

### 会话记录
![会话记录](docs/screenshots/07-sessions.png)

### 奏折归档
![奏折归档](docs/screenshots/08-memorials.png)

### 圣旨模板
![圣旨模板](docs/screenshots/09-templates.png)

### 天下要闻
![天下要闻](docs/screenshots/10-morning-briefing.png)

### 上朝仪式
![上朝仪式](docs/screenshots/11-ceremony.png)

</details>

---

## 🚀 快速体验

### Docker 一键启动

```bash
docker run -p 7891:7891 cft0808/sansheng-demo
```
打开 http://localhost:7891 即可体验军机处看板。

### 完整安装

#### 前置条件
- [OpenClaw](https://openclaw.ai) 已安装
- Python 3.9+
- macOS / Linux

#### 安装

```bash
git clone https://github.com/chuguixin/edict.git
cd edict
chmod +x install.sh && ./install.sh
```

安装脚本自动完成：
- ✅ 创建全量 Agent Workspace（含太子/吏部/早朝/翰林院）
- ✅ 写入各省部 SOUL.md（角色人格 + 工作流规则 + 数据清洗规范）
- ✅ 注册 Agent 及权限矩阵到 `openclaw.json`
- ✅ 构建 React 前端
- ✅ 初始化数据目录 + 首次数据同步
- ✅ 重启 Gateway 使配置生效

#### 启动

```bash
# 终端 1：数据刷新循环
bash scripts/run_loop.sh

# 终端 2：看板服务器
python3 dashboard/server.py

# 打开浏览器
open http://127.0.0.1:7891
```

---

## 🔄 跟踪上游更新

本项目会定期同步原作者的特性。你可以通过以下命令保持更新：

```bash
# 同步原作者 cft0808 的最新更新
git remote add upstream https://github.com/cft0808/edict.git
git fetch upstream
git merge upstream/main
```

---

## 🏛️ 架构

```
                        ┌──────────────────────────┐
                        │       👑 皇上（你）        │
                        └─────────────┬────────────┘
                                      │
                        ┌─────────────▼────────────┐
                        │       🤴 太子 (taizi)      │
                        │  分拣·协调·全程跟踪·唯一入口 │
                        └──┬──┬──┬──┬──┬──┬──┬──┬──┘
                           │  │  │  │  │  │  │  │  │
           ┌───────────────┘  │  │  └──┼──┼──┼──┼──┼──────────────────────┐
           │ 按需调用          │  │     │  │  │  │  │  并行执行             │
    ┌──────▼──┐  ┌────────▼┐  │  │ ┌──▼─┐┌─▼──┐┌─▼──┐┌─▼──┐┌─▼──┐┌──▼──┐│
    │📜 中书省│  │🔍 门下省 │  │  │ │💰户│ │📝礼││⚔️兵 ││⚖️刑 ││🔧工 ││📚翰││
    │方案设计 │  │方案Review│  │  │ │ 部 │ │ 部 ││ 部  ││ 部  ││ 部  ││林院││
    └─────────┘  └─────────┘  │  │ └────┘ └────┘└────┘└────┘└────┘└─────┘│
                        ┌──────▼──┐  └──────────────────────────────────────┘
                        │📮 尚书省│
                        │验收汇总 │
                        └─────────┘

    ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
    独立运行  👔 吏部 (libu_hr) · 系统巡检 · Agent 保活
```

### 各省部职责

| 部门 | ID | 职责 | 调用方式 |
|---|---|---|---|
| 🤴 **太子** | `taizi` | 分拣、协调、全程跟踪 | 唯一入口 |
| 📜 **中书省** | `zhongshu` | 方案设计、任务拆解 | 按需 |
| 🔍 **门下省** | `menxia` | 方案审议、质量把关 | 按需（极复杂任务） |
| 📮 **尚书省** | `shangshu` | 验收汇总、结果整合 | 按需 |
| 💰 **户部** | `hubu` | 数据处理、资源核算 | 并行执行 |
| 📝 **礼部** | `libu` | 文档编写、规范制定 | 并行执行 |
| ⚔️ **兵部** | `bingbu` | 代码开发、算法实现 | 并行执行 |
| ⚖️ **刑部** | `xingbu` | 安全审计、合规检查 | 并行执行 |
| 🔧 **工部** | `gongbu` | CI/CD、部署基建 | 并行执行 |
| 📚 **翰林院** | `hanlin` | 调研、搜索、信息收集 | 并行执行 |
| 👔 **吏部** | `libu_hr` | 系统巡检、Agent 保活 | 独立运行 |
| 🌅 **早朝官** | `zaochao` | 每日早朝、新闻聚合 | 定时运行 |

---

## 📁 项目结构

```
edict/
├── agents/                     # 13 个 Agent 的人格模板
│   ├── taizi/SOUL.md           # 太子 · 消息分拣
│   ├── zhongshu/SOUL.md        # 中书省 · 规划中枢
│   ├── menxia/SOUL.md          # 门下省 · 审议把关
│   ├── shangshu/SOUL.md        # 尚书省 · 调度大脑
│   ├── hubu/SOUL.md            # 户部 · 数据资源
│   ├── libu/SOUL.md            # 礼部 · 文档规范
│   ├── bingbu/SOUL.md          # 兵部 · 工程实现
│   ├── xingbu/SOUL.md          # 刑部 · 合规审计
│   ├── gongbu/SOUL.md          # 工部 · 基础设施
│   ├── hanlin/SOUL.md          # 翰林院 · 调研搜索
│   ├── libu_hr/                # 吏部 · 人事管理
│   └── zaochao/SOUL.md         # 早朝官 · 情报枢纽
├── dashboard/
│   ├── dashboard.html          # 军机处看板
│   ├── dist/                   # React 前端构建产物
│   └── server.py               # API 服务器
├── scripts/
│   ├── run_loop.sh             # 数据刷新循环
│   ├── kanban_update.py        # 看板 CLI
│   ├── skill_manager.py        # Skill 管理工具
│   └── ...                     # 其他同步脚本
├── tests/
│   └── test_e2e_kanban.py      # 端到端测试
├── data/                       # 运行时数据
├── docs/
│   ├── task-dispatch-architecture.md  # 详细架构文档
│   └── ...
├── install.sh                  # 一键安装脚本
├── CONTRIBUTING.md             # 贡献指南
└── LICENSE                     # MIT License
```

---

## 🎯 使用方法

### 向 AI 下旨

通过 Feishu / Telegram / Signal 给太子发消息：

```
给我设计一个用户注册系统，要求：
1. RESTful API（FastAPI）
2. PostgreSQL 数据库
3. JWT 鉴权
4. 完整测试用例
5. 部署文档
```

**然后坐好，看戏：**

1. 🤴 太子接旨，识别为任务，分派给相关部门。
2. 📜 中书省（按需）规划子任务分配方案。
3. 🔍 门下省（按需）审议，通过或封驳打回。
4. ⚔️ 各部并行执行，进度实时可见。
5. 🤴 太子汇总结果，回奏给你。

全程可在**军机处看板**实时监控，随时可以**叫停、取消、恢复**。

---

## 🔧 技术亮点

| 特点 | 说明 |
|------|------|
| **React 18 前端** | TypeScript + Vite + Zustand 状态管理，13 个功能组件 |
| **纯 stdlib 后端** | `server.py` 基于 `http.server`，零依赖，同时提供 API + 静态文件服务 |
| **Agent 思考可视** | 实时展示 Agent 的 thinking 过程、工具调用、返回结果 |
| **动态 SVG 架构图** | 实时反映 Agent 状态与协同流向 |
| **一键安装** | `install.sh` 自动完成全部配置 |
| **15 秒同步** | 数据自动刷新，看板倒计时显示 |
| **远程 Skills 生态** | 从 GitHub/URL 一键导入能力 |

---

## 🔧 常见问题排查

<details>
<summary><b>❌ 任务总超时 / 下属完成了但无法传回太子</b></summary>

**症状**：各部已完成任务，但太子收不到回报，最终超时。

**排查步骤**：

1. **检查 Agent 注册状态**：
```bash
curl -s http://127.0.0.1:7891/api/agents-status | python3 -m json.tool
```
确认 `taizi` agent 的 `statusLabel` 是 `alive`。

2. **检查 Gateway 日志**：
```bash
ls /tmp/openclaw/ | tail -5
grep -i "error\|fail\|unknown" /tmp/openclaw/openclaw-*.log | tail -20
```

3. **常见原因**：
   - Agent ID 不匹配。
   - LLM provider 超时。
   - 僵尸 Agent 进程（运行 `ps aux | grep openclaw` 检查）。

</details>

<details>
<summary><b>❌ Docker: exec format error</b></summary>

**症状**：`exec /usr/local/bin/python3: exec format error`

**原因**：镜像架构与主机架构不匹配。

**解决**：
```bash
# 指定平台
docker run --platform linux/amd64 -p 7891:7891 cft0808/sansheng-demo
```

</details>

---

## 🗺️ Roadmap

### Phase 1 — 核心架构 ✅
- [x] 十三部制 Agent 架构（新增翰林院）
- [x] 两层扁平架构重构（消除中间层延迟）
- [x] 动态 SVG 组织架构图（实时状态 + 流光粒子）
- [x] 军机处实时看板（10 个功能面板）
- [x] 任务叫停 / 取消 / 恢复
- [x] 奏折系统（自动归档 + 五阶段时间线）
- [x] 圣旨模板库（9 个预设）
- [x] 太子消息分拣（闲聊自动回复 / 旨意建任务）
- [x] 端到端测试覆盖
- [x] React 18 前端重构
- [x] Agent 思考过程可视化

### Phase 2 — 制度深化 🚧
- [ ] 御批模式（人工审批 + 一键准奏/封驳）
- [ ] 功过簿（Agent 绩效评分体系）
- [ ] 急递铺（Agent 间实时消息流可视化）
- [ ] 国史馆（知识库检索 + 引用溯源）

---

## 🤝 参与贡献

欢迎任何形式的贡献！详见 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## ⭐ Star History

如果这个项目让你会心一笑，请给个 Star ⚔️

[![Star History Chart](https://api.star-history.com/svg?repos=cft0808/edict&type=Date)](https://star-history.com/#cft0808/edict&Date)

---

## 📮 朕的邸报——公众号

> 古有邸报传天下政令，今有公众号聊 AI 架构。

<p align="center">
  <img src="docs/assets/wechat-qrcode.jpg" width="220" alt="公众号二维码 · cft0808">
  <br><br>
  <b>👆 扫码关注「cft0808」—— 朕的技术邸报</b>
</p>

---

本项目 fork 自 [cft0808/edict](https://github.com/cft0808/edict)（MIT License）。
感谢原作者的三省六部架构设计，本 fork 在此基础上持续演进。

---

<p align="center">
  <strong>⚔️ 以古制御新技，以智慧驾驭 AI</strong><br>
  <sub>Governing AI with the wisdom of ancient empires</sub>
</p>
