# Agent 3（三弟）配置文件

## 文件说明

- `AGENTS.md` - Agent 3 审查者配置
- `HEARTBEAT.md` - Agent 3 心跳检查清单
- `openclaw.json` - OpenClaw 配置模板（需填入实际的 appId 和 appSecret）

## 使用方法

1. 复制 `openclaw.json` 到服务器 `~/.openclaw/openclaw.json`
2. 填入实际的飞书 App ID 和 App Secret
3. 复制 `AGENTS.md` 和 `HEARTBEAT.md` 到 workspace 目录

## Agent 3 职责

- 审查 Agent 2 的执行结果
- 检查是否偏离需求
- 写审查报告到 `project/40_review/`
- 审查通过 → 删除 task 文件
- 审查不通过 → 写报告通知 Agent 1

## 心跳频率

- 5 分钟（等待 Agent 2 完成后再审查）