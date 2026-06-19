#!/bin/bash
# ============================================================
# 题目 1b：一键生成火焰图
# 用法：bash generate_flame.sh
# 产出：flamegraphs/ 下 2 个 SVG
# ============================================================

set -e

OUTDIR="flamegraphs"
mkdir -p "$OUTDIR"

FLAMEGRAPH_DIR="$HOME/FlameGraph"

# 检查 FlameGraph 是否存在
if [ ! -f "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" ]; then
    echo "⚠️  未找到 FlameGraph，正在克隆..."
    git clone https://github.com/brendangregg/FlameGraph.git "$FLAMEGRAPH_DIR"
fi

echo "========================================"
echo "  采集 ①：矩阵乘法（matrixprod）"
echo "  时间：15 秒"
echo "========================================"

sudo perf record -F 99 -g -o perf_matrixprod.data -- stress-ng --cpu 1 --cpu-method matrixprod -t 15s

echo "生成火焰图..."
sudo perf script -f -i perf_matrixprod.data | \
    "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | \
    "$FLAMEGRAPH_DIR/flamegraph.pl" > "$OUTDIR/matrixprod_flame.svg"

echo "✅ matrixprod 火焰图已生成"
echo ""

echo "========================================"
echo "  采集 ②：N皇后（queens）"
echo "  时间：15 秒"
echo "========================================"

sudo perf record -F 99 -g -o perf_queens.data -- stress-ng --cpu 1 --cpu-method queens -t 15s

echo "生成火焰图..."
sudo perf script -f -i perf_queens.data | \
    "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | \
    "$FLAMEGRAPH_DIR/flamegraph.pl" > "$OUTDIR/queens_flame.svg"

echo "✅ queens 火焰图已生成"
echo ""

# 清理临时文件
rm -f perf_matrixprod.data perf_queens.data

echo "========================================"
echo "  全部完成！"
echo "========================================"
echo ""
echo "产出文件："
ls -la "$OUTDIR/"
echo ""
echo "下一步：把 flamegraphs/ 文件夹里的 2 个 SVG 发给我！"
