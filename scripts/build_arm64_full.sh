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
        ls -lh Kotoamatsukami.so
        file Kotoamatsukami.so
        
        mkdir -p ../bin/arm64
        cp Kotoamatsukami.so ../bin/arm64/
        echo -e "${GREEN}已复制到 bin/arm64/Kotoamatsukami.so${NC}"
    else
        echo -e "${RED}编译失败${NC}"
    fi
else
    echo -e "${RED}CMake配置失败，可能需要手动安装更多依赖${NC}"
fi
