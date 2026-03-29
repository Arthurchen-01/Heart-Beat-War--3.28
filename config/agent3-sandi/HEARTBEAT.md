# Heartbeat Checklist (Agent 3 / 三弟)

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