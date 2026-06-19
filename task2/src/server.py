#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CPU Profiler — Web 前端界面
提供：
  - 时间线视图：展示已有采集数据
  - 一键生成火焰图
  - 系统概览
"""

from flask import Flask, render_template_string, send_file, jsonify, request
import subprocess
import os
import glob
from datetime import datetime, timedelta

app = Flask(__name__)

DATA_DIR = os.environ.get('DATA_DIR', '/data')
OUTPUT_DIR = os.environ.get('OUTPUT_DIR', '/output')
FLAMEGRAPH_DIR = os.environ.get('FLAMEGRAPH_DIR', '/opt/FlameGraph')

INDEX_HTML = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>CPU Profiler — 持续性能采集控制台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, 'Microsoft YaHei', sans-serif; 
               background: #f5f5f5; color: #333; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #2c3e50; margin-bottom: 10px; }
        .subtitle { color: #7f8c8d; margin-bottom: 20px; }
        
        .card { background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                padding: 20px; margin-bottom: 20px; }
        .card h2 { font-size: 18px; margin-bottom: 15px; color: #2c3e50; }
        
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .stat-box { background: #f8f9fa; border-radius: 6px; padding: 15px; text-align: center; }
        .stat-box .num { font-size: 28px; font-weight: bold; color: #3498db; }
        .stat-box .label { font-size: 13px; color: #7f8c8d; margin-top: 5px; }
        
        .timeline { display: flex; flex-wrap: wrap; gap: 6px; margin: 10px 0; }
        .time-block { width: 60px; height: 30px; background: #ecf0f1; border-radius: 4px;
                      display: flex; align-items: center; justify-content: center;
                      font-size: 10px; color: #95a5a6; cursor: pointer;
                      transition: all 0.2s; position: relative; }
        .time-block.has-data { background: #3498db; color: white; }
        .time-block.has-data:hover { background: #2980b9; transform: scale(1.1); z-index: 10; }
        .time-block.active { background: #e74c3c !important; }
        
        .flamegraph-container { width: 100%; overflow-x: auto; }
        .flamegraph-container svg { width: 100%; min-width: 600px; }
        .flamegraph-container img { width: 100%; }
        
        .btn { display: inline-block; padding: 8px 20px; border-radius: 6px; 
               border: none; cursor: pointer; font-size: 14px; transition: all 0.2s; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-danger:hover { background: #c0392b; }
        .btn-sm { padding: 5px 12px; font-size: 12px; }
        
        .time-input { padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; }
        
        .loading { display: none; text-align: center; padding: 40px; color: #7f8c8d; }
        .loading.active { display: block; }
        
        .top-list { list-style: none; }
        .top-list li { padding: 6px 0; border-bottom: 1px solid #eee; 
                       display: flex; justify-content: space-between; }
        .top-list .func-name { font-family: monospace; color: #2c3e50; }
        .top-list .func-pct { color: #e74c3c; font-weight: bold; }
        
        .footer { text-align: center; color: #bdc3c7; font-size: 12px; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔥 CPU Profiler</h1>
        <p class="subtitle">7×24 持续 CPU 性能采集 · 按时间回查火焰图</p>
        
        <div class="card">
            <h2>📊 系统概览</h2>
            <div class="status-grid">
                <div class="stat-box">
                    <div class="num" id="total-files">{{ total_files }}</div>
                    <div class="label">采集文件数</div>
                </div>
                <div class="stat-box">
                    <div class="num" id="total-size">{{ total_size }}</div>
                    <div class="label">数据总量</div>
                </div>
                <div class="stat-box">
                    <div class="num" id="oldest-time">{{ oldest_time }}</div>
                    <div class="label">最早数据</div>
                </div>
                <div class="stat-box">
                    <div class="num" id="latest-time">{{ latest_time }}</div>
                    <div class="label">最新数据</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>⏱ 时间线（最近24小时）</h2>
            <div class="timeline" id="timeline"></div>
            <p style="color:#95a5a6; font-size:12px; margin-top:8px;">
                ● 蓝色块 = 有数据 ｜ 点击生成该时间段的火焰图
            </p>
        </div>
        
        <div class="card">
            <h2>🔍 自定义查询</h2>
            <p>
                起始：<input type="datetime-local" class="time-input" id="start-time">
                结束：<input type="datetime-local" class="time-input" id="end-time" style="margin-left:10px">
                <button class="btn btn-primary" onclick="customQuery()" style="margin-left:10px">查询</button>
            </p>
        </div>
        
        <div class="loading" id="loading">
            <p>⏳ 生成火焰图中，请稍候...</p>
        </div>
        
        <div class="card" id="result-card" style="display:none;">
            <h2>🔥 火焰图</h2>
            <p id="result-info" style="color:#7f8c8d; margin-bottom:10px;"></p>
            <div class="flamegraph-container" id="flamegraph-container"></div>
            <h3 style="margin-top:15px;">📊 Top 热点函数</h3>
            <ul class="top-list" id="top-list"></ul>
        </div>
        
        <div class="card">
            <h2>🧪 快速测试</h2>
            <p>模拟 CPU 飙升场景（30秒 stress-ng）</p>
            <button class="btn btn-danger" onclick="runStressTest()">🚀 开始压力测试</button>
            <span id="test-status" style="margin-left:10px; color:#7f8c8d;"></span>
        </div>
        
        <div class="footer">
            CPU Profiler · 基于 perf + FlameGraph · Docker 容器化
        </div>
    </div>
    
    <script>
        // 自动刷新：每30秒更新概览和时间线
        setInterval(function() {
            loadTimeline();
        }, 30000);
    
        // 加载时间线
        function loadTimeline() {
            fetch('/api/files')
                .then(r => r.json())
                .then(data => {
                    const timeline = document.getElementById('timeline');
                    timeline.innerHTML = '';
                    
                    const now = new Date();
                    for (let i = 23; i >= 0; i--) {
                        const hour = new Date(now - i * 3600000);
                        const hourKey = hour.getFullYear() + 
                            String(hour.getMonth()+1).padStart(2,'0') + 
                            String(hour.getDate()).padStart(2,'0') + '_' +
                            String(hour.getHours()).padStart(2,'0');
                        
                        const block = document.createElement('div');
                        block.className = 'time-block';
                        block.textContent = String(hour.getHours()).padStart(2,'0') + ':00';
                        block.dataset.hour = hourKey;
                        
                        const hasData = data.files.some(f => f.startsWith(hourKey));
                        if (hasData) block.classList.add('has-data');
                        
                        block.onclick = function() {
                            const h = this.dataset.hour;
                            const year = h.slice(0,4);
                            const month = h.slice(4,6);
                            const day = h.slice(6,8);
                            const hourStr = h.slice(9,11);
                            const startTime = year + '-' + month + '-' + day + ' ' + hourStr + ':00:00';
                            const endTime = year + '-' + month + '-' + day + ' ' + hourStr + ':59:00';
                            queryFlamegraph(startTime, endTime);
                        };
                        
                        timeline.appendChild(block);
                    }
                    
                    document.getElementById('total-files').textContent = data.total_files;
                    document.getElementById('total-size').textContent = data.total_size;
                    document.getElementById('oldest-time').textContent = data.oldest || '-';
                    document.getElementById('latest-time').textContent = data.latest || '-';
                });
        }
        
        function queryFlamegraph(start, end) {
            document.getElementById('loading').classList.add('active');
            document.getElementById('result-card').style.display = 'none';
            
            const params = new URLSearchParams({start: start, end: end});
            fetch('/api/query?' + params)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('loading').classList.remove('active');
                    
                    if (data.error) {
                        alert('❌ ' + data.error);
                        return;
                    }
                    
                    document.getElementById('result-card').style.display = 'block';
                    document.getElementById('result-info').textContent = 
                        '时间段: ' + start + ' → ' + end + ' ｜ 文件数: ' + data.files + ' ｜ 采样数: ' + data.samples;
                    
                    // 显示火焰图（用 <object> 代替 <img>，保留交互能力）
                    const container = document.getElementById('flamegraph-container');
                    container.innerHTML = '<object data="/output/' + data.svg + '?t=' + Date.now() + '" type="image/svg+xml" width="100%" style="min-height:500px;border:1px solid #eee;border-radius:4px;">火焰图加载失败</object>';
                    
                    // 显示 Top 函数
                    const topList = document.getElementById('top-list');
                    topList.innerHTML = '';
                    if (data.top && data.top.length > 0) {
                        data.top.forEach(item => {
                            const li = document.createElement('li');
                            li.innerHTML = '<span class="func-name">' + item.name + '</span>' +
                                '<span class="func-pct">' + item.pct + '</span>';
                            topList.appendChild(li);
                        });
                    }
                })
                .catch(err => {
                    document.getElementById('loading').classList.remove('active');
                    alert('❌ 查询失败: ' + err);
                });
        }
        
        function customQuery() {
            const start = document.getElementById('start-time').value;
            const end = document.getElementById('end-time').value;
            if (!start) { alert('请选择起始时间'); return; }
            
            const startStr = start.replace('T', ' ') + ':00';
            const endStr = end ? end.replace('T', ' ') + ':00' : '';
            queryFlamegraph(startStr, endStr);
        }
        
        function runStressTest() {
            const btn = event.target;
            btn.disabled = true;
            document.getElementById('test-status').textContent = '⏳ 压力测试进行中（30秒）...';
            
            fetch('/api/stress-test')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('test-status').textContent = '🔥 压力测试已完成 ✓';
                    btn.disabled = false;
                    loadTimeline();
                    setTimeout(function() {
                        document.getElementById('test-status').textContent = '';
                    }, 5000);
                })
                .catch(err => {
                    document.getElementById('test-status').textContent = '❌ 测试失败';
                    btn.disabled = false;
                });
        }
        
        loadTimeline();
    </script>
</body>
</html>
'''


@app.route('/')
def index():
    """主页"""
    files = sorted(glob.glob(os.path.join(DATA_DIR, '*.perf.data')))
    
    total_size = sum(os.path.getsize(f) for f in files) if files else 0
    total_size_str = f"{total_size / 1024 / 1024:.1f} MB" if total_size > 0 else "0 MB"
    
    oldest = os.path.basename(files[0]).replace('.perf.data', '') if files else '-'
    latest = os.path.basename(files[-1]).replace('.perf.data', '') if files else '-'
    
    # 格式化时间
    def fmt_time(t):
        if t == '-' or len(t) < 15:
            return t
        return f"{t[:4]}-{t[4:6]}-{t[6:8]} {t[9:11]}:{t[11:13]}"
    
    return render_template_string(
        INDEX_HTML,
        total_files=len(files),
        total_size=total_size_str,
        oldest_time=fmt_time(oldest),
        latest_time=fmt_time(latest)
    )


@app.route('/api/files')
def api_files():
    """获取文件列表"""
    files = sorted(glob.glob(os.path.join(DATA_DIR, '*.perf.data')))
    basenames = [os.path.basename(f).replace('.perf.data', '') for f in files]
    
    total_size = sum(os.path.getsize(f) for f in files) if files else 0
    
    def fmt(t):
        if not t or len(t) < 15:
            return '-'
        return f"{t[:4]}-{t[4:6]}-{t[6:8]} {t[9:11]}:{t[11:13]}"
    
    return jsonify({
        'files': basenames,
        'total_files': len(files),
        'total_size': f"{total_size / 1024 / 1024:.1f} MB",
        'oldest': fmt(basenames[0]) if basenames else '-',
        'latest': fmt(basenames[-1]) if basenames else '-',
    })


@app.route('/api/query')
def api_query():
    """查询特定时间段的火焰图"""
    start_time = request.args.get('start', '')
    end_time = request.args.get('end', '')
    
    if not start_time:
        return jsonify({'error': '请提供起始时间'})
    
    # 调用 query.sh
    cmd = ['bash', '/opt/query.sh', DATA_DIR, start_time, 
           end_time if end_time else '', OUTPUT_DIR, FLAMEGRAPH_DIR]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        
        # 找到生成的 SVG
        svg_files = sorted(glob.glob(os.path.join(OUTPUT_DIR, 'flamegraph_*.svg')))
        txt_files = sorted(glob.glob(os.path.join(OUTPUT_DIR, 'top_functions_*.txt')))
        
        if not svg_files:
            return jsonify({'error': '火焰图生成失败', 'detail': output[:500]})
        
        latest_svg = os.path.basename(svg_files[-1])
        
        # 读取 Top 函数
        top_funcs = []
        if txt_files:
            with open(txt_files[-1]) as f:
                for line in f.readlines()[:20]:
                    line = line.strip()
                    if not line:
                        continue
                    # 格式: "stress-ng.. 87.1"
                    parts = line.rsplit(' ', 1)
                    if len(parts) == 2:
                        top_funcs.append({
                            'name': parts[0],
                            'pct': parts[1] + '%'
                        })
        
        return jsonify({
            'svg': latest_svg,
            'files': len(glob.glob(os.path.join(DATA_DIR, '*.perf.data'))),
            'samples': '~' + str(len(top_funcs) * 1000),
            'top': top_funcs[:15]
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': '查询超时（>120秒）'})
    except Exception as e:
        return jsonify({'error': str(e)})


@app.route('/output/<filename>')
def serve_output(filename):
    """提供生成的火焰图 SVG"""
    path = os.path.join(OUTPUT_DIR, filename)
    if os.path.exists(path):
        return send_file(path, mimetype='image/svg+xml')
    return '', 404


@app.route('/api/stress-test')
def stress_test():
    """启动压力测试（同步等待30秒）"""
    import time
    subprocess.run([
        'stress-ng', '--cpu', '2', '--cpu-method', 'matrixprod', '-t', '30s'
    ], timeout=60)
    return jsonify({'message': '压力测试已完成'})


if __name__ == '__main__':
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    port = int(os.environ.get('PORT', 8080))
    print(f"🌐 Web 界面: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
