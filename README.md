# 三个 OpenClaw 协作模板包

三个 AI 协作框架：1号规划，2号执行，3号审查。

## 必读更新：推荐改成“部门制 + subagent”

旧模型仍可用，但现在更推荐：

- 1号作为**指挥中枢**，内部可调用 subagent 做分析、拆解、排优先级
- 2号作为**执行部门**，内部可调用 subagent 做小步实现和检查
- 3号作为**质量与审计部门**，内部可调用 subagent 做审查和风险分析

核心思想：

- 不把每个 OpenClaw 限死成一个窄动作
- 而是给每个 OpenClaw 一个大的部门职责范围
- 所有内部 subagent 周期的外部结果都落到仓库文件

推荐任务包结构：

- `task-card.md`
- `execution-checklist.md`
- `test-plan.md`

推荐执行回写：

- 产物文件
- `HANDOFF.md`
- `STATUS-REPORT.md`

推荐记忆结构：

- `memory/agent-x/short-term/`
- `memory/agent-x/mid-term/`
- `memory/agent-x/long-term/`

## Practical Docs

If you want to run this as a real multi-machine system rather than only reuse the templates, read:

- `PRACTICAL-RUNBOOK.md`
- `TESTING-DEBUG-THREATS.md`
- `FEISHU-GROUP-DRILL.md`
- `scripts/OpenClaw-Validate-Reset.ps1`
- `config/OpenClaw-Hosts.example.ps1`

## 核心角色

- **1号**：架构师。读需求，写架构，发任务卡。
- **2号**：执行者。读任务卡，执行，产出结果 + handoff 说明。
- **3号**：检验室。审查执行结果，通过则删 task 并汇报 1号，不通过则打回。

## 极简协作规则

### 保留层（长期）
- `00_input/` — 用户的需求输入
- `10_architecture/` — 架构设计（1号维护）
- `30_execution/` — 执行结果（2号产出）
- `40_review/` — 审查报告（3号产出）

### 临时层（一次性的）
- `20_tasks/` — 任务卡（1号发出，3号审查后删除）

### 任务生命周期

```
1号：读 00_input/ → 调用内部 subagent 拆解 → 写 10_architecture/ → 发 20_tasks/
2号：读 20_tasks/ → 只做当前最小步骤 → 写 30_execution/（含 HANDOFF.md 和 STATUS-REPORT.md）
3号：读 1号指令 + 2号结果 + handoff + status → 写 40_review/
     ├── 通过当前批次 → 告诉 1号发下一小步，必要时删 task
     └── 不通过 → 打回，1号更新 architecture / checklist / test plan
```

### 角色分工

**1号（架构师）**
- 读 `00_input/`
- 写/改 `10_architecture/`（保留，不删）
- 发 `20_tasks/`（临时调度文件）
- 收到 review 后，更新 architecture，发新 task

**2号（执行者）**
- 读 `20_tasks/` 任务卡
- 执行任务
- 产出写到 `30_execution/`
- 必须附带 `HANDOFF.md`（给3号的检查说明）
- **不删 task**（3号删）

**3号（检验室）**
- 读 1号指令（`10_architecture/`）
- 读 2号结果（`30_execution/`）
- 读 2号的 handoff 说明
- 审查，产出 `40_review/`
- 通过 → 删 task，汇报 1号
- 不通过 → 打回，1号发新 task

### HANDOFF.md（2号必须写）

告诉 3号：
- 我改了什么
- 看哪里
- 哪块最容易出问题
- 哪些地方需要重点审

### 防重复原则

- task 用完就删（3号负责）
- 不复用已完成的 task
- 有新问题就发新 task
- 不靠旧 task 反复循环
- Architecture 保留，task 一次性

### 记忆

每个 agent 建议明确保留三层：
1. `short-term/`：当天流水账、当前阻塞、临时发现
2. `mid-term/`：当前任务/里程碑总结、滚动摘要
3. `long-term/`：长期浓缩记忆、稳定规则、反复踩坑

---

## 一句话总结

**Architecture 是长期控制面，Task Packet 是一次性调度票据，Status Report 是回传给 1号的下一步依据。**

## 部署

三个独立 workspace，clone 同一个仓库，各自放自己的 `AGENTS.md`。

详细说明见 `templates/deployment-layout.md`。
