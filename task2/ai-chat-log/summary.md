# AI 辅助编程对话记录 — 持续 CPU Profiling 工具

## 说明

本项目使用 **Reasonix Code（AI 编程助手）** 进行辅助开发。
由于 Reasonix Code 的对话界面不支持导出完整对话记录，以下为本项目中 AI 协助内容的技术总结。

## AI 协助内容

| 模块 | AI 参与程度 |
|------|------------|
| `collector.sh` | AI 编写完整后台采集循环（60秒轮转、24小时保留、自动清理） |
| `query.sh` | AI 编写时间解析、文件匹配、FlameGraph 调用逻辑 |
| `server.py` | AI 编写 Flask Web 前端（HTML/CSS/JS + REST API） |
| `Dockerfile` | AI 编写多阶段镜像构建，集成 perf + stress-ng + FlameGraph |
| `docker-entrypoint.sh` | AI 编写同时启动采集器和 Web 服务的入口脚本 |
| `test/test_scenario.sh` | AI 编写完整测试验证流程 |
| `README.md` | AI 编写项目文档 |

## 关键决策记录

### 1. 采集方式选择
**决策**：使用 `perf record -a` 系统级采集 + `sleep 60` 轮转
**原因**：简单可靠，相比 `--switch-output` 信号机制更易于调试

### 2. Web 框架选择
**决策**：使用 Flask（Python）而非 Express/React
**原因**：零 npm 依赖，适合 Docker 容器化部署

### 3. 前端设计
**决策**：原生 HTML + JavaScript，不引入前端框架
**原因**：减少依赖，适合单容器部署

### 4. perf 版本兼容
**决策**：容器启动时自动检测并安装匹配宿主机内核的 perf 版本
**原因**：Docker 容器内核与宿主机相同，需要对应版本的 linux-tools

### 5. stress-ng 编译
**决策**：从源码编译 stress-ng（添加 `-fno-omit-frame-pointer`）
**原因**：Ubuntu apt 预编译版缺少帧指针，perf 无法解析内部函数名

## 已解决问题

| 问题 | 解决方案 |
|------|---------|
| `perf record` 数据为空 | 添加 `-a`（system-wide）参数，采集全系统数据 |
| perf 缺少共享库 | Dockerfile 添加 `libelf1 libdw1 libunwind8 libnuma1 libtraceevent1` 等依赖 |
| 时间不对 | 设置 `TZ=Asia/Shanghai` 时区环境变量 |
| 压力测试按钮文本不对 | 改为同步调用，API 等待 stress-ng 完成后返回 |

## 对话记录形式

本项目的 AI 辅助通过 **Reasonix Code** 命令行界面实时交互完成，
无法导出为外部对话文件。以上内容为技术决策的摘要记录。
