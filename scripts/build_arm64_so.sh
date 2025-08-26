#!/bin/bash

echo "=== 编译ARM64动态库(.so)文件 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# 安装ARM64开发环境
echo -e "${YELLOW}步骤1: 确保ARM64开发环境完整...${NC}"
apt update -qq
apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross \
    libstdc++-11-dev-arm64-cross build-essential crossbuild-essential-arm64 -qq

echo -e "${GREEN}✓ ARM64开发环境准备完成${NC}"

# 创建测试共享库源码
echo -e "${YELLOW}步骤2: 创建ARM64共享库源码...${NC}"
cat > test_shared.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

// 导出的全局变量
int shared_counter = 100;
char shared_message[] = "ARM64 Shared Library with Kotoamatsukami!";

// 导出的计算函数
int __attribute__((visibility("default"))) calculate_fibonacci(int n) {
    if (n <= 1) return n;
    return calculate_fibonacci(n - 1) + calculate_fibonacci(n - 2);
}

// 导出的数据处理函数
int __attribute__((visibility("default"))) process_shared_data(int value) {
    int result = shared_counter;
    
    if (value > 50) {
        result += value * 2;
    } else if (value > 20) {
        result += value + 10;
    } else {
        result += value * 3;
    }
    
    // 模拟复杂计算
    for (int i = 0; i < 10; i++) {
        result = (result * 7 + 13) % 1000;
    }
    
    return result;
}

// 导出的字符串处理函数
void __attribute__((visibility("default"))) print_shared_info(void) {
    printf("Shared Library Info: %s\n", shared_message);
    printf("Shared Counter: %d\n", shared_counter);
    
    int fib_result = calculate_fibonacci(8);
    printf("Fibonacci(8) = %d\n", fib_result);
}

// 库初始化函数
void __attribute__((constructor)) init_shared_lib(void) {
    shared_counter += 42;
}
EOF

echo -e "${GREEN}✓ ARM64共享库源码创建完成${NC}"

# 编译正常版本ARM64动态库作为对比
echo -e "${YELLOW}步骤3: 编译正常版本ARM64动态库...${NC}"
aarch64-linux-gnu-gcc -shared -fPIC -O2 test_shared.c -o libtest_normal_arm64.so

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 正常版本ARM64动态库编译成功${NC}"
else
    echo -e "${RED}✗ 正常版本编译失败${NC}"
    exit 1
fi

# 使用Kotoamatsukami混淆并编译ARM64动态库
echo -e "${YELLOW}步骤4: 使用Kotoamatsukami混淆并编译ARM64动态库...${NC}"

# 首先生成LLVM IR
clang-17 --target=aarch64-linux-gnu -S -emit-llvm -fPIC test_shared.c -o test_shared_arm64.ll

# 使用Kotoamatsukami混淆
opt-17 --load-pass-plugin=/root/code/Kotoamatsukami/bin/Kotoamatsukami.so \
    test_shared_arm64.ll --passes=gv-encrypt,bogus-control-flow,flatten -S \
    -o test_shared_arm64_obfuscated.ll

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Kotoamatsukami混淆处理完成${NC}"
else
    echo -e "${RED}✗ 混淆处理失败${NC}"
    exit 1
fi

# 编译混淆后的ARM64动态库
echo -e "${YELLOW}步骤5: 编译混淆后的ARM64动态库...${NC}"
clang-17 --target=aarch64-linux-gnu -shared -fPIC -O2 \
    test_shared_arm64_obfuscated.ll -o libtest_obfuscated_arm64.so \
    --sysroot=/usr/aarch64-linux-gnu \
    -B/usr/aarch64-linux-gnu/bin \
    --gcc-toolchain=/usr

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 混淆版本ARM64动态库编译成功${NC}"
else
    echo -e "${RED}✗ 混淆版本编译失败，尝试使用gcc...${NC}"
    
    # 先生成目标文件
    clang-17 --target=aarch64-linux-gnu -c -fPIC test_shared_arm64_obfuscated.ll -o test_shared_arm64.o
    
    # 使用gcc链接
    aarch64-linux-gnu-gcc -shared test_shared_arm64.o -o libtest_obfuscated_arm64.so
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 使用gcc成功编译混淆版本ARM64动态库${NC}"
    else
        echo -e "${RED}✗ 编译失败${NC}"
        exit 1
    fi
fi

# 检查生成的文件
echo -e "${BLUE}=== ARM64动态库编译结果 ===${NC}"

echo -e "${GREEN}文件列表:${NC}"
ls -lh libtest_*_arm64.so test_shared_arm64*.ll

echo -e "${GREEN}文件架构信息:${NC}"
file libtest_*_arm64.so

echo -e "${GREEN}动态库符号信息:${NC}"
echo "正常版本导出符号:"
aarch64-linux-gnu-readelf -Ws libtest_normal_arm64.so | grep -E "(calculate_fibonacci|process_shared_data|print_shared_info)"

echo "混淆版本导出符号:"
aarch64-linux-gnu-readelf -Ws libtest_obfuscated_arm64.so | grep -E "(calculate_fibonacci|process_shared_data|print_shared_info)"

echo -e "${GREEN}代码复杂度对比:${NC}"
echo -n "原始LLVM IR行数: "
wc -l < test_shared_arm64.ll
echo -n "混淆后LLVM IR行数: "
wc -l < test_shared_arm64_obfuscated.ll

echo -e "${GREEN}文件大小对比:${NC}"
echo -n "正常版本大小: "
ls -lh libtest_normal_arm64.so | awk '{print $5}'
echo -n "混淆版本大小: "
ls -lh libtest_obfuscated_arm64.so | awk '{print $5}'

# 创建测试程序
echo -e "${YELLOW}步骤6: 创建ARM64测试程序...${NC}"
cat > test_arm64_client.c << 'EOF'
#include <stdio.h>
#include <dlfcn.h>

int main() {
    void *handle = dlopen("./libtest_obfuscated_arm64.so", RTLD_LAZY);
    if (!handle) {
        printf("无法加载动态库: %s\n", dlerror());
        return 1;
    }
    
    // 获取函数指针
    int (*calc_fib)(int) = dlsym(handle, "calculate_fibonacci");
    int (*process_data)(int) = dlsym(handle, "process_shared_data");
    void (*print_info)(void) = dlsym(handle, "print_shared_info");
    
    if (calc_fib && process_data && print_info) {
        printf("=== ARM64混淆动态库测试 ===\n");
        print_info();
        printf("Fibonacci(10) = %d\n", calc_fib(10));
        printf("Process(75) = %d\n", process_data(75));
        printf("测试完成！\n");
    } else {
        printf("无法找到导出函数\n");
    }
    
    dlclose(handle);
    return 0;
}
EOF

# 编译测试程序
aarch64-linux-gnu-gcc test_arm64_client.c -ldl -o test_arm64_client

echo -e "${BLUE}=== 最终结果 ===${NC}"
echo -e "${GREEN}✅ ARM64动态库编译成功！${NC}"
echo ""
echo "生成的ARM64动态库文件:"
echo "- libtest_normal_arm64.so     : 正常版本"
echo "- libtest_obfuscated_arm64.so : Kotoamatsukami混淆版本"
echo "- test_arm64_client           : 测试程序"
echo ""
echo "在ARM64环境中可以运行: ./test_arm64_client"

# 清理中间文件
rm -f test_shared.c test_shared_arm64*.ll test_shared_arm64.o test_arm64_client.c

echo -e "${GREEN}ARM64动态库编译脚本执行完成！${NC}"
