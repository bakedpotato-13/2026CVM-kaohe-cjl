# 2026 CVM 竞品微架构性能测评

> 2026 CVM 校企合作 Mini 项目考核 — 题目 1（必做）+ 题目 2（选做加分）

**姓名**：陈俊禄
**提交日期**：2026年6月21日

---

## 完成情况

| 题目 | 状态 | 说明 |
|------|------|------|
| **1a**：perf stat 五场景采集 | ✅ | 含环境记录、横向对比表格、差异分析 |
| **1b**：火焰图生成与热点分析 | ✅ | 含 4 张火焰图 SVG + hotspot 对比分析（已从源码编译 stress-ng，函数名可正确显示）|
| **1c**：Cache Line 微基准测试 | ✅ | 含 C 源码、10 组步长数据、性能曲线图 |
| **题目 2**：持续 CPU Profiling 工具 | ✅ **选做加分** | Docker 容器化，Web 界面可查火焰图 |

---

## 环境要求

### 题目 1（perf 工具链）

| 工具 | 安装命令 |
|------|---------|
| perf | `sudo apt install linux-tools-common linux-tools-generic` |
| stress-ng | `sudo apt install stress-ng` |
| gcc | `sudo apt install gcc` |
| FlameGraph | `git clone https://github.com/brendangregg/FlameGraph.git` |

### 题目 2（Docker）

| 工具 | 说明 |
|------|------|
| Docker | 需安装 Docker Engine（[官方文档](https://docs.docker.com/engine/install/)） |
| 特权模式 | 运行容器需 `--privileged`（perf 需要访问内核 PMU） |

---

## 快速复现 — 题目 1

### 1a：perf stat 五场景采集

```bash
cd task1/1-perf-stat
sudo bash collect_all.sh
```

自动记录环境信息，跑 5 类负载（整数/浮点/连续访存/随机访存/分支），产出见 `results/`。

### 1b：火焰图生成

```bash
cd task1/2-flamegraph
bash generate_flame.sh
```

采集 2 种负载（matrixprod + queens），生成 SVG 火焰图到 `flamegraphs/`。

> **注意**：热点的函数名显示依赖 stress-ng 编译参数。
> 本仓库已附带从源码编译的 stress-ng（带 `-fno-omit-frame-pointer`），
> 如需自行编译：`git clone https://github.com/ColinIanKing/stress-ng.git && cd stress-ng && make -j$(nproc) CFLAGS="-g -fno-omit-frame-pointer -O2" && sudo cp stress-ng /usr/bin/stress-ng`

### 1c：Cache Line 测试

```bash
cd task1/3-cache-line-test
bash run_all.sh
```

编译 C 程序 → 跑 10 种步长 → 生成 stride=1 和 stride=64 的火焰图对比。

---

## 快速复现 — 题目 2（Docker 持续 Profiling）

### 方式一：从镜像加载（推荐）

```bash
docker load -i task2/profiler.tar
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler
```

浏览器打开 `http://localhost:8080`

### 方式二：从源码构建

```bash
cd task2
docker build -t cpu-profiler .
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler
```

### 功能验证

1. 浏览器访问 `http://localhost:8080`
2. 点击 **"开始压力测试"**，等待 30 秒
3. 点击蓝色时间块，查看火焰图中 stress-ng 热点

---

## 目录结构

```
├── README.md                          ← 本文件
├── resume/                            ← 个人简历
├── .gitignore
│
├── task1/1-perf-stat/                 ← 题目1a
│   ├── README.md
│   ├── collect_all.sh
│   └── results/
│
├── task1/2-flamegraph/                ← 题目1b
│   ├── README.md
│   ├── generate_flame.sh
│   └── flamegraphs/                   ← 4张SVG火焰图
│
├── task1/3-cache-line-test/           ← 题目1c
│   ├── README.md
│   ├── src/cache_line_test.c
│   ├── run_all.sh
│   ├── results/
│   ├── flamegraphs/
│   └── ai-chat-log/           ← AI辅助编程对话记录
│
├── task2/                             ← 题目2（选做）
│   ├── README.md
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── profiler.tar                   ← 可直接加载的镜像（由于文件大小 镜像在releases）
│   ├── src/
│   │   ├── collector.sh
│   │   ├── query.sh
│   │   └── server.py
│   ├── test/
│   └── ai-chat-log/           ← AI辅助编程对话记录
│
├── report_项目4_CVM微架构分析.docx     ← 完整报告（含图）
└── report_images/
```

---

## 注意事项

- **VMware 虚拟化限制**：本文档在 VMware 虚拟机内完成，PMU 硬件性能计数器未透传。
  因此 `perf stat` 的 instruction、cache-misses 等硬件事件不可用。
- **perf 版本**：Docker 容器会在启动时自动安装匹配宿主机内核的 perf 版本。
- **网络**：构建 Docker 镜像时需要访问 GitHub（用于下载 FlameGraph 和 stress-ng 源码）。

---

## 参考

- [FlameGraph](https://github.com/brendangregg/FlameGraph) — Brendan Gregg 的火焰图工具
- [stress-ng](https://github.com/ColinIanKing/stress-ng) — 系统压力测试工具
- [perf Wiki](https://perf.wiki.kernel.org/) — Linux 性能分析工具
