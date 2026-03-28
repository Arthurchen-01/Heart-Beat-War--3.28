

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


原问题：【我希望我三个open claw都能够互相配合着工作，那么这个结构应该是这样的，首先我有很多需求，那么一次AI它只能在一个领域去整理我的需求，并且他作为首席架构师把我的需求进行流程化以及目标化，布置成任务给下一个AI

那么第二个AI，它作为第二个open cloud, 它一旦发现我们GitHub上面的repository里面有新的需求文件的更新，那么他就会去相对应的去把需求文件给里面要求的内容给处理

然后，我们第三个OpenCL，它就是作为检验室，他会阅读我们整体的需求。其次，他会阅读架构师的第一轮的指令，再根据指令检查第二个open. Cloud的任务完成情况。他会根据总体的，它会生成一个报告，分别从整体框架上以及拆解任务上，以及本次任务完成的情况上给出建议和总结

那么他的这个总结和建议将会生成另一个MD文件，放到repository里面的另一个就是另一个文件夹里面。然后，我们切分割任务的第一个openclaw，他就每30分钟heartbeat设置成30分钟检查一次。每30分钟他就要检查一下这个是否有新的需求文件，并且根据我们总体的框架以及第三个open claw给出的报告，去更新以及给出下一步的指令给到第二个open claw

那么我需要做的事情就是写这个MD文件，写需求的MD文件，把我的需求以及我想要的图片的格式的样式的图片或者HD、ML等一切有的资源都放在这个需求文件夹里面。那么我希望的结果就是当天晚上我会写多个这个需求文件，然后晚上的时候他们就自主的这样进行运行

为了方便我查看每一个需求对应的一个大项目，他们所对应的文件夹只能放在自己的那一个里面。里面的那一个可以有很多的分支，再就是所有的记忆文件夹必须要放在一个统一的文件夹里面。那么这个记忆文件夹需要分成一openclaw一号、二号、三号。他们分别的这个记忆都需要有，但最好是多次对话，多次执行之后进行总结简化的一个报告一样的记忆】

建议：【可以，而且我建议你把它定成“1 个仓库状态机 + 3 个角色”，不要定成“3 个 AI 随便互相聊天”。这样最稳，也最容易排错。OpenClaw 本身就有 workspace、文件型记忆、heartbeat、cron、webhook 这些能力，所以你这个方案是能落地的。要特别注意一件事：OpenClaw 会把 workspace 根目录里的 AGENTS.md、SOUL.md、TOOLS.md、USER.md 之类文件当成 agent 的基础行为说明，所以三个角色最好不要共用同一个 workspace；更稳的做法是 3 个独立 workspace，各自 clone 同一个 GitHub 仓库。 

你原来的想法里，我只建议改一刀：新需求不要先让 2 号直接开工，而是先经过 1 号。
因为 1 号是“首席架构师”，它的职责不是干活，而是把需求翻译成“目标、流程、任务卡、验收标准”。2 号只负责按任务卡执行。3 号只负责检查“原需求、架构指令、执行结果”三者是不是对得上。这样晚上自动跑的时候，不容易越做越乱。🙂

Heartbeat 你可以把它理解成“定时巡逻”。OpenClaw 官方把它定位成周期性检查，默认就是 30 分钟这一类节奏，适合让 1 号每半小时看看有没有新需求、review、阻塞项。Cron 更像“定时闹钟”，适合每天固定时间出日报、夜间汇总这种精确时间任务。外部触发则直接用 webhook：OpenClaw 的 POST /hooks/agent 可以跑一个隔离的 agent 回合，POST /hooks/wake 可以把事件塞回主会话；GitHub 自己也支持 repository webhook，把仓库事件实时 POST 到你指定的 URL，而不是靠轮询。 

我建议你把整套流程定成这样：
	1.	你只负责往项目的 00_input/ 里放需求 MD、图片、品牌素材、参考图、文案、数据。
	2.	1 号读取 00_input/，输出 10_architecture/ 和 20_tasks/。
	3.	2 号只读取最新任务卡，把结果写进 30_execution/。
	4.	3 号读取 00_input/、10_architecture/、20_tasks/、30_execution/，输出 40_review/。
	5.	1 号 heartbeat 每 30 分钟醒一次，看看有没有新需求、有没有新的 review、要不要更新任务卡。
	6.	每天固定一个时间，再用 cron 跑一次“总汇总”或“压缩记忆”。

最关键的运行原则就三条：
仓库是唯一真相源；每个角色只写自己该写的目录；任何结论都落成文件，不靠聊天记忆。

你的目录我建议直接这样定，简单又清楚：
repo/
  projects/
    PRJ-2026-001-demo/
      00_input/
        requirement.md
        assets/
      10_architecture/
        project-brief.md
        execution-plan.md
        current-instruction.md
      20_tasks/
        TASK-001/
          task-card.md
        TASK-002/
      30_execution/
      40_review/
      50_release/

  memory/
    openclaw-1/
      daily/
      MEMORY.md
      summaries/
    openclaw-2/
      daily/
      MEMORY.md
      summaries/
    openclaw-3/
      daily/
      MEMORY.md
      summaries/

  system/
    workflow-rules.md
    naming-rules.md

这里面的意思用人话说就是：
00_input 是你写的原始要求；10_architecture 是 1 号的“作战图”；20_tasks 是 1 号发给 2 号的任务单；30_execution 是 2 号的干活结果；40_review 是 3 号的质检报告；memory 是三个 agent 各自的记忆柜子。

记忆这块，你的想法也是对的。OpenClaw 官方本来就建议把记忆放成“当天日志 + 长期记忆”两层，也就是类似 memory/YYYY-MM-DD.md 和 MEMORY.md 这样的文件式记忆。你现在想统一成 memory/openclaw-1/、memory/openclaw-2/、memory/openclaw-3/ 也完全可以，只是要在各自的 AGENTS.md 里明确写死它该读哪个路径，不要指望默认模板自己猜出来。我的建议是：每次运行先写 daily/，每晚最后一轮再把多次对话压缩进 MEMORY.md 和 summaries/rolling-summary.md，这样上下文不会越滚越胖。 

还有一个很重要的工程细节：三个角色不要共用同一个本地 workspace 目录。
更稳的是：
	•	agent-1-workspace/ clone 同一个仓库
	•	agent-2-workspace/ clone 同一个仓库
	•	agent-3-workspace/ clone 同一个仓库

这样每个 OpenClaw 根目录都能放自己的 AGENTS.md，角色不会串味；但它们推送到的是同一个远端仓库，所以项目文件还是统一的。要不然你只要把 1 号的 AGENTS.md 换成架构师风格，2 号和 3 号也会一起吃到这套说明，角色边界就会糊掉。OpenClaw 官方也明确说了，workspace 是 agent 的“家”，而且这些根目录文件会在会话启动时直接进上下文。 


我已经把你这套结构整理成一份可以直接拿去改的模板包了，里面有：
	•	需求模板
	•	架构师总指令模板
	•	任务卡模板
	•	执行回写模板
	•	质检报告模板
	•	3 个角色各自的 AGENTS.md 模板
	•	推荐目录结构
	•	独立 workspace 的部署说明

你可以直接下载：

模板包 ZIP
中文说明 README

你现在最值得先做的一步，就是拿这个模板先建 1 个真实项目文件夹，不要一上来同时跑十个项目；先让 3 个角色在一个项目上顺起来，通了以后再扩。
