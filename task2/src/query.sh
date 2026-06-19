#!/bin/bash
# ============================================================
# CPU Profiler — 查询 + 火焰图生成脚本
# 用法：
#   bash query.sh <数据目录> <起始时间> [结束时间]
# 示例：
#   bash query.sh /data "2026-06-15 03:00" "2026-06-15 03:05"
# ============================================================

DATA_DIR="${1:-/data}"
START_TIME="$2"
END_TIME="$3"
OUTPUT_DIR="${4:-/output}"
FLAMEGRAPH_DIR="${5:-$HOME/FlameGraph}"

# 如果没有指定时间，默认查最近一个文件
if [ -z "$START_TIME" ]; then
    LATEST=$(ls -t "$DATA_DIR"/*.perf.data 2>/dev/null | head -1)
    if [ -z "$LATEST" ]; then
        echo "❌ 没有找到采集数据"
        exit 1
    fi
    echo "📂 使用最新文件: $LATEST"
    FILES=("$LATEST")
else
    # 将起始/结束时间转为时间戳
    START_TS=$(date -d "$START_TIME" +%s 2>/dev/null)
    END_TS=$(date -d "$END_TIME" +%s 2>/dev/null)
    
    if [ -z "$START_TS" ]; then
        echo "❌ 时间格式错误，请使用 YYYY-MM-DD HH:MM 格式"
        echo "   示例：bash query.sh /data '2026-06-15 03:00' '2026-06-15 03:05'"
        exit 1
    fi
    if [ -z "$END_TS" ]; then
        # 如果没给结束时间，默认起始时间+5分钟
        END_TS=$((START_TS + 300))
    fi
    
    echo "🔍 查询时间段: $(date -d @$START_TS) → $(date -d @$END_TS)"
    
    # 找出该时间段内的所有 .perf.data 文件
    FILES=()
    while read -r f; do
        FILES+=("$f")
    done < <(for f in "$DATA_DIR"/*.perf.data; do
        # 从文件名解析时间：20260615_030201.perf.data
        BASENAME=$(basename "$f" .perf.data)
        FILE_TS=$(date -d "${BASENAME:0:4}-${BASENAME:4:2}-${BASENAME:6:2} ${BASENAME:9:2}:${BASENAME:11:2}:${BASENAME:13:2}" +%s 2>/dev/null)
        if [ -n "$FILE_TS" ] && [ "$FILE_TS" -ge "$START_TS" ] && [ "$FILE_TS" -le "$END_TS" ]; then
            echo "$f"
        fi
    done | sort)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "❌ 该时间段内没有找到采集数据"
    exit 1
fi

echo "📊 找到 ${#FILES[@]} 个数据文件"
mkdir -p "$OUTPUT_DIR"

# 检查 FlameGraph
if [ ! -f "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" ]; then
    echo "📦 正在下载 FlameGraph..."
    git clone https://github.com/brendangregg/FlameGraph.git "$FLAMEGRAPH_DIR" 2>/dev/null
fi

# 合并所有 .perf.data 文件（如果有多个）
if [ ${#FILES[@]} -eq 1 ]; then
    MERGED_DATA="${FILES[0]}"
    echo "📂 单个文件，直接处理"
else
    MERGED_DATA="/tmp/merged.perf.data"
    echo "🔄 合并 ${#FILES[@]} 个文件..."
    
    # 先用 perf script 导出，再合并（如果只有1个文件跳过）
    FIRST=true
    for f in "${FILES[@]}"; do
        if [ "$FIRST" = true ]; then
            perf script -f -i "$f" > /tmp/merged_script.txt 2>/dev/null
            FIRST=false
        else
            perf script -f -i "$f" >> /tmp/merged_script.txt 2>/dev/null
        fi
    done
fi

# 生成火焰图
TIMESTAMP_TAG=$(date +%Y%m%d_%H%M%S)
SVG_OUTPUT="$OUTPUT_DIR/flamegraph_${TIMESTAMP_TAG}.svg"
TEXT_OUTPUT="$OUTPUT_DIR/top_functions_${TIMESTAMP_TAG}.txt"

echo "🔥 生成火焰图..."

if [ ${#FILES[@]} -eq 1 ]; then
    perf script -f -i "$MERGED_DATA" 2>/dev/null | \
        "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" 2>/dev/null | \
        "$FLAMEGRAPH_DIR/flamegraph.pl" > "$SVG_OUTPUT" 2>/dev/null
else
    cat /tmp/merged_script.txt | \
        "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" 2>/dev/null | \
        "$FLAMEGRAPH_DIR/flamegraph.pl" > "$SVG_OUTPUT" 2>/dev/null
fi

# 同时输出 top 函数（折叠文本好分析）
if [ ${#FILES[@]} -eq 1 ]; then
    perf script -f -i "$MERGED_DATA" 2>/dev/null | \
        "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" 2>/dev/null | \
        awk 'BEGIN{c=0} { if (c++==0) { total=$NF } else { total+=$NF; lines[NR-1]=$0; cnt[NR-1]=$NF } } END { for(i=1;i<=NR-1;i++) { pct=sprintf("%.1f", cnt[i]/total*100); sub(/ [0-9]+$/, "", lines[i]); if (length(lines[i])>45) lines[i]=substr(lines[i],1,45)".."; print lines[i] " " pct } }' | \
        sort -t' ' -k2 -rn | head -30 > "$TEXT_OUTPUT"  
else
    cat /tmp/merged_script.txt | \
        "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" 2>/dev/null | \
        awk 'BEGIN{c=0} { if (c++==0) { total=$NF } else { total+=$NF; lines[NR-1]=$0; cnt[NR-1]=$NF } } END { for(i=1;i<=NR-1;i++) { pct=sprintf("%.1f", cnt[i]/total*100); sub(/ [0-9]+$/, "", lines[i]); if (length(lines[i])>45) lines[i]=substr(lines[i],1,45)".."; print lines[i] " " pct } }' | \
        sort -k2 -rn | head -30 > "$TEXT_OUTPUT"
fi

echo ""
echo "========================================"
echo "  ✅ 查询完成！"
echo "========================================"
echo "  🔥 火焰图: $SVG_OUTPUT"
echo "  📊 Top30:  $TEXT_OUTPUT"
echo ""

# 清理临时文件
rm -f /tmp/merged_script.txt /tmp/merged.perf.data
