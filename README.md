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

## 快速复现

### 环境准备

```bash
# 安装必要工具（Ubuntu/Debian）
sudo apt update
sudo apt install -y linux-tools-common linux-tools-generic stress-ng gcc git
# 下载 FlameGraph 工具
git clone https://github.com/brendangregg/FlameGraph.git ~/FlameGraph
```

### 第一步：perf stat 五场景采集（题目1a）

```bash
cd task1/1-perf-stat
sudo bash collect_all.sh
```
等待约 3 分钟自动完成，数据保存到 `results/` 目录。

### 第二步：火焰图生成（题目1b）

```bash
cd task1/2-flamegraph
bash generate_flame.sh
```
等待约 30 秒，SVG 火焰图保存到 `flamegraphs/` 目录，双击 SVG 文件可在浏览器中交互查看。

### 第三步：Cache Line 测试（题目1c）

```bash
cd task1/3-cache-line-test
bash run_all.sh
```
自动编译 C 程序、运行 10 种步长测试并生成火焰图。

### 第四步：Docker Profiling 工具（题目2 选做）

```bash
# 方式一：从镜像加载（推荐，无需构建）
# 用 curl 从 Release 下载 profiler.tar（约170MB，网络慢可能需数分钟）
curl -L https://github.com/bakedpotato-13/2026CVM-kaohe-cjl/releases/download/v1/profiler.tar -o profiler.tar
cd task2
docker load -i profiler.tar
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler

# 方式二：从源码构建（无需下载）
cd task2
docker build -t cpu-profiler .
docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler
```

### 第五步：查看 Web 界面

```bash
# 查看本机 IP 地址（找 ens33 或 eth0 那行的 inet 地址）
ip addr show | grep ens33
```
示例输出：
```
inet 192.168.95.129/24 ... ens33
```
浏览器访问 `http://192.168.95.129:8080`（将 IP 替换为你查到的实际地址）

### 验证 Profiling 功能

1. 打开 Web 页面，点击 **"开始压力测试"**
2. 等待 30 秒
3. 找到对应时间段的蓝色块并点击
4. 页面显示火焰图，热点列表中 stress-ng 函数名可正常显示

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
