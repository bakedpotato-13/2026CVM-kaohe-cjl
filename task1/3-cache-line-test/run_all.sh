#!/bin/bash
# ============================================================
# 题目 1c：Cache Line 微基准测试 — 一键运行
# ============================================================

set -e

SRC_DIR="src"
RESULTS_DIR="results"
FLAMEGRAPHS_DIR="flamegraphs"
mkdir -p "$RESULTS_DIR" "$FLAMEGRAPHS_DIR"

echo "========================================"
echo "  Step 1: 编译 C 程序"
echo "========================================"
gcc -O2 "$SRC_DIR/cache_line_test.c" -o "$SRC_DIR/cache_line_test"
echo "✅ 编译成功"
echo ""

echo "========================================"
echo "  Step 2: 运行 Cache Line 测试"
echo "========================================"
"$SRC_DIR/cache_line_test" | tee "$RESULTS_DIR/cache_line_results.txt"
echo "✅ 测试完成"
echo ""

echo "========================================"
echo "  Step 3: 生成火焰图对比"
echo "  (stride=1 vs stride=64)"
echo "========================================"

# 写一个专门的小程序来跑 stride=1 和 stride=64
cat > /tmp/cache_stride_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#define ARRAY_SIZE (32 * 1024 * 1024)

int main(int argc, char *argv[]) {
    int stride = 64;
    if (argc > 1) stride = atoi(argv[1]);

    volatile char *array = (volatile char *)malloc(ARRAY_SIZE);
    for (int i = 0; i < ARRAY_SIZE; i += 4096) array[i] = 0;

    volatile char sink;
    for (int iter = 0; iter < 500; iter++) {
        for (int i = 0; i < ARRAY_SIZE; i += stride) {
            sink = array[i];
        }
    }

    free((void*)array);
    return 0;
}
EOF

gcc -O2 /tmp/cache_stride_test.c -o /tmp/cache_stride_test

FLAMEGRAPH_DIR="$HOME/FlameGraph"

echo "采集 stride=1 火焰图..."
sudo perf record -F 99 -g -o /tmp/perf_stride1.data -- /tmp/cache_stride_test 1
sudo perf script -f -i /tmp/perf_stride1.data | \
    "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | \
    "$FLAMEGRAPH_DIR/flamegraph.pl" > "$FLAMEGRAPHS_DIR/stride1_flame.svg"
echo "✅ stride=1 火焰图已生成"

echo "采集 stride=64 火焰图..."
sudo perf record -F 99 -g -o /tmp/perf_stride64.data -- /tmp/cache_stride_test 64
sudo perf script -f -i /tmp/perf_stride64.data | \
    "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | \
    "$FLAMEGRAPH_DIR/flamegraph.pl" > "$FLAMEGRAPHS_DIR/stride64_flame.svg"
echo "✅ stride=64 火焰图已生成"

# 清理
rm -f /tmp/cache_stride_test.c /tmp/cache_stride_test /tmp/perf_stride1.data /tmp/perf_stride64.data

echo ""
echo "========================================"
echo "  全部完成！"
echo "========================================"
echo ""
echo "产出文件："
echo "  results/cache_line_results.txt     — 步长 vs 性能数据"
echo "  flamegraphs/stride1_flame.svg      — stride=1 火焰图"
echo "  flamegraphs/stride64_flame.svg     — stride=64 火焰图"
echo ""
echo "下一步：把这 3 个文件发给我！"
