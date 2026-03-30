# 三个 OpenClaw 协作模板包

这个模板包把你的想法收敛成一个更稳的结构：

- 1号：首席架构师，负责理解需求、拆目标、发任务
- 2号：执行者，负责按任务产出结果
- 3号：检验室，负责对照需求和架构指令做审查与总结

## 必读更新：2026-03-30 之后的推荐工作模式

上面那套“1号规划、2号执行、3号审查”的线性模型仍然能跑，但现在更推荐升级成下面这套：

- **1号不是单点架构师，而是指挥中枢**。
  它负责接收需求、调用自己的 subagent 做拆解、写任务包、决定下一步最小指令。
- **2号不是一次性交付工位，而是执行部门**。
  它也可以调用自己的 subagent，但对外只按最小单位多次执行，并持续回写状态报告给 1号。
- **3号不是只看最终结果，而是质量与审计部门**。
  它审当前批次、当前里程碑和风险，而不是只在最后给一个通过/打回。

换句话说：

- 每个 OpenClaw 实例都可以有自己的 subagent
- 但每个实例仍然负责一个大的“部门范围”
- 仓库只记录这些 subagent 周期的**外部可见结果**
- 这样既保留灵活性，也能控制 token 消耗

### 新的推荐控制循环

1. 用户把目标给 1号
2. 1号调用内部 subagent 做分析和拆解
3. 1号写：
   - 架构说明
   - 任务卡
   - 执行清单
   - 测试计划
4. 2号只完成当前最小的一步
5. 2号写：
   - 执行产物
   - handoff
   - status report
6. 3号审查当前批次
7. 3号告诉 1号下一步应该：
   - 继续发下一小步
   - 返工
   - 关闭任务
8. 1号再发下一个最小指令

### 新的任务包结构

推荐每个 `20_tasks/TASK-xxx/` 至少包含：

- `task-card.md`
- `execution-checklist.md`
- `test-plan.md`

推荐 `30_execution/` 至少包含：

- 本轮产物
- `HANDOFF.md`
- `STATUS-REPORT.md`

### 新的记忆结构

每个 agent 的记忆建议明确分成三层：

1. **短期记忆**：当前天、当前步、当前阻塞
2. **中期记忆**：当前任务、当前里程碑、滚动总结
3. **长期记忆**：稳定规则、项目结构、反复踩坑经验

推荐目录：

- `memory/agent-x/short-term/`
- `memory/agent-x/mid-term/`
- `memory/agent-x/long-term/`

## 实战文档

如果你不是只想看模板，而是要把系统实际跑起来，优先看这两份：

- `PRACTICAL-RUNBOOK.md`：实战运行手册，包含批次编号、任务目录约束、单飞书群聊模式前提
- `TESTING-DEBUG-THREATS.md`：测试方案、debug 顺序、潜在威胁模型

这样做的目的不是“多存文件”，而是：

- 上下文丢了还能恢复
- 人能随时查看
- agent 不需要每次都重复读超长聊天
- 长期降低 token 消耗

## 推荐原则

1. **仓库是唯一真相源**。不要让三个 AI 靠聊天互相传话，所有协作都落到文件。
2. **一个项目一个文件夹**。项目内可以再拆很多子任务，但不能把多个大项目混放。
3. **用户只写输入，不直接写执行状态**。用户主要维护 `00_input/`。
4. **架构师只写架构和任务，不直接产出最终执行件**。
5. **执行者只按任务卡干活，不改总体架构**。
6. **检验员只写审查报告和建议，不直接代替执行者交付**。
7. **记忆统一放在 `/memory/` 下，但按 agent 分开**。


## 部署上最重要的一条

**推荐三个 OpenClaw 各自使用不同的本地 workspace，并且这三个 workspace 都 clone 同一个 GitHub 仓库。**

原因很简单：OpenClaw 会把 workspace 根目录里的 `AGENTS.md`、`SOUL.md`、`TOOLS.md`、`USER.md` 作为 agent 的基础行为说明。如果三个角色共用一个 workspace，角色边界就会混在一起。

详细说明见 `templates/deployment-layout.md`。

## 推荐目录逻辑

- `projects/`：所有项目
- `memory/`：所有 agent 的记忆
- `system/`：全局规则、命名规范、状态流转规范

## 一个项目内部的推荐流转

1. 你把需求和资源放进 `00_input/`
2. 1号读取输入，调用内部 subagent 做拆解，产出 `10_architecture/` 与 `20_tasks/`
3. 1号在 `20_tasks/` 中写明任务卡、执行清单、测试计划
4. 2号读取任务包，只执行当前最小步骤，产出 `30_execution/`
5. 2号补写 `HANDOFF.md` 与 `STATUS-REPORT.md`
6. 3号对照 `00_input/`、`10_architecture/`、`20_tasks/`、`30_execution/` 产出 `40_review/`
7. 1号根据 status report 和 review 决定下一条最小指令，而不是一次性发完整大任务

## 状态建议

- `NEW`：刚创建需求
- `ARCHITECTED`：已完成架构拆解
- `EXECUTING`：执行中
- `REVIEWING`：审核中
- `ITERATING`：根据审核意见返工
- `DONE`：完成
- `BLOCKED`：阻塞

## 触发建议

- 新需求或需求更新：**优先用 GitHub webhook 或 GitHub Actions 触发 1号或 2号**
- 每 30 分钟巡检：**1号 heartbeat**
- 每日固定汇总：**cron**

## 关于“飞书下一条指令能否驱动全链路”

可以做到，但前提不是“1号直接远程操控 2号和 3号”，而是：

1. 你在飞书里给 1号下指令
2. 1号把指令落到共享仓库
3. 2号和 3号通过 heartbeat 或轮询发现仓库状态变化
4. 它们各自执行并回写

如果你想在**同一个飞书群**里看到执行和审查进度：

- 最稳的是三台都接入飞书
- 或者至少由 1号把 2号、3号的进度汇总后转发到群里

如果 2号或 3号使用微信，而不是飞书，那么“单飞书群聊统一汇报”就不是天然成立的。

## 你最需要写的文件

- `templates/requirement.md`：你写需求时用
- `templates/architect-brief.md`：1号用
- `templates/task-card.md`：1号发给 2号
- `templates/execution-checklist.md`：1号定义 2号当前小步执行顺序
- `templates/test-plan.md`：1号定义这一步怎么验收
- `templates/execution-report.md`：2号回写
- `templates/status-report.md`：2号告诉 1号“做完了什么、卡在哪里、下一步建议是什么”
- `templates/review-report.md`：3号审查

## 记忆建议

每个 agent 建议明确保留三层：

1. `short-term/`：当天流水账、当前任务、当前阻塞
2. `mid-term/`：当前里程碑总结、滚动总结
3. `long-term/`：长期有效的浓缩记忆

这样做的目的是：避免上下文越来越长，导致 agent 变慢、跑偏、花费越来越高。
