#!/bin/bash

echo "=== 快速测试ARM64版本混淆功能 ==="

# 动态检测项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
cd "$PROJECT_ROOT" || exit 1

# 检查ARM64版本是否存在
if [ ! -f "bin/arm64/Kotoamatsukami.so" ]; then
    echo "❌ ARM64版本不存在，请先运行 check_arm64_build.sh"
    exit 1
fi

echo "✅ ARM64版本存在，创建测试代码..."

# 创建测试代码
cat > android_test.c << 'EOF'
#include <jni.h>
#include <string.h>

// 模拟Android JNI函数
jstring Java_com_example_app_MainActivity_getSecretKey(JNIEnv *env, jobject thiz) {
    char secret[] = "MySecretKey123";
    int key = 0x42;
    
    // 简单加密
    for(int i = 0; i < strlen(secret); i++) {
        secret[i] ^= key;
    }
    
    return (*env)->NewStringUTF(env, secret);
}

int native_calculation(int a, int b) {
    if (a > b) {
        return a * b + 100;
    } else {
        return (a + b) * 2;
    }
}
EOF

echo "✅ 测试代码创建完成"

echo "🔧 生成ARM64 LLVM IR..."
clang-17 --target=aarch64-linux-gnu -S -emit-llvm android_test.c -o android_test_arm64.ll

if [ $? -eq 0 ]; then
    echo "✅ LLVM IR生成成功"
    wc -l android_test_arm64.ll
    
    echo "🔐 应用混淆技术..."
    opt-17 --load-pass-plugin=./bin/arm64/Kotoamatsukami.so \
           --passes=gv-encrypt,bogus-control-flow,flatten \
           -S android_test_arm64.ll -o android_test_obfuscated_arm64.ll
    
    if [ $? -eq 0 ]; then
        echo "✅ 混淆成功！"
        echo "📊 混淆效果对比："
        echo "原始: $(wc -l android_test_arm64.ll | awk '{print $1}') 行"
        echo "混淆: $(wc -l android_test_obfuscated_arm64.ll | awk '{print $1}') 行"
        echo "增长: $(($(wc -l android_test_obfuscated_arm64.ll | awk '{print $1}') / $(wc -l android_test_arm64.ll | awk '{print $1}')))x"
        
        echo "🔨 编译为ARM64 SO..."
        clang-17 --target=aarch64-linux-gnu -shared -fPIC \
                android_test_obfuscated_arm64.ll -o libandroid_obfuscated_arm64.so
        
        if [ $? -eq 0 ]; then
            echo "✅ ARM64 SO编译成功！"
            ls -lh libandroid_obfuscated_arm64.so
            file libandroid_obfuscated_arm64.so
            echo "🎉 Android SO混淆测试完成！"
        else
            echo "❌ ARM64 SO编译失败"
        fi
    else
        echo "❌ 混淆失败"
    fi
else
    echo "❌ LLVM IR生成失败"
fi
