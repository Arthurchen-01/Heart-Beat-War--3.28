# 全局流程规则

## 核心原则
- 仓库是唯一真相源
- 任何关键协作都必须落成文件
- 不允许通过口头上下文替代文件状态

## 流程顺序
1. 用户写入 `00_input/`
2. 1号写 `10_architecture/` 和 `20_tasks/`
3. 2号写 `30_execution/`
4. 3号写 `40_review/`
5. 1号根据 review 决定下一轮

## 状态流转
`NEW -> ARCHITECTED -> EXECUTING -> REVIEWING -> ITERATING -> DONE`
必要时可进入 `BLOCKED`

## 写入边界
- 1号：架构与任务
- 2号：执行产物与执行报告
- 3号：审核报告与复盘
- 用户：原始需求与资源
