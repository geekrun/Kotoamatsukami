#!/bin/bash

echo "=== 安装ARM64交叉编译完整环境并编译ARM64插件 ==="

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}安装ARM64交叉编译工具链...${NC}"
apt update
apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross

echo -e "${YELLOW}创建ARM64构建目录...${NC}"

# 动态检测并确保在项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

echo "脚本目录: $SCRIPT_DIR"
echo "项目根目录: $PROJECT_ROOT"

cd "$PROJECT_ROOT" || exit 1

rm -rf build-arm64-full
mkdir build-arm64-full
cd build-arm64-full

echo -e "${YELLOW}配置CMake使用完整的ARM64工具链...${NC}"
cmake .. \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
    -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
    -DCMAKE_FIND_ROOT_PATH=/usr/aarch64-linux-gnu \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_VERBOSE_MAKEFILE=ON

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ CMake配置成功${NC}"
    
    echo -e "${YELLOW}开始编译ARM64版本...${NC}"
    make -j$(nproc)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ARM64版本编译成功！${NC}"
        
        echo "文件信息:"
        # 检查生成的文件名（可能是 libKotoamatsukami.so 或 Kotoamatsukami.so）
        if [ -f "libKotoamatsukami.so" ]; then
            SO_FILE="libKotoamatsukami.so"
        elif [ -f "Kotoamatsukami.so" ]; then
            SO_FILE="Kotoamatsukami.so"
        else
            echo -e "${RED}未找到生成的SO文件${NC}"
            ls -lh *.so 2>/dev/null || echo "没有找到任何.so文件"
            exit 1
        fi
        
        ls -lh $SO_FILE
        file $SO_FILE
        
        mkdir -p ../bin/arm64
        cp $SO_FILE ../bin/arm64/Kotoamatsukami.so
        echo -e "${GREEN}已复制 $SO_FILE 到 bin/arm64/Kotoamatsukami.so${NC}"
    else
        echo -e "${RED}编译失败${NC}"
    fi
else
    echo -e "${RED}CMake配置失败，可能需要手动安装更多依赖${NC}"
fi
