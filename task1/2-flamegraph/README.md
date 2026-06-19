# 题目 1b：火焰图生成与热点分析

## 环境准备

```bash
# 确保已安装 perf 和 FlameGraph
sudo apt install -y linux-tools-common linux-tools-generic stress-ng
git clone https://github.com/brendangregg/FlameGraph.git ~/FlameGraph
```

## 一键生成

```bash
bash generate_flame.sh
```

自动完成：
1. 采集 matrixprod（15秒）→ 生成 `flamegraphs/matrixprod_flame.svg`
2. 采集 queens（15秒）→ 生成 `flamegraphs/queens_flame.svg`

## 手动操作

```bash
# 采集
sudo perf record -F 99 -g -o perf.data -- stress-ng --cpu 1 --cpu-method matrixprod -t 15s

# 生成火焰图
sudo perf script -f -i perf.data | ~/FlameGraph/stackcollapse-perf.pl | \
  ~/FlameGraph/flamegraph.pl > flamegraph.svg
```

## 产出文件

| 文件 | 说明 |
|------|------|
| `flamegraphs/matrixprod_flame.svg` | 矩阵乘法火焰图 |
| `flamegraphs/queens_flame.svg` | N皇后火焰图 |
| `flamegraphs/matrixprod_dwarf.svg` | dwarf 模式（更深调用栈） |
| `flamegraphs/queens_dwarf.svg` | dwarf 模式 |

## SVG 使用方法

直接双击 SVG 文件，浏览器打开后可：
- **鼠标悬停** → 显示函数名和采样占比
- **点击** → 放大该层
- **滚轮** → 缩放
