# Heartbeat Checklist (Agent 2 / 二哥)

## 每次心跳检查

1. **git pull** 拉取最新代码
2. **扫描 20_tasks/** 是否有新任务卡
3. **有新任务？** → 执行 → 写 30_execution/ + HANDOFF.md → git push
4. **30_execution/ 已有结果？** → 不重复执行，等 Agent 3 审查
5. **更新日志** → memory/daily/$(date +%Y-%m-%d).md
6. **没有就 HEARTBEAT_OK**