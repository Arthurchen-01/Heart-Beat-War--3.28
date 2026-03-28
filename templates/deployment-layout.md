# 部署布局建议

推荐不是让三个 OpenClaw 共用一个本地 workspace，
而是让它们 **各自拥有自己的 workspace，本地都 clone 同一个 GitHub 仓库**。

## 推荐原因

因为 OpenClaw 会把 workspace 根目录中的这些文件当成 agent 的基础行为说明：
- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `USER.md`

如果三个 agent 共用一个 workspace，角色说明就容易混在一起。

## 推荐布局

- `/srv/openclaw/agent-1-workspace/`
- `/srv/openclaw/agent-2-workspace/`
- `/srv/openclaw/agent-3-workspace/`

这三个目录都 clone 同一个远端仓库，例如：
- `git@github.com:your-org/ai-factory.git`

## 每个 workspace 根目录怎么放

### 1号 workspace 根目录
- 根目录 `AGENTS.md` 采用 `templates/agent1-AGENTS.md`
- 只负责架构与任务拆解

### 2号 workspace 根目录
- 根目录 `AGENTS.md` 采用 `templates/agent2-AGENTS.md`
- 只负责执行

### 3号 workspace 根目录
- 根目录 `AGENTS.md` 采用 `templates/agent3-AGENTS.md`
- 只负责审查

## Git 同步建议

最稳的方式：
1. 每次执行前 `git pull`
2. 写入文件
3. `git add .`
4. `git commit -m "agent-x update"`
5. `git push`

## 防止撞车的简单规则

- 同一时刻，一个项目只允许一个执行者写 `30_execution/`
- 1号和 3号主要写 md 文档，尽量不碰大文件
- 对于正在执行的项目，可以放一个 `project-lock.md` 标明当前处理者和时间
