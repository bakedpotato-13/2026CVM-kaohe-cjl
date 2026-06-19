#!/bin/bash
# ============================================================
# 项目 4 - 题目 1a：五场景微架构指标 一键采集脚本
# 用法：bash collect_all.sh
# 产出：results/ 目录下 5 个 txt + env_info.txt
# ============================================================

set -e

OUTDIR="results"
mkdir -p "$OUTDIR"

echo "========================================"
echo "  Step 0: 记录测试环境信息"
echo "========================================"

{
    echo "========== CPU 信息 =========="
    cat /proc/cpuinfo | grep "model name" | head -1
    cat /proc/cpuinfo | grep "cpu cores" | head -1
    echo ""

    echo "========== 内核版本 =========="
    uname -a
    echo ""

    echo "========== NUMA 拓扑 =========="
    numactl --hardware 2>/dev/null || echo "numactl 未安装，跳过"
    echo ""

    echo "========== CPU 频率策略 =========="
    cpupower frequency-info 2>/dev/null || echo "cpupower 未安装，跳过"
    echo ""

    echo "========== lscpu =========="
    lscpu

} > "$OUTDIR/env_info.txt"

echo "✅ 环境信息已保存到 $OUTDIR/env_info.txt"
echo ""

# ============================================================
# 五类负载采集
# ============================================================

PERF_EVENTS="cycles,instructions,cache-references,cache-misses,\
L1-dcache-load-misses,L1-icache-load-misses,LLC-load-misses,\
branch-instructions,branch-misses,dTLB-load-misses,\
context-switches,cpu-migrations"

declare -A SCENARIOS
SCENARIOS["int64"]="stress-ng --cpu 1 --cpu-method int64 -t 30s"
SCENARIOS["matrixprod"]="stress-ng --cpu 1 --cpu-method matrixprod -t 30s"
SCENARIOS["read64"]="stress-ng --vm 1 --vm-bytes 1G --vm-method read64 --vm-keep -t 30s"
SCENARIOS["rand-set"]="stress-ng --vm 1 --vm-bytes 512M --vm-method rand-set --vm-keep -t 30s"
SCENARIOS["queens"]="stress-ng --cpu 1 --cpu-method queens -t 30s"

for name in "${!SCENARIOS[@]}"; do
    echo "========================================"
    echo "  采集场景: $name"
    echo "  命令: ${SCENARIOS[$name]}"
    echo "========================================"

    sudo perf stat -e "$PERF_EVENTS" ${SCENARIOS[$name]} 2>&1 | tee "$OUTDIR/${name}.txt"

    echo ""
    echo "✅ ${name} 采集完成，已保存到 $OUTDIR/${name}.txt"
    echo ""
done

echo "========================================"
echo "  全部采集完成！"
echo "========================================"
echo ""
echo "产出文件："
ls -la "$OUTDIR/"
echo ""
echo ""
echo "完成！所有数据已保存到 results/ 目录"
