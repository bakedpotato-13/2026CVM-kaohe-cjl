#!/bin/bash
# ============================================================
# CPU Profiler — 后台持续采集脚本
# 循环 perf record，每60秒轮转一次，保留最近24小时
# ============================================================

DATA_DIR="${1:-/data}"
INTERVAL="${2:-60}"       # 每60秒轮转一次
RETENTION_HOURS="${3:-24}" # 保留24小时
SAMPLE_FREQ="${4:-99}"    # 采样频率 99Hz

mkdir -p "$DATA_DIR"

echo "🚀 CPU Profiler 已启动"
echo "   数据目录: $DATA_DIR"
echo "   轮转间隔: ${INTERVAL}s"
echo "   保留时长: ${RETENTION_HOURS}h"
echo "   采样频率: ${SAMPLE_FREQ}Hz"
echo ""

cleanup_old() {
    # 删除超过保留时长的旧文件
    find "$DATA_DIR" -name "*.perf.data" -mmin +$((RETENTION_HOURS * 60)) -delete 2>/dev/null
    find "$DATA_DIR" -name "*.svg" -mmin +$((RETENTION_HOURS * 60)) -delete 2>/dev/null
}

record_loop() {
    while true; do
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        OUTPUT_FILE="$DATA_DIR/${TIMESTAMP}.perf.data"
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始采集: $OUTPUT_FILE"
        
        # 采集 SLEEP_TIME 秒
        perf record -a -F "$SAMPLE_FREQ" -g -o "$OUTPUT_FILE" -- sleep "$INTERVAL" 2>/dev/null
        
        # 检查文件是否有效（大于1KB）
        if [ -f "$OUTPUT_FILE" ] && [ "$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null)" -gt 1024 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 采集完成: $OUTPUT_FILE"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  采样数据过少（可能无进程在跑）"
        fi
        
        # 清理旧文件
        cleanup_old
    done
}

# 捕获 SIGTERM/SIGINT 优雅退出
trap 'echo "🛑 采集停止"; exit 0' SIGTERM SIGINT

record_loop
