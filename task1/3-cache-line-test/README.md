# 题目 1c：AI 辅助编写 Cache Line 微基准测试

## 环境准备

```bash
sudo apt install -y gcc stress-ng
```

## 一键运行

```bash
bash run_all.sh
```

自动完成：
1. 编译 `src/cache_line_test.c`
2. 运行 10 种步长测试 → `results/cache_line_results.txt`
3. 生成 stride=1 和 stride=64 的火焰图对比

## 手动编译运行

```bash
cd src
gcc -O2 cache_line_test.c -o cache_line_test
./cache_line_test
```

## 产出文件

| 文件 | 说明 |
|------|------|
| `src/cache_line_test.c` | 微基准测试 C 源码 |
| `results/cache_line_results.txt` | 10 个步长的性能数据 |
| `flamegraphs/stride1_flame.svg` | stride=1 火焰图 |
| `flamegraphs/stride64_flame.svg` | stride=64 火焰图 |

## 测试原理

以 1/2/4/8/16/32/64/128/256/512 字节步长遍历 32MB 数组，
测量总耗时和单次访问延迟。预期 stride=64 处出现拐点，
验证 x86 Cache Line = 64 字节。

## AI 辅助说明

本代码由 AI 辅助编写。AI 协助了代码生成、性能优化、
问题排查和结果解读。详细对话记录见 `ai-chat-log/` 目录。
