#!/bin/bash

echo "=== 检查ARM64编译状态和完成后续工作 ==="

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 动态检测项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
BUILD_DIR="$PROJECT_ROOT/build-arm64-full"

cd "$PROJECT_ROOT" || exit 1

echo -e "${YELLOW}1. 检查ARM64编译目录...${NC}"
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}❌ ARM64编译目录不存在${NC}"
    exit 1
fi

cd "$BUILD_DIR" || exit 1

echo -e "${YELLOW}2. 检查编译是否完成...${NC}"
if [ -f "Kotoamatsukami.so" ]; then
    echo -e "${GREEN}✅ ARM64版本编译已完成！${NC}"
    
    echo -e "${YELLOW}3. 检查文件信息...${NC}"
    ls -lh Kotoamatsukami.so
    file Kotoamatsukami.so
    
    echo -e "${YELLOW}4. 创建ARM64目录并复制文件...${NC}"
    mkdir -p "$PROJECT_ROOT/bin/arm64"
    cp Kotoamatsukami.so "$PROJECT_ROOT/bin/arm64/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 已成功复制到 bin/arm64/Kotoamatsukami.so${NC}"
        
        echo -e "${YELLOW}5. 验证复制的文件...${NC}"
        ls -lh "$PROJECT_ROOT/bin/arm64/"
        file "$PROJECT_ROOT/bin/arm64/Kotoamatsukami.so"
        
        echo -e "${GREEN}🎉 ARM64版本Kotoamatsukami编译完成！${NC}"
        echo -e "${GREEN}现在您可以使用ARM64版本进行Android SO混淆了${NC}"
        
        echo -e "\n${YELLOW}=== 使用方法 ===${NC}"
        echo "对于Android SO混淆，可以使用以下步骤："
        echo "1. 使用clang生成ARM64 LLVM IR："
        echo "   clang-17 --target=aarch64-linux-gnu -S -emit-llvm your_code.c -o your_code.ll"
        echo ""
        echo "2. 应用混淆："
        echo "   opt-17 --load-pass-plugin=./bin/arm64/Kotoamatsukami.so \\"
        echo "          --passes=gv-encrypt,bogus-control-flow,flatten \\"
        echo "          -S your_code.ll -o your_code_obfuscated.ll"
        echo ""
        echo "3. 编译为ARM64目标："
        echo "   clang-17 --target=aarch64-linux-gnu -shared -fPIC \\"
        echo "            your_code_obfuscated.ll -o libobfuscated_arm64.so"
        
    else
        echo -e "${RED}❌ 复制文件失败${NC}"
        exit 1
    fi
    
else
    echo -e "${YELLOW}⏳ 编译仍在进行中，检查编译进程...${NC}"
    ps aux | grep -E "(make|aarch64-linux-gnu)" | grep -v grep
    
    echo -e "${YELLOW}等待编译完成，您可以稍后再运行此脚本${NC}"
    echo "或者手动检查编译进度：cd $BUILD_DIR && make"
fi

echo -e "\n${YELLOW}=== 当前项目状态 ===${NC}"
echo "x86_64版本: $(ls -lh $PROJECT_ROOT/bin/Kotoamatsukami.so 2>/dev/null | awk '{print $5}' || echo '不存在')"
echo "ARM64版本:  $(ls -lh $PROJECT_ROOT/bin/arm64/Kotoamatsukami.so 2>/dev/null | awk '{print $5}' || echo '不存在')"
