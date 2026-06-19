/**
 * cache_line_test.c
 * 
 * 验证 CPU Cache Line 大小对数组遍历性能的影响
 * 
 * 原理：用不同步长遍历一个大数组，测量访问延迟
 * 预期：stride=64 时出现性能拐点（因为 x86 的 Cache Line 是 64 字节）
 * 
 * 编译：gcc -O2 cache_line_test.c -o cache_line_test
 * 运行：./cache_line_test
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>

#define ARRAY_SIZE (32 * 1024 * 1024)  // 32MB 数组（远大于 L3 Cache）
#define STRIDES_COUNT 10

// 获取当前时间（纳秒）
static inline uint64_t get_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000UL + (uint64_t)ts.tv_nsec;
}

int main() {
    int strides[] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512};
    const int iterations = 100;  // 每个 stride 重复次数

    printf("============================================\n");
    printf("  CPU Cache Line 大小验证测试\n");
    printf("  数组大小: %d MB\n", ARRAY_SIZE / 1024 / 1024);
    printf("============================================\n\n");

    // 分配大数组
    volatile char *array = (volatile char *)malloc(ARRAY_SIZE);
    if (!array) {
        printf("内存分配失败！\n");
        return 1;
    }

    // 初始化，确保物理内存真的分配了
    for (int i = 0; i < ARRAY_SIZE; i += 4096) {
        array[i] = 0;
    }

    printf("| %10s | %12s | %20s |\n", "Stride(B)", "总时间(ns)", "相对速度(越大越快)");
    printf("|------------|--------------|----------------------|\n");

    uint64_t base_time = 0;

    for (int s = 0; s < STRIDES_COUNT; s++) {
        int stride = strides[s];
        
        // 热身
        for (int i = 0; i < ARRAY_SIZE; i += stride) {
            array[i]++;
        }

        uint64_t total_time = 0;

        for (int iter = 0; iter < iterations; iter++) {
            uint64_t start = get_ns();

            // 核心：按 stride 步长遍历整个数组
            for (int i = 0; i < ARRAY_SIZE; i += stride) {
                array[i]++;
            }

            uint64_t end = get_ns();
            total_time += (end - start);
        }

        uint64_t avg_time = total_time / iterations;

        if (s == 0) base_time = avg_time;

        double ratio = (double)base_time / (double)avg_time;
        
        printf("| %10d | %12lu | %20.2f |\n", stride, avg_time, ratio);
    }

    printf("\n");
    printf("结果解读：\n");
    printf("  - strides=1 最快（同一 Cache Line 内连续访问）\n");
    printf("  - stride=64 附近出现拐点（Cache Line = 64 字节）\n");
    printf("  - stride>64 后速度趋于稳定（每次都跨越 Cache Line 边界）\n");
    printf("\n");
    printf("建议配合 perf 使用：\n");
    printf("  sudo perf stat -e L1-dcache-load-misses,LLC-load-misses ./cache_line_test --stride 1\n");
    printf("  sudo perf stat -e L1-dcache-load-misses,LLC-load-misses ./cache_line_test --stride 64\n\n");

    free((void*)array);
    return 0;
}
