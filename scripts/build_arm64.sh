#!/bin/bash

echo "=== Kotoamatsukami ARM64 交叉编译脚本 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查必要工具
echo -e "${YELLOW}检查编译环境...${NC}"
if ! command -v clang-17 &> /dev/null; then
    echo -e "${RED}错误: clang-17 未找到${NC}"
    exit 1
fi

if ! command -v clang++-17 &> /dev/null; then
    echo -e "${RED}错误: clang++-17 未找到${NC}"
    exit 1
fi

# 检查lld链接器
if ! command -v lld &> /dev/null && ! command -v ld.lld &> /dev/null; then
    echo -e "${RED}错误: LLVM链接器(lld)未找到，ARM64交叉编译需要lld${NC}"
    echo -e "${YELLOW}提示: 请安装 lld 或 llvm 完整包${NC}"
    exit 1
fi

echo -e "${GREEN}✓ clang-17 工具链和lld链接器检查通过${NC}"

# 检查LLVM是否支持ARM64
echo -e "${YELLOW}检查ARM64目标支持...${NC}"
if ! llvm-config-17 --targets-built | grep -q "AArch64"; then
    echo -e "${RED}错误: LLVM不支持AArch64目标${NC}"
    exit 1
fi

echo -e "${GREEN}✓ ARM64目标支持检查通过${NC}"

# 创建ARM64构建目录
echo -e "${YELLOW}准备构建目录...${NC}"
cd ..  # 回到项目根目录
rm -rf build-arm64
mkdir -p build-arm64
cd build-arm64

echo -e "${GREEN}✓ 构建目录准备完成${NC}"

# 配置CMake进行ARM64交叉编译
echo -e "${YELLOW}配置CMake进行ARM64交叉编译...${NC}"

# ARM64交叉编译配置
export CC=clang-17
export CXX=clang++-17
export CFLAGS="-target aarch64-linux-gnu"
export CXXFLAGS="-target aarch64-linux-gnu"

# 运行cmake配置
cmake .. \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER=clang-17 \
    -DCMAKE_CXX_COMPILER=clang++-17 \
    -DCMAKE_C_FLAGS="-target aarch64-linux-gnu -fuse-ld=lld" \
    -DCMAKE_CXX_FLAGS="-target aarch64-linux-gnu -fuse-ld=lld" \
    -DCMAKE_SHARED_LINKER_FLAGS="-target aarch64-linux-gnu -fuse-ld=lld" \
    -DCMAKE_VERBOSE_MAKEFILE=ON

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: CMake配置失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ CMake配置成功${NC}"

# 开始编译
echo -e "${YELLOW}开始ARM64编译...${NC}"
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ ARM64编译成功${NC}"

# 检查生成的文件
echo -e "${YELLOW}检查生成的ARM64动态库...${NC}"
if [ -f "Kotoamatsukami.so" ]; then
    echo -e "${GREEN}✓ 找到 Kotoamatsukami.so${NC}"
    
    # 显示文件信息
    echo -e "${YELLOW}文件信息:${NC}"
    ls -lh Kotoamatsukami.so
    
    echo -e "${YELLOW}架构信息:${NC}"
    file Kotoamatsukami.so
    
    # 复制到bin目录
    echo -e "${YELLOW}复制到bin目录...${NC}"
    mkdir -p ../bin/arm64
    cp Kotoamatsukami.so ../bin/arm64/
    
    echo -e "${GREEN}✓ ARM64版本已复制到 bin/arm64/Kotoamatsukami.so${NC}"
    
    # 显示最终结果
    echo -e "${GREEN}"
    echo "================================="
    echo "  ARM64编译完成！"
    echo "================================="
    echo -e "${NC}"
    echo "生成文件位置:"
    echo "- 构建目录: build-arm64/Kotoamatsukami.so"
    echo "- 部署目录: bin/arm64/Kotoamatsukami.so"
    echo ""
    echo "文件详情:"
    file ../bin/arm64/Kotoamatsukami.so
    echo ""
    ls -lh ../bin/arm64/Kotoamatsukami.so
    
else
    echo -e "${RED}错误: 未找到生成的动态库文件${NC}"
    exit 1
fi

echo -e "${GREEN}ARM64交叉编译脚本执行完成！${NC}"
