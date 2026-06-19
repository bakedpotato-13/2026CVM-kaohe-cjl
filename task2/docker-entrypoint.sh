#!/bin/bash
# ============================================================
# Docker 入口脚本
# 在启动时安装匹配内核的 perf，然后启动采集器 + Web
# ============================================================

echo "========================================"
echo "  🔥 CPU Profiler 启动"
echo "========================================"
echo ""

# 降低 perf 权限限制
echo "🔧 设置 perf_event_paranoid = 1..."
echo 1 > /proc/sys/kernel/perf_event_paranoid 2>/dev/null || true

# 安装匹配当前内核的 perf
KERNEL_VER=$(uname -r)
echo "🔧 安装 linux-tools-${KERNEL_VER}..."
apt-get update -qq
apt-get install -y -qq "linux-tools-${KERNEL_VER}" 2>/dev/null

# 测试 perf 是否可用，不可用则装通用包
if ! perf record -a -F 99 -o /tmp/.perf_test -- sleep 1 2>/dev/null; then
    echo "⚠️  尝试安装 linux-tools-generic..."
    apt-get install -y -qq linux-tools-generic 2>/dev/null || true
fi
rm -f /tmp/.perf_test

echo ""

# 启动后台采集器
echo "📡 启动后台采集器（每60秒轮转，保留24小时）..."
bash /opt/collector.sh /data 60 24 99 &
COLLECTOR_PID=$!
echo "   采集器 PID: $COLLECTOR_PID"

sleep 5

# 启动 Web 界面
echo ""
echo "🌐 启动 Web 界面（端口 $PORT）..."
cd /opt
python3 server.py &
SERVER_PID=$!
echo "   Web PID: $SERVER_PID"
echo ""
echo "========================================"
echo "  ✅ 启动完成！"
echo "  🌐 访问 http://localhost:$PORT"
echo "  📡 采集器 PID=$COLLECTOR_PID"
echo "========================================"

wait
