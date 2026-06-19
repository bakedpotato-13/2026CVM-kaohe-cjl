# AI 辅助编程对话记录 — Task 2

## 说明

Task 2（持续 CPU Profiling 工具）的全部代码由 **Reasonix Code（AI 编程助手）** 辅助生成。

## AI 协助内容

| 模块 | AI 参与程度 |
|------|------------|
| `collector.sh` | AI 编写完整采集循环逻辑 |
| `query.sh` | AI 编写时间解析 + 文件匹配 + FlameGraph 调用 |
| `server.py` | AI 编写 Flask 前端（HTML/CSS/JS + API 路由） |
| `Dockerfile` | AI 编写多阶段镜像构建 |
| `docker-entrypoint.sh` | AI 编写同时启动采集器 + Web |
| `test/test_scenario.sh` | AI 编写完整测试验证流程 |
| `README.md` | AI 编写项目文档 |

## 关键决策点的 AI 建议

1. **采集方式选择**：选择 sleep 轮转而非 perf --switch-output，因为更简单可靠
2. **Web 框架选择**：选择 Flask 而非 Express/React，因为无需 npm 构建，适合 Docker 容器
3. **前端设计**：选择原生 HTML+JS 而非框架，减少依赖
4. **时间解析**：使用 date 命令而非 Python，降低对系统环境的依赖

## 对话记录

（请将 AI 对话记录截图或导出文件放入此目录）
