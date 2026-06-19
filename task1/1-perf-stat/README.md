# 题目 1a：多场景微架构指标采集

## 环境准备

```bash
# 安装必要工具
sudo apt update
sudo apt install -y linux-tools-common linux-tools-generic stress-ng
```

## 采集命令

```bash
# 一键采集所有场景
sudo bash collect_all.sh
```

该脚本自动：
1. 记录测试环境信息 → `results/env_info.txt`
2. 依次跑 5 类负载（各 30 秒），每类用 perf stat 采集 →
   - `results/int64.txt`
   - `results/matrixprod.txt`
   - `results/read64.txt`
   - `results/rand-set.txt`
   - `results/queens.txt`

## 手动采集（单场景）

```bash
perf stat -e cycles,instructions,cache-references,cache-misses,\
L1-dcache-load-misses,L1-icache-load-misses,LLC-load-misses,\
branch-instructions,branch-misses,dTLB-load-misses,\
context-switches,cpu-migrations \
  stress-ng --cpu 1 --cpu-method int64 -t 30s
```

## 产出文件

| 文件 | 内容 |
|------|------|
| `results/env_info.txt` | CPU/内核/虚拟化/频率策略 |
| `results/int64.txt` | 整数运算 perf stat 输出 |
| `results/matrixprod.txt` | 矩阵乘法 perf stat 输出 |
| `results/read64.txt` | 连续读内存 perf stat 输出 |
| `results/rand-set.txt` | 随机访存 perf stat 输出 |
| `results/queens.txt` | N皇后 perf stat 输出 |

## 已知限制

⚠️ VMware 虚拟机环境下 PMU 硬件计数器未透传，instructions、cache-misses 等指标不可用。详情见总报告。
