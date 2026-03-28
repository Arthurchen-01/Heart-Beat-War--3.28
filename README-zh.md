# 三个 OpenClaw 协作模板包

这个模板包把你的想法收敛成一个更稳的结构：

- 1号：首席架构师，负责理解需求、拆目标、发任务
- 2号：执行者，负责按任务产出结果
- 3号：检验室，负责对照需求和架构指令做审查与总结

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
2. 1号读取输入，产出 `10_architecture/` 与 `20_tasks/`
3. 2号读取任务卡，产出 `30_execution/`
4. 3号对照 `00_input/`、`10_architecture/`、`30_execution/` 产出 `40_review/`
5. 1号每 30 分钟检查一次新输入、未关闭审查、阻塞项，然后更新任务卡

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

## 你最需要写的文件

- `templates/requirement.md`：你写需求时用
- `templates/architect-brief.md`：1号用
- `templates/task-card.md`：1号发给 2号
- `templates/execution-report.md`：2号回写
- `templates/review-report.md`：3号审查

## 记忆建议

每个 agent 建议至少保留三层：

1. `daily/`：当天流水账
2. `MEMORY.md`：长期有效的浓缩记忆
3. `summaries/rolling-summary.md`：多轮执行后的压缩总结

这样做的目的是：避免上下文越来越长，导致 agent 变慢、跑偏、花费越来越高。
