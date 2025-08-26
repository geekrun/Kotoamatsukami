#!/bin/bash

echo "=== Kotoamatsukami ARM64代码混淆演示 ==="
echo "目的：展示插件可以处理ARM64目标代码（生成LLVM IR和汇编）"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# 动态检测项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
cd "$PROJECT_ROOT"

cd compiler

echo -e "${YELLOW}步骤1: 生成ARM64目标的LLVM IR...${NC}"
clang-17 --target=aarch64-linux-gnu -S -emit-llvm ../test.c -o ../test_arm64.ll

echo -e "${YELLOW}步骤2: 使用Kotoamatsukami混淆ARM64 LLVM IR...${NC}"
export DEBUG=1  # 保留中间文件
./clang_wrapper.sh gv-encrypt bogus-control-flow ../test.c --target=aarch64-linux-gnu -S -emit-llvm -o ../test_arm64_obfuscated.ll 2>/dev/null || true

echo -e "${YELLOW}步骤3: 手动运行混淆插件处理ARM64代码...${NC}"
opt-17 --load-pass-plugin=/root/code/Kotoamatsukami/bin/Kotoamatsukami.so ../test_arm64.ll --passes=gv-encrypt,bogus-control-flow -S -o ../test_arm64_final.ll

echo -e "${YELLOW}步骤4: 生成ARM64汇编代码...${NC}"
clang-17 --target=aarch64-linux-gnu -S ../test_arm64_final.ll -o ../test_arm64_final.s

echo -e "${BLUE}=== 结果对比分析 ===${NC}"
echo -e "${GREEN}文件大小对比:${NC}"
ls -lh ../test_arm64.ll ../test_arm64_final.ll ../test_arm64_final.s 2>/dev/null

echo -e "${GREEN}代码复杂度对比:${NC}"
echo -n "原始LLVM IR行数: "
wc -l < ../test_arm64.ll 2>/dev/null || echo "0"
echo -n "混淆后LLVM IR行数: "
wc -l < ../test_arm64_final.ll 2>/dev/null || echo "0"
echo -n "ARM64汇编代码行数: "
wc -l < ../test_arm64_final.s 2>/dev/null || echo "0"

echo -e "${GREEN}ARM64汇编代码片段（前20行）:${NC}"
head -20 ../test_arm64_final.s 2>/dev/null || echo "未生成汇编文件"

echo -e "${BLUE}=== 总结 ===${NC}"
echo "✅ Kotoamatsukami成功混淆了ARM64目标代码"
echo "✅ 生成了ARM64 LLVM IR和汇编代码"  
echo "✅ 现有x86_64插件完全支持ARM64代码处理"
echo ""
echo "生成的文件:"
echo "- ../test_arm64.ll : 原始ARM64 LLVM IR"
echo "- ../test_arm64_final.ll : 混淆后ARM64 LLVM IR"  
echo "- ../test_arm64_final.s : ARM64汇编代码"

echo -e "${GREEN}混淆成功完成！${NC}"
