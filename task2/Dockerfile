# ============================================================
# CPU Profiler — Docker 镜像
# 基于 Ubuntu 22.04，集成 perf + FlameGraph + Flask Web UI
# ============================================================
FROM ubuntu:22.04

LABEL description="CPU Profiler — 持续 CPU Profiling 工具"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV DATA_DIR=/data
ENV OUTPUT_DIR=/output
ENV FLAMEGRAPH_DIR=/opt/FlameGraph
ENV PORT=8080

# 安装依赖
RUN apt-get update && apt-get install -y \
    linux-tools-common \
    build-essential \
    libelf1 \
    libdw1 \
    libunwind8 \
    libslang2 \
    libperl5.34 \
    libnuma1 \
    libtraceevent1 \
    liblzma5 \
    libbz2-1.0 \
    tzdata \
    git \
    python3 \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 编译 stress-ng（带帧指针，让火焰图显示函数名）
RUN git clone --depth 1 https://github.com/ColinIanKing/stress-ng.git /tmp/stress-ng-src && \
    cd /tmp/stress-ng-src && \
    make -j$(nproc) CFLAGS="-g -fno-omit-frame-pointer -O2" && \
    cp stress-ng /usr/bin/stress-ng && \
    rm -rf /tmp/stress-ng-src

# 安装 Python 依赖
COPY src/requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# 克隆 FlameGraph
RUN git clone https://github.com/brendangregg/FlameGraph.git /opt/FlameGraph --depth 1

# 复制脚本
COPY src/collector.sh /opt/collector.sh
COPY src/query.sh /opt/query.sh
COPY src/server.py /opt/server.py
RUN chmod +x /opt/collector.sh /opt/query.sh

# 创建数据目录
RUN mkdir -p /data /output

# 启动入口
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
