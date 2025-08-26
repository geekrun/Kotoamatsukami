#!/bin/bash
# 本地CI测试脚本 - 模拟GitHub Actions环境

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."
    
    local missing_deps=()
    
    # 检查基础工具
    command -v cmake >/dev/null 2>&1 || missing_deps+=("cmake")
    command -v ninja >/dev/null 2>&1 || missing_deps+=("ninja-build")
    command -v clang-17 >/dev/null 2>&1 || missing_deps+=("clang-17")
    command -v opt-17 >/dev/null 2>&1 || missing_deps+=("llvm-17")
    command -v ccache >/dev/null 2>&1 || missing_deps+=("ccache")
    
    # 检查ARM64工具（如果要测试ARM64）
    if [[ "$1" == "arm64" ]]; then
        command -v aarch64-linux-gnu-gcc >/dev/null 2>&1 || missing_deps+=("gcc-aarch64-linux-gnu")
        command -v aarch64-linux-gnu-g++ >/dev/null 2>&1 || missing_deps+=("g++-aarch64-linux-gnu")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "安装命令:"
        echo "sudo apt-get install -y ${missing_deps[*]}"
        return 1
    fi
    
    log_success "所有依赖已满足"
    return 0
}

# 检查LLVM配置
check_llvm() {
    log_info "检查LLVM配置..."
    
    # 检查LLVM目录
    LLVM_DIR="/usr/lib/llvm-17/lib/cmake/llvm"
    if [ ! -d "$LLVM_DIR" ]; then
        log_error "LLVM-17 cmake配置目录不存在: $LLVM_DIR"
        return 1
    fi
    
    # 检查LLVM版本
    local llvm_version=$(opt-17 --version | grep "LLVM version" | awk '{print $3}')
    log_info "LLVM版本: $llvm_version"
    
    if [[ ! "$llvm_version" =~ ^17\. ]]; then
        log_warn "LLVM版本可能不匹配，期望17.x，实际: $llvm_version"
    fi
    
    # 检查关键LLVM文件
    local llvm_files=(
        "/usr/lib/llvm-17/include/llvm/Pass.h"
        "/usr/lib/llvm-17/lib/libLLVM-17.so.1"
    )
    
    for file in "${llvm_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_warn "LLVM文件缺失: $file"
        fi
    done
    
    log_success "LLVM配置检查完成"
}

# 设置缓存
setup_cache() {
    log_info "设置构建缓存..."
    
    # 备份现有ccache配置
    if [ -f ~/.ccache/ccache.conf ]; then
        cp ~/.ccache/ccache.conf ~/.ccache/ccache.conf.backup.$(date +%s)
        log_info "已备份现有ccache配置"
    fi
    
    # 创建缓存目录
    mkdir -p ~/.cache/ccache-ci-test
    
    # 配置ccache（使用独立的缓存目录）
    ccache --set-config=cache_dir=~/.cache/ccache-ci-test
    ccache --set-config=max_size=1G
    ccache --set-config=compression=true
    ccache --zero-stats
    
    log_success "缓存配置完成（使用独立目录）"
}

# 模拟GitHub Actions的CMake配置
test_cmake_config() {
    local arch=$1
    local build_dir="build-ci-test-$arch"
    
    log_info "测试CMAKE配置 ($arch)..."
    
    # 如果在scripts目录中，先回到项目根目录
    if [[ $(basename "$(pwd)") == "scripts" ]]; then
        cd ..
    fi
    
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    if [[ "$arch" == "x86_64" ]]; then
        cmake .. \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER=clang-17 \
            -DCMAKE_CXX_COMPILER=clang++-17 \
            -DLLVM_DIR=/usr/lib/llvm-17/lib/cmake/llvm
    else
        cmake .. \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_SYSTEM_NAME=Linux \
            -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
            -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
            -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
            -DCMAKE_FIND_ROOT_PATH=/usr/aarch64-linux-gnu \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DLLVM_DIR=/usr/lib/llvm-17/lib/cmake/llvm
    fi
    
    if [ $? -eq 0 ]; then
        log_success "CMAKE配置成功 ($arch)"
    else
        log_error "CMAKE配置失败 ($arch)"
        cd ..
        return 1
    fi
    
    cd ..
}

# 快速编译测试
test_quick_build() {
    local arch=$1
    local build_dir="build-ci-test-$arch"
    
    log_info "快速编译测试 ($arch)..."
    
    # 如果在scripts目录中，先回到项目根目录
    if [[ $(basename "$(pwd)") == "scripts" ]]; then
        cd ..
    fi
    
    cd "$build_dir"
    
    # 只编译一个源文件测试
    if ninja Kotoamatsukami; then
        log_success "快速编译测试通过 ($arch)"
    else
        log_error "快速编译测试失败 ($arch)"
        cd ..
        return 1
    fi
    
    cd ..
}

# 完整编译测试
test_full_build() {
    local arch=$1
    local build_dir="build-ci-test-$arch"
    
    log_info "完整编译测试 ($arch)..."
    
    # 如果在scripts目录中，先回到项目根目录
    if [[ $(basename "$(pwd)") == "scripts" ]]; then
        cd ..
    fi
    
    cd "$build_dir"
    
    local start_time=$(date +%s)
    
    if ninja -j$(nproc); then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "完整编译成功 ($arch) - 用时: ${duration}秒"
        
        # 检查生成的文件
        if [ -f "Kotoamatsukami.so" ] || [ -f "libKotoamatsukami.so" ]; then
            local so_file=$(ls *Kotoamatsukami*.so | head -1)
            log_info "生成文件: $so_file"
            ls -lh "$so_file"
            file "$so_file"
        else
            log_error "未找到生成的.so文件"
            cd ..
            return 1
        fi
    else
        log_error "完整编译失败 ($arch)"
        cd ..
        return 1
    fi
    
    cd ..
}

# 功能测试
test_functionality() {
    local arch=$1
    local build_dir="build-ci-test-$arch"
    
    # 只对x86_64进行功能测试
    if [[ "$arch" != "x86_64" ]]; then
        log_info "跳过ARM64功能测试"
        return 0
    fi
    
    log_info "插件功能测试 ($arch)..."
    
    # 如果在scripts目录中，先回到项目根目录
    if [[ $(basename "$(pwd)") == "scripts" ]]; then
        cd ..
    fi
    
    cd "$build_dir"
    
    local so_file=$(ls *Kotoamatsukami*.so | head -1)
    if [ ! -f "$so_file" ]; then
        log_error "找不到插件文件"
        cd ..
        return 1
    fi
    
    # 创建测试文件
    cat > test_plugin.c << 'EOF'
int global_var = 42;
int test_array[5] = {1, 2, 3, 4, 5};

int simple_func(int a, int b) {
    if (a > b) {
        return a + b + global_var;
    }
    return b - a + global_var;
}

int main() {
    return simple_func(10, 5);
}
EOF
    
    # 生成LLVM IR
    if clang-17 -S -emit-llvm -O1 test_plugin.c -o test_plugin.ll; then
        log_success "LLVM IR生成成功"
    else
        log_error "LLVM IR生成失败"
        cd ..
        return 1
    fi
    
    # 测试插件加载
    log_info "测试插件加载..."
    if timeout 30s opt-17 --load-pass-plugin=./"$so_file" \
        --passes="gv-encrypt" -S test_plugin.ll -o test_plugin_out.ll 2>/dev/null; then
        log_success "插件加载测试通过"
        
        # 检查混淆效果
        local original_lines=$(wc -l < test_plugin.ll)
        local obfuscated_lines=$(wc -l < test_plugin_out.ll)
        log_info "混淆效果: $original_lines -> $obfuscated_lines 行"
        
        if [ $obfuscated_lines -gt $original_lines ]; then
            log_success "混淆功能正常工作"
        else
            log_warn "混淆效果不明显"
        fi
    else
        log_error "插件加载测试失败"
        cd ..
        return 1
    fi
    
    cd ..
}

# 清理测试文件
cleanup() {
    log_info "清理测试文件..."
    rm -rf build-ci-test-*
    log_success "清理完成"
}

# 显示缓存统计
show_cache_stats() {
    if command -v ccache >/dev/null 2>&1; then
        log_info "构建缓存统计:"
        ccache --show-stats
    fi
}

# 主函数
main() {
    echo "=================================="
    echo "🚀 Kotoamatsukami 本地CI测试"
    echo "=================================="
    
    local test_arch=${1:-"x86_64"}
    local test_mode=${2:-"quick"}  # quick, full, both, check-only
    
    log_info "测试架构: $test_arch"
    log_info "测试模式: $test_mode"
    
    # 安全模式检查
    if [[ "$test_mode" == "check-only" ]]; then
        log_info "🛡️ 安全模式：只检查不执行构建"
    fi
    echo
    
    # 检查依赖
    if ! check_dependencies "$test_arch"; then
        if [[ "$test_mode" == "check-only" ]]; then
            log_warn "依赖检查失败，但继续进行其他检查"
        else
            log_error "依赖检查失败，请先安装缺失的依赖"
            exit 1
        fi
    fi
    
    # 检查LLVM
    check_llvm
    
    # 安全模式只做检查
    if [[ "$test_mode" == "check-only" ]]; then
        log_info "🔍 安全模式：仅检查环境和配置"
        
        # 只检查CMake配置，不实际执行
        log_info "检查CMake配置（模拟）..."
        log_success "环境检查完成 - 未执行任何构建或修改操作"
        
        # 显示会执行的命令
        echo
        log_info "如果执行完整测试，将运行以下命令："
        echo "  1. 创建临时目录: build-ci-test-$test_arch"
        echo "  2. 配置CMake"
        echo "  3. 编译测试"
        echo "  4. 清理临时文件"
        
        return 0
    fi
    
    # 设置缓存
    setup_cache
    
    # 根据模式运行测试
    if [[ "$test_mode" == "both" ]]; then
        # 测试两个架构
        for arch in "x86_64" "arm64"; do
            echo
            log_info "开始测试 $arch 架构..."
            
            if ! check_dependencies "$arch"; then
                log_warn "跳过 $arch 测试 - 依赖不满足"
                continue
            fi
            
            test_cmake_config "$arch" || continue
            test_quick_build "$arch" || continue
            test_full_build "$arch" || continue
            test_functionality "$arch"
        done
    else
        # 测试单个架构
        test_cmake_config "$test_arch" || exit 1
        test_quick_build "$test_arch" || exit 1
        
        if [[ "$test_mode" == "full" ]]; then
            test_full_build "$test_arch" || exit 1
            test_functionality "$test_arch" || exit 1
        fi
    fi
    
    # 显示统计
    show_cache_stats
    
    echo
    log_success "🎉 本地CI测试完成！"
    
    # 询问是否清理
    if [[ "${CI_CLEANUP:-true}" != "false" ]]; then
        read -p "是否清理测试文件? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup
        fi
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 [架构] [模式]"
    echo
    echo "架构:"
    echo "  x86_64  - 测试x86_64架构 (默认)"
    echo "  arm64   - 测试ARM64架构"
    echo "  both    - 测试两个架构"
    echo
    echo "模式:"
    echo "  check-only  - 🛡️ 安全模式：只检查环境，不执行构建"
    echo "  quick       - 快速测试 (默认) - 配置和快速编译测试"  
    echo "  full        - 完整测试 - 包括完整编译和功能测试"
    echo
    echo "示例:"
    echo "  $0                        # 快速测试x86_64"
    echo "  $0 x86_64 check-only      # 🛡️ 只检查环境，不修改任何文件"
    echo "  $0 x86_64 full            # 完整测试x86_64"
    echo "  $0 arm64 quick            # 快速测试ARM64"
    echo "  $0 both full              # 完整测试两个架构"
    echo
    echo "🛡️ 安全模式说明:"
    echo "  - 只检查依赖和环境配置"
    echo "  - 不创建任何文件或目录"
    echo "  - 不修改任何系统配置"
    echo "  - 完全安全，不会影响开发环境"
    echo
    echo "环境变量:"
    echo "  CI_CLEANUP=false          # 不自动清理测试文件"
}

# 解析参数
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 运行主函数
main "$@"
