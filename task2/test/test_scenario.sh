#!/bin/bash
# ============================================================
# CPU Profiler — 测试验证脚本
# 
# 用法：
#   先启动 profiler 容器
#   然后在宿主机或另一个终端运行本脚本
# ============================================================

echo "========================================"
echo "  🧪 CPU Profiler 测试验证"
echo "========================================"
echo ""

# 记录开始时间
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo "⏰ 测试开始时间: $START_TIME"
echo ""

# Step 1: 检查容器是否在运行
echo "Step 1: 检查 profiler 容器状态..."
if docker ps | grep -q cpu-profiler; then
    echo "✅ 容器 cpu-profiler 运行中"
else
    echo "❌ 容器未运行！请先执行："
    echo "   docker run --privileged -d -p 8080:8080 --name cpu-profiler cpu-profiler"
    exit 1
fi
echo ""

# Step 2: 模拟 CPU 飙升
echo "Step 2: 模拟 CPU 飙升（stress-ng matrixprod, 60秒）..."
echo "   开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
stress-ng --cpu 2 --cpu-method matrixprod -t 60s &
STRESS_PID=$!
echo "   stress-ng PID: $STRESS_PID"
echo "   等待 60 秒完成..."
wait $STRESS_PID
echo "✅ 压力测试完成: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Step 3: 等待采集器处理
echo "Step 3: 等待采集器完成数据轮转（10秒）..."
sleep 10
echo ""

# Step 4: 在容器内查询该时间段
echo "Step 4: 查询压力测试时间段的火焰图..."
docker exec cpu-profiler bash /opt/query.sh /data "$START_TIME" "$END_TIME" /output /opt/FlameGraph
echo ""

# Step 5: 检查结果
echo "Step 5: 检查生成的火焰图..."
docker exec cpu-profiler ls -la /output/
echo ""

echo "========================================"
echo "  ✅ 测试完成！"
echo "========================================"
echo ""
echo "🌐 在浏览器中访问 http://localhost:8080"
echo "   查看火焰图"
echo ""
echo "📂 也可在容器内查看输出文件："
echo "   docker exec cpu-profiler ls -la /output/"
echo ""
echo "📊 查看 top 函数："
echo "   docker exec cpu-profiler cat /output/top_functions_*.txt | head -20"
