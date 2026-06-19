# 🔥 CPU Profiler — 持续 CPU Profiling 工具

> 题目 2（选做加分）：构建 Linux 持续 CPU Profiling 工具

## 项目简介

一个 **7×24 持续 CPU Profiling 的 Docker 容器化工具**。让 perf 像"黑匣子"一样常驻后台运行，出问题时只需指定时间点，就能调出当时的 CPU 采样数据，生成火焰图定位根因。

### 核心功能

| 功能 | 说明 |
|------|------|
| ✅ **后台持续采集** | 每 60 秒自动轮转 perf record 采样文件 |
| ✅ **历史数据保留** | 保留最近 24 小时，自动清理过期数据 |
| ✅ **按时间回查** | Web 界面点击时间段 / 自定义查询 |
| ✅ **一键生成火焰图** | 选中时间段自动调用 FlameGraph 生成 SVG |
| ✅ **Web 前端界面** | 时间线视图 + 火焰图展示 + 热点函数列表 |

## 架构设计

```
┌─────────────────────────────────────────────┐
│              Docker 容器 (特权模式)            │
│                                             │
│  collector.sh ──→ /data/*.perf.data          │
│  (循环采集)         (每60秒轮转)              │
│                                             │
│  server.py (Flask) ──→ Web UI (端口 8080)    │
│    │                                        │
│    └── query.sh ──→ FlameGraph ──→ SVG       │
│                                             │
│  /opt/FlameGraph/ (FlameGraph 工具链)         │
└─────────────────────────────────────────────┘
```

## 快速启动

### 方式一：从 tar 包加载

```bash
# 解压
docker load -i profiler.tar

# 运行（特权模式！）
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler

# 访问 Web 界面
# 浏览器打开 http://localhost:8080
```

### 方式二：直接构建

```bash
# 构建
docker build -t cpu-profiler .

# 运行
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler
```

> **注意**：必须使用 `--privileged` 模式，因为 perf 需要访问内核的 PMU。

## 使用示例

### 1. 查看 Web 界面

浏览器访问 `http://localhost:8080`

- 顶部显示系统概览（文件数、数据量、时间范围）
- 时间线视图：蓝色块表示有数据，点击即可生成该小时的火焰图
- 支持自定义时间段查询

### 2. 手动查询（命令行）

```bash
# 进入容器
docker exec -it cpu-profiler bash

# 查询特定时间段
bash /opt/query.sh /data "2026-06-15 03:00" "2026-06-15 03:05" /output /opt/FlameGraph

# 查看生成的火焰图
ls -la /output/
```

### 3. 模拟故障验证

```bash
# 在宿主机或另一个终端模拟 CPU 飙升
stress-ng --cpu 2 --cpu-method matrixprod -t 60s

# 然后在 Web 界面查看该时间段的火焰图
# 应该能看到 stress-ng 的热点
```

## 文件说明

| 文件 | 作用 |
|------|------|
| `Dockerfile` | 镜像构建文件 |
| `docker-entrypoint.sh` | 容器入口（启动采集器 + Web） |
| `src/collector.sh` | 后台采集循环 |
| `src/query.sh` | 查询 + 火焰图生成 |
| `src/server.py` | Flask Web 前端 |
| `src/requirements.txt` | Python 依赖 |
| `test/test_scenario.sh` | 测试验证脚本 |

## 设计权衡

| 决策 | 选择 | 原因 |
|------|------|------|
| 采集轮转方式 | 60s 间隔 sleep 轮转 | 简单可靠，无需信号机制 |
| 数据存储 | 文件系统（/data） | 容器化场景，挂载 volume 即可持久化 |
| 前端框架 | 原生 HTML + Flask | 零依赖，免去 npm/build 步骤 |
| 采样频率 | 99 Hz | perf 推荐值，足够精细 |
| 数据保留 | 24 小时 | 平衡磁盘占用和回查需求 |

## 注意事项

1. **特权模式**：perf 需要 `--privileged` 才能采集宿主机性能数据
2. **VMware 限制**：在虚拟机中 PMU 计数器可能不可用，但 timer-based 采样（`-F 99`）仍正常工作
3. **磁盘占用**：约 5-10MB/分钟，24 小时约 7-15GB，可通过 volume 挂载持久化
4. **perf_event_paranoid**：容器启动时会自动设为 1，无需手动配置
5. **stress-ng 函数名**：stress-ng 已从源码编译（带 -fno-omit-frame-pointer），火焰图中可正常显示函数名

## 测试验证

```bash
# 运行测试脚本（在宿主机上）
bash test/test_scenario.sh
```

测试步骤：
1. 检查容器运行状态
2. 启动 stress-ng 模拟 60 秒 CPU 飙升
3. 查询该时间段的火焰图
4. 验证火焰图中能看到 stress-ng 热点
