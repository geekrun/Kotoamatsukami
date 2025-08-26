#!/bin/bash

echo "=== 手动创建强力混淆ARM64库 ==="

# 步骤1: 创建复杂测试代码
cat > large_arm64_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// 大量全局变量
int g_counters[50] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50};
char g_strings[10][100];
double g_data[200];

// 复杂函数1
int complex_func1(int x) {
    int result = x;
    for(int i = 0; i < 100; i++) {
        if(i % 7 == 0) result += g_counters[i%50];
        else if(i % 7 == 1) result -= g_counters[i%50];
        else if(i % 7 == 2) result *= 2;
        else if(i % 7 == 3) result /= 2;
        else if(i % 7 == 4) result ^= g_counters[i%50];
        else if(i % 7 == 5) result |= g_counters[i%50];
        else result &= g_counters[i%50];
        
        switch(result % 5) {
            case 0: result += 10; break;
            case 1: result += 20; break;
            case 2: result += 30; break;
            case 3: result += 40; break;
            default: result += 50; break;
        }
    }
    return result;
}

// 复杂函数2
double complex_func2(double y) {
    double result = y;
    for(int i = 0; i < 50; i++) {
        g_data[i] = sin(y + i) * cos(y - i);
        if(g_data[i] > 0.5) {
            result += sqrt(g_data[i]);
        } else if(g_data[i] > 0) {
            result += g_data[i] * g_data[i];  
        } else {
            result -= g_data[i];
        }
        
        if(i % 3 == 0) result *= 1.1;
        else if(i % 3 == 1) result *= 1.2;
        else result *= 1.3;
    }
    return result;
}

// 复杂函数3
void complex_func3(char* str) {
    int len = strlen(str);
    for(int i = 0; i < len; i++) {
        char c = str[i];
        if(c >= 'a' && c <= 'z') {
            str[i] = 'a' + (c - 'a' + g_counters[i%50]) % 26;
        } else if(c >= 'A' && c <= 'Z') {
            str[i] = 'A' + (c - 'A' + g_counters[i%50]) % 26;
        } else if(c >= '0' && c <= '9') {
            str[i] = '0' + (c - '0' + g_counters[i%50]) % 10;
        }
        
        // 更多分支
        switch(i % 8) {
            case 0: str[i] ^= 0x11; break;
            case 1: str[i] ^= 0x22; break;
            case 2: str[i] ^= 0x33; break;
            case 3: str[i] ^= 0x44; break;
            case 4: str[i] ^= 0x55; break;
            case 5: str[i] ^= 0x66; break;
            case 6: str[i] ^= 0x77; break;
            case 7: str[i] ^= 0x88; break;
        }
    }
}

// 导出的主函数
int __attribute__((visibility("default"))) massive_test_function(int input) {
    int r1 = complex_func1(input);
    double r2 = complex_func2((double)input);
    
    char buffer[1000];
    snprintf(buffer, sizeof(buffer), "Test_%d_Result_%d_%.2f", input, r1, r2);
    complex_func3(buffer);
    
    printf("Final: %s\n", buffer);
    return r1 + (int)r2;
}
EOF

# 步骤2: 编译正常版本
echo "编译正常版本..."
aarch64-linux-gnu-gcc -shared -fPIC -O2 large_arm64_test.c -o libmassive_normal_arm64.so -lm
echo "正常版本大小: $(ls -lh libmassive_normal_arm64.so | awk '{print $5}')"

# 步骤3: 生成LLVM IR
echo "生成ARM64 LLVM IR..."
clang-17 --target=aarch64-linux-gnu -S -emit-llvm -fPIC large_arm64_test.c -o large_arm64.ll
echo "原始IR行数: $(wc -l < large_arm64.ll)"

# 步骤4: 应用多种混淆
echo "应用Kotoamatsukami混淆..."
opt-17 --load-pass-plugin=./bin/Kotoamatsukami.so \
    large_arm64.ll \
    --passes=gv-encrypt,bogus-control-flow,flatten,split-basic-block,substitution \
    -S -o large_arm64_obfuscated.ll

if [ $? -eq 0 ]; then
    echo "混淆IR行数: $(wc -l < large_arm64_obfuscated.ll)"
    
    # 步骤5: 编译混淆版本
    echo "编译混淆版本..."
    aarch64-linux-gnu-gcc -shared -fPIC -O1 large_arm64_obfuscated.ll -o libmassive_obfuscated_arm64.so -lm
    
    echo "=== 结果对比 ==="
    ls -lh libmassive_*_arm64.so
    
    echo "=== 复杂度对比 ==="
    echo "原始IR: $(wc -l < large_arm64.ll)行"
    echo "混淆IR: $(wc -l < large_arm64_obfuscated.ll)行"
    echo "增长倍数: $(($(wc -l < large_arm64_obfuscated.ll) / $(wc -l < large_arm64.ll)))x"
    
else
    echo "混淆失败，检查插件路径"
fi
EOF

chmod +x create_obfuscated_arm64_lib.sh
echo "脚本已创建：create_obfuscated_arm64_lib.sh"
echo "运行: ./create_obfuscated_arm64_lib.sh"
