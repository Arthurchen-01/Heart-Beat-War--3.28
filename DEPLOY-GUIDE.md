# 多 Agent 协作部署指南

> 基于 Heart-Beat-War 模板，3 个 Agent 通过 GitHub 仓库协作完成软件开发任务。

---

## 必读更新：当前推荐运行模式

这份部署指南原本默认的是线性工位制：

- 1号写架构
- 2号执行
- 3号审查

现在更推荐升级成“部门制 + subagent”：

- **1号 = 指挥中枢**
  负责 intake、分析、拆解、排优先级、写任务包、决定下一步最小指令。
- **2号 = 执行部门**
  负责按最小单位多次执行，必要时调用自己的 subagent 做实现和局部检查。
- **3号 = 质量与审计部门**
  负责审查当前批次、里程碑状态和风险，并告诉 1号下一步该继续、返工还是关闭。

### 为什么推荐这么改

因为真实项目里：

- 1号不应该只是“写一次架构就结束”
- 2号不应该一次性吞掉整个大任务
- 3号也不应该只在最后出现

更稳的方式是：

1. 1号发一个最小可执行任务包
2. 2号完成一个小步骤
3. 2号回写状态报告
4. 3号审当前批次
5. 1号发下一条最小指令

### 新的任务包结构

推荐每个 `20_tasks/TASK-xxx/` 至少包含：

- `task-card.md`
- `execution-checklist.md`
- `test-plan.md`

推荐每次执行后，`30_execution/` 至少包含：

- 本轮产物
- `HANDOFF.md`
- `STATUS-REPORT.md`

### 新的记忆结构

推荐每个 agent 明确保留三层记忆：

- `memory/agent-x/short-term/`
- `memory/agent-x/mid-term/`
- `memory/agent-x/long-term/`

含义分别是：

- 短期：当前天、当前步、临时阻塞
- 中期：当前任务、当前里程碑、滚动总结
- 长期：稳定规则、项目结构、长期经验

如果你正在搭新的三机协作系统，建议直接按这套新版模式搭，不必再严格照旧版“单工位”理解。

---

## 实战模式选择

在真的上线前，先明确你要的是哪种模式：

### 模式 A：混合渠道模式

- 1号接收飞书指令
- 2号、3号通过共享仓库协作
- 2号、3号可以不在同一个聊天渠道

优点：

- 更容易先跑通

限制：

- 你未必能在同一个飞书群里看到 2号和 3号各自直接汇报

### 模式 B：单飞书群聊模式

- 1号、2号、3号都接入飞书
- 三个实例都能在同一个飞书群里收发消息
- 共享仓库仍然是唯一协作总线

这是你想实现“我在飞书里给本地下指令，然后别的机器去做事，最后在群里汇报进度”时最推荐的模式。

要实现它，必须额外满足：

- 三台机器都接入飞书，而不是混用微信
- 群聊已加入 allowlist 或等效白名单
- 三个实例都已和目标群完成过消息配对
- heartbeat 不是只回 `HEARTBEAT_OK`，而是真的会扫仓库并执行

更完整的上线说明见：

- `PRACTICAL-RUNBOOK.md`
- `TESTING-DEBUG-THREATS.md`

---

## 架构总览

```
本地（Windows）        二哥（VM-0-7-ubuntu）      三哥（VM-0-5-ubuntu）
┌─────────────┐      ┌──────────────────┐      ┌──────────────────┐
│  Agent 1    │      │     Agent 2      │      │     Agent 3      │
│  总架构师    │      │     执行者        │      │     审查者        │
│             │      │                  │      │                  │
│ 读需求      │      │ 读任务卡          │      │ 读全部           │
│ 写架构      │      │ 执行代码          │      │ 写审查报告        │
│ 拆任务卡    │      │ 写执行结果        │      │ 批准/打回         │
│ 用飞书      │      │ 用飞书或微信       │      │ 用飞书或微信       │
│ 模型最好    │      │ 模型可以便宜点    │      │ 模型中等          │
└──────┬──────┘      └────────┬─────────┘      └────────┬─────────┘
       │                      │                          │
       └──────────────────────┼──────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   GitHub 仓库      │
                    │   （共享任务板）    │
                    │                   │
                    │  00_input/        │  ← 用户写需求
                    │  10_architecture/ │  ← Agent 1 写
                    │  20_tasks/        │  ← Agent 1 写，Agent 3 删
                    │  30_execution/    │  ← Agent 2 写
                    │  40_review/       │  ← Agent 3 写
                    └───────────────────┘
```

## 协作流程

```
Agent 1（本地）: 读 00_input/ → 写 10_architecture/ → 写 20_tasks/task-xxx.md
                                              ↓
Agent 2（二哥）: git pull → 发现新任务卡 → 执行 → 写 30_execution/ → git push
                                              ↓
Agent 3（三哥）: git pull → 看到执行结果 → 审查 → 写 40_review/
              ↓ 通过                    ↓ 不通过
         删 task 卡                  通知 Agent 1 重新拆任务
```

## 先回答一个关键问题

### 我能不能只在飞书里给本地端下一条指令，然后它驱动其他机器工作，并在群聊里汇报？

可以，但这不是“实时远程控制”，而是“飞书 intake + 仓库调度 + heartbeat 执行”。

真正链路是：

1. 你在飞书联系 1号
2. 1号把指令写进共享仓库
3. 2号与 3号通过 heartbeat 发现新任务和新状态
4. 2号执行、3号审查
5. 进度通过仓库回传，必要时再由飞书播报

如果你要求“同一个飞书群里实时看到多台机器各自汇报”：

- 推荐三台都接飞书
- 或者让 1号统一汇总 2号和 3号的结果后播报

如果 2号或 3号使用微信，那么“同一个飞书群统一汇报”就需要额外转发层，不是默认能力。

---

## 第一步：准备 GitHub 仓库

1. 创建一个私有仓库（或使用已有仓库）
2. 创建以下目录结构：

```
项目仓库/
├── 00_input/           # 用户写需求
│   └── requirement.md
├── 10_architecture/    # Agent 1 写架构
├── 20_tasks/           # Agent 1 写任务卡
├── 30_execution/       # Agent 2 写执行结果
├── 40_review/          # Agent 3 写审查报告
└── system/
    ├── workflow-rules.md
    └── naming-rules.md
```

3. 每台机器都 clone 这个仓库
4. 配置 git 凭证（每台机器都要能 push）：

```bash
git config --global user.name "agent-x"
git config --global user.email "your@email.com"
# 用 token 推送
git remote set-url origin https://<your-token>@github.com/<owner>/<repo>.git
```

---

## 第二步：本地（Windows）— Agent 1 总架构师

### 2.1 安装 OpenClaw

```powershell
# 如果还没装
npm install -g openclaw

# 验证
openclaw --version
```

### 2.2 配置 OpenClaw

编辑 `C:\Users\25472\.config\kilo\openclaw.json`（或 `~/.openclaw/openclaw.json`）：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "claude/claude-sonnet-4-6"
      },
      "workspace": "C:/Users/25472/.openclaw/workspace-agent1",
      "heartbeat": {
        "every": "5m",
        "target": "feishu",
        "directPolicy": "allow",
        "lightContext": true
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "<你的飞书 App ID>",
      "appSecret": "<你的飞书 App Secret>"
    }
  }
}
```

### 2.3 创建 Agent 1 的 Workspace

```powershell
# 创建 workspace 目录
mkdir C:\Users\25472\.openclaw\workspace-agent1

# clone 项目仓库
cd C:\Users\25472\.openclaw\workspace-agent1
git clone https://github.com/<owner>/<repo>.git project

# 创建 AGENTS.md（从模板复制）
copy project\templates\agent1-AGENTS.md AGENTS.md
```

### 2.4 AGENTS.md 内容（Agent 1 专用）

```markdown
# Agent 1 — 总架构师

## 你的唯一职责
1. 读取 `project/00_input/` 里的需求
2. 写架构方案到 `project/10_architecture/`
3. 拆任务卡到 `project/20_tasks/`
4. 读 `project/40_review/` 的审查报告
5. 收到 review 打回时，修改架构，重新拆任务

## 你能写的目录
- `project/10_architecture/`
- `project/20_tasks/`
- `memory/`

## 你不能碰的
- 不要直接改 `00_input/`
- 不要执行代码
- 不要写 `30_execution/`
- 不要写 `40_review/`

## 每次启动前先读
- `project/00_input/`（需求）
- `project/40_review/`（审查反馈，如果有）
- `memory/MEMORY.md`

## 工作原则
- 先定目标，再拆步骤，再分配任务
- 每次只拆 2-3 个小任务
- 需求变了要重新评估架构
- 收到 review 打回时，先看审查意见再改

## Git 操作
- 每次写完文件后：`git add . && git commit -m "agent1: 架构/任务更新" && git push`
- 每次开工前：`git pull`
```

### 2.5 创建 HEARTBEAT.md

```markdown
# Heartbeat Checklist (Agent 1 / 本地)

## 每次心跳检查

1. **git pull** 拉取最新代码
2. **检查 00_input/** 是否有新需求
3. **检查 40_review/** 是否有审查打回
4. **有新需求？** → 写架构 → 拆任务卡 → git push
5. **有打回？** → 修改架构 → 重新拆任务 → git push
6. **都没事？** → HEARTBEAT_OK
```

### 2.6 启动

```powershell
openclaw gateway
```

---

## 第三步：二哥（VM-0-7-ubuntu）— Agent 2 执行者

### 3.1 当前状态

- 系统：Ubuntu 24.04
- Node.js：v22.22.2
- OpenClaw：已安装（pnpm）
- 渠道：飞书
- Gateway 端口：20696
- Gateway 进程：已有，需要重启

### 3.2 配置 OpenClaw

编辑 `~/.openclaw/openclaw.json`，确保以下配置：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "claude/claude-sonnet-4-6"
      },
      "workspace": "/root/.openclaw/workspace-agent2",
      "heartbeat": {
        "every": "3m",
        "target": "feishu",
        "directPolicy": "allow",
        "lightContext": true,
        "isolatedSession": true,
        "prompt": "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        "ackMaxChars": 300
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "cli_a94d2548eb21dcd3",
      "appSecret": "h40WKiw5STFPR4PPprXVCbIYpgAS7WYc",
      "domain": "feishu",
      "heartbeat": {
        "showOk": true,
        "showAlerts": true,
        "useIndicator": true
      }
    }
  }
}
```

### 3.3 创建 Agent 2 的 Workspace

```bash
# 创建 workspace 目录
mkdir -p /root/.openclaw/workspace-agent2

# clone 项目仓库
cd /root/.openclaw/workspace-agent2
git clone https://github.com/<owner>/<repo>.git project

# 配置 git 凭证
cd project
git config user.name "agent-2"
git config user.email "agent2@example.com"
```

### 3.4 AGENTS.md 内容（Agent 2 专用）

```markdown
# Agent 2 — 执行者

## 你的唯一职责
1. 读取 `project/20_tasks/` 中当前要执行的任务
2. 参考 `project/00_input/` 和 `project/10_architecture/` 理解上下文
3. 执行任务，把结果写到 `project/30_execution/`
4. 写 HANDOFF.md（给 Agent 3 的交接说明）

## 你能写的目录
- `project/30_execution/`
- `memory/`

## 你不能碰的
- 不要改 `00_input/`
- 不要写 `10_architecture/`
- 不要删除任务卡（Agent 3 删除）

## 每次启动前先读
- `project/20_tasks/`（当前任务）
- `project/10_architecture/`（架构）
- `project/00_input/`（原始需求）
- `memory/MEMORY.md`

## 工作原则
- 严格按任务卡要求执行
- 有不确定的地方写执行备忘注释
- 完成后写清楚做了什么、没做什么
- 不要偷偷扩大任务范围

## Git 操作
- 每次写完文件后：`git add . && git commit -m "agent2: 任务执行完成" && git push`
- 每次开工前：`git pull`

## HANDOFF.md 格式
写到 `project/30_execution/HANDOFF.md`，包含：
- 我做了什么
- 没做什么
- 哪些地方需要重点看
- 哪些地方可能有问题
```

### 3.5 创建 HEARTBEAT.md

```markdown
# Heartbeat Checklist (Agent 2 / 二哥)

## 每次心跳检查

1. **git pull** 拉取最新代码
2. **扫描 20_tasks/** 是否有新任务卡
3. **有新任务？** → 执行 → 写 30_execution/ + HANDOFF.md → git push
4. **30_execution/ 已有结果？** → 不重复执行，等 Agent 3 审查
5. **更新日志** → memory/daily/$(date +%Y-%m-%d).md
6. **没有就 HEARTBEAT_OK**
```

### 3.6 清理并重启 Gateway

```bash
# 1. 修复 cron jobs.json
printf '{"version":1,"jobs":[]}' > ~/.openclaw/cron/jobs.json

# 2. 杀掉旧的 gateway 进程
pkill -f openclaw-gateway
sleep 3

# 3. 重启
openclaw gateway --port 20696 &

# 4. 等启动完成后，在飞书上发一条消息让 target: "last" 记住你的聊天
# 5. 等 3 分钟看 heartbeat 能不能到飞书
```

### 3.7 验证

```bash
# 检查 heartbeat 是否启动
cat /tmp/openclaw/openclaw-2026-03-29.log | grep -i heartbeat

# 应该看到：
# [heartbeat] started
# heartbeat: {"intervalMs": 180000}
```

---

## 第四步：三哥（VM-0-5-ubuntu）— Agent 3 审查者

### 4.1 当前状态

- 系统：Linux
- 渠道：微信（openclaw-weixin）
- 模型：openrouter/xiaomi/mimo-v2-pro

### 4.2 配置 OpenClaw

编辑 `~/.openclaw/openclaw.json`：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/xiaomi/mimo-v2-pro"
      },
      "workspace": "/root/.openclaw/workspace-agent3",
      "heartbeat": {
        "every": "5m",
        "target": "last",
        "directPolicy": "allow",
        "lightContext": true,
        "isolatedSession": true,
        "prompt": "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        "ackMaxChars": 300
      }
    }
  }
}
```

**注意：不要在顶层放 `heartbeat` 键，必须放在 `agents.defaults.heartbeat` 下面。**

### 4.3 创建 Agent 3 的 Workspace

```bash
# 创建 workspace 目录
mkdir -p /root/.openclaw/workspace-agent3

# clone 项目仓库
cd /root/.openclaw/workspace-agent3
git clone https://github.com/<owner>/<repo>.git project

# 配置 git 凭证
cd project
git config user.name "agent-3"
git config user.email "agent3@example.com"
```

### 4.4 AGENTS.md 内容（Agent 3 专用）

```markdown
# Agent 3 — 审查者

## 你的唯一职责
1. 读取 `project/00_input/`（原始需求）
2. 读取 `project/10_architecture/`（架构方案）
3. 读取 `project/20_tasks/`（任务卡）
4. 读取 `project/30_execution/`（执行结果 + HANDOFF.md）
5. 检查是否偏离需求，写审查报告到 `project/40_review/`
6. 审查通过 → 删除对应 task 文件
7. 审查不通过 → 写审查报告，通知 Agent 1

## 你能写的目录
- `project/40_review/`
- `memory/`

## 你不能碰的
- 不要改 `10_architecture/`
- 不要改 `30_execution/`
- 不要改用户的需求

## 每次启动前先读
- `project/00_input/`（原始需求）
- `project/10_architecture/`（架构）
- `project/20_tasks/`（任务卡）
- `project/30_execution/`（执行结果）
- `memory/MEMORY.md`

## 审查要点
- 方向是否正确
- 内容是否完整
- 执行是否达标
- 是否有遗漏、重复、偏离

## Git 操作
- 每次写完文件后：`git add . && git commit -m "agent3: 审查完成" && git push`
- 每次开工前：`git pull`
```

### 4.5 创建 HEARTBEAT.md

```markdown
# Heartbeat Checklist (Agent 3 / 三哥)

## 每次心跳检查

1. **git pull** 拉取最新代码
2. **扫描 projects/** 下所有项目
3. **30_execution/ 有新文件？** → 触发完整审查流程：
   - 读 00_input/（需求）
   - 读 10_architecture/（架构）
   - 读 20_tasks/（任务卡）
   - 读 30_execution/（执行结果 + handoff）
   - 写 40_review/review-YYYYMMDD-HHMM.md
   - 审查通过 → 删 task 文件
   - 审查不通过 → 写报告说明问题
4. **没有就 HEARTBEAT_OK**
```

### 4.6 重启 Gateway

```bash
# 检查配置是否正确（不能有顶层 heartbeat 键）
python3 -c "
import json
with open('/root/.openclaw/openclaw.json') as f:
    d = json.load(f)
if 'heartbeat' in d:
    print('错误：heartbeat 在顶层，需要移到 agents.defaults 下')
else:
    print('配置正确')
"

# 重启 gateway
pkill -f openclaw-gateway
sleep 3
openclaw gateway &

# 在微信上发一条消息，让 target: "last" 记住你的聊天
# 等 5 分钟看 heartbeat
```

---

## 常见问题

### Q: Heartbeat 消息发不出来（delivered: false）

检查顺序：
1. `openclaw.json` 里 heartbeat 的 `target` 是否正确（飞书用 `feishu`，微信用 `last`）
2. 是否有 cron job 和 built-in heartbeat 冲突（删掉 cron job 只用 built-in）
3. 重启后先在渠道上发一条消息，让 `target: "last"` 记住你的聊天

### Q: Gateway 启动报 "already running under systemd"

```bash
pkill -f openclaw-gateway
sleep 3
openclaw gateway &
```

### Q: Cron jobs.json 解析失败

```bash
printf '{"version":1,"jobs":[]}' > ~/.openclaw/cron/jobs.json
```

### Q: 心跳频率建议

| Agent | 建议频率 | 说明 |
|-------|---------|------|
| Agent 1（架构师） | 5 分钟 | 架构不需要频繁更新 |
| Agent 2（执行者） | 3 分钟 | 有任务时尽快执行 |
| Agent 3（审查者） | 5 分钟 | 等 Agent 2 写完再审查 |

### Q: 任务锁

如果同时有多个 Agent 要写同一个项目，在项目根目录放一个 `project-lock.md`：

```markdown
# Project Lock
- 锁定者：Agent 2
- 锁定时间：2026-03-29 12:00
- 任务：task-001 执行中
```

---

## 部署检查清单

### 本地（Agent 1）
- [ ] OpenClaw 安装完成
- [ ] openclaw.json 配置正确（model, workspace, heartbeat）
- [ ] 飞书渠道配置正确
- [ ] workspace 目录创建，项目 clone 完成
- [ ] AGENTS.md 写入（agent1 模板）
- [ ] HEARTBEAT.md 写入
- [ ] git 凭证配置（能 push）
- [ ] Gateway 启动，飞书能收到消息
- [ ] Heartbeat 能到飞书

### 二哥（Agent 2）
- [ ] OpenClaw 已安装
- [ ] openclaw.json 配置正确（重点：heartbeat.target = "feishu"）
- [ ] 没有冲突的 cron job（已清空）
- [ ] workspace 目录创建，项目 clone 完成
- [ ] AGENTS.md 写入（agent2 模板）
- [ ] HEARTBEAT.md 写入
- [ ] git 凭证配置（能 push）
- [ ] Gateway 重启成功，飞书能收到消息
- [ ] Heartbeat 能到飞书

### 三哥（Agent 3）
- [ ] openclaw.json 修复（heartbeat 不能在顶层）
- [ ] openclaw.json 配置正确（heartbeat.target = "last"）
- [ ] workspace 目录创建，项目 clone 完成
- [ ] AGENTS.md 写入（agent3 模板）
- [ ] HEARTBEAT.md 写入
- [ ] git 凭证配置（能 push）
- [ ] Gateway 重启成功，微信能收到消息
- [ ] Heartbeat 能到微信

### 整体验证
- [ ] 三个 Agent 都能 git pull/push 同一个仓库
- [ ] Agent 1 写了任务卡到 20_tasks/
- [ ] Agent 2 检测到任务卡，执行后写到 30_execution/
- [ ] Agent 3 检测到执行结果，写审查报告到 40_review/
- [ ] Agent 3 审查通过后删除了 task 文件
- [ ] Agent 1 看到审查结果，开始下一轮任务

---

## 目录速查

| 机器 | Workspace | 渠道 | Heartbeat 频率 |
|------|-----------|------|---------------|
| 本地 | `C:\Users\25472\.openclaw\workspace-agent1` | 飞书 | 5m |
| 二哥 | `/root/.openclaw/workspace-agent2` | 飞书 | 3m |
| 三哥 | `/root/.openclaw/workspace-agent3` | 微信 | 5m |

| 文件 | 谁写 | 谁读 |
|------|------|------|
| `00_input/` | 用户 | Agent 1, 2, 3 |
| `10_architecture/` | Agent 1 | Agent 2, 3 |
| `20_tasks/` | Agent 1 写，Agent 3 删 | Agent 2, 3 |
| `30_execution/` | Agent 2 | Agent 3 |
| `40_review/` | Agent 3 | Agent 1 |
