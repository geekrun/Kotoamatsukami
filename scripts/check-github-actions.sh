#!/bin/bash
# GitHub Actions 配置检查脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 检查YAML语法
check_yaml_syntax() {
    local file=$1
    log_info "检查YAML语法: $file"
    
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint "$file" 2>/dev/null; then
            log_success "YAML语法正确: $file"
        else
            log_error "YAML语法错误: $file"
            yamllint "$file" || true
            return 1
        fi
    elif python3 -c "import yaml" 2>/dev/null; then
        if python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        yaml.safe_load(f)
    print('YAML syntax OK')
except yaml.YAMLError as e:
    print(f'YAML Error: {e}')
    sys.exit(1)
"; then
            log_success "YAML语法正确: $file"
        else
            log_error "YAML语法错误: $file"
            return 1
        fi
    else
        log_warn "未找到YAML检查工具 (yamllint或python3+yaml)，跳过语法检查"
    fi
}

# 检查GitHub Actions配置问题
check_actions_config() {
    local file=$1
    log_info "检查Actions配置: $file"
    
    local issues=0
    
    # 检查常见问题
    if grep -q "uses: actions/checkout@v4" "$file"; then
        log_success "使用了推荐的checkout版本"
    elif grep -q "uses: actions/checkout@" "$file"; then
        log_warn "可能使用了旧版本的actions/checkout"
        ((issues++))
    fi
    
    # 检查缓存配置
    if grep -q "uses: actions/cache@v3" "$file"; then
        log_success "使用了缓存配置"
    else
        log_warn "未发现缓存配置，可能影响构建速度"
    fi
    
    # 检查超时配置
    if grep -q "timeout-minutes:" "$file"; then
        local timeout=$(grep "timeout-minutes:" "$file" | head -1 | awk '{print $2}')
        if [ "$timeout" -gt 60 ]; then
            log_warn "超时时间设置过长: ${timeout}分钟"
            ((issues++))
        else
            log_success "超时配置合理: ${timeout}分钟"
        fi
    else
        log_warn "未设置超时时间，可能导致任务hang住"
        ((issues++))
    fi
    
    # 检查并行配置
    if grep -q "strategy:" "$file"; then
        log_success "使用了并行构建策略"
    fi
    
    # 检查依赖版本
    local llvm_issues=0
    if grep -q "llvm-17" "$file"; then
        log_success "明确指定了LLVM-17版本"
    else
        log_warn "未明确指定LLVM版本"
        ((llvm_issues++))
    fi
    
    if grep -q "clang-17" "$file"; then
        log_success "明确指定了Clang-17版本"
    else
        log_warn "未明确指定Clang版本"
        ((llvm_issues++))
    fi
    
    # 检查ARM64特定配置
    if grep -q "aarch64-linux-gnu" "$file"; then
        log_success "包含ARM64交叉编译配置"
        
        # 检查ARM64特定问题
        if grep -q "CMAKE_FIND_ROOT_PATH_MODE" "$file"; then
            log_success "ARM64 CMAKE配置正确"
        else
            log_warn "ARM64 CMAKE配置可能不完整"
            ((issues++))
        fi
    fi
    
    # 检查秘钥使用
    if grep -q "GITHUB_TOKEN" "$file"; then
        log_success "正确使用了GITHUB_TOKEN"
    fi
    
    return $issues
}

# 检查构建步骤逻辑
check_build_logic() {
    local file=$1
    log_info "检查构建逻辑: $file"
    
    local issues=0
    
    # 检查步骤顺序
    local step_order=(
        "checkout"
        "cache"
        "install.*dependencies"
        "cmake"
        "build\|ninja\|make"
    )
    
    local current_line=1
    for step in "${step_order[@]}"; do
        local step_line=$(grep -n -i "$step" "$file" | head -1 | cut -d: -f1)
        if [ -n "$step_line" ]; then
            if [ "$step_line" -ge "$current_line" ]; then
                current_line=$step_line
                log_success "构建步骤顺序正确: $step"
            else
                log_warn "构建步骤顺序可能有问题: $step"
                ((issues++))
            fi
        fi
    done
    
    return $issues
}

# 检查性能优化
check_performance_optimizations() {
    local file=$1
    log_info "检查性能优化: $file"
    
    local optimizations=0
    
    # 检查缓存
    if grep -q "cache" "$file"; then
        log_success "✓ 使用了缓存"
        ((optimizations++))
    fi
    
    # 检查并行编译
    if grep -q "nproc\|j\$(nproc)\|-j" "$file"; then
        log_success "✓ 使用了并行编译"
        ((optimizations++))
    fi
    
    # 检查ccache
    if grep -q "ccache" "$file"; then
        log_success "✓ 使用了编译缓存(ccache)"
        ((optimizations++))
    fi
    
    # 检查Ninja构建
    if grep -q "Ninja\|-G Ninja" "$file"; then
        log_success "✓ 使用了Ninja构建系统"
        ((optimizations++))
    fi
    
    # 检查条件执行
    if grep -q "if:" "$file"; then
        log_success "✓ 使用了条件执行"
        ((optimizations++))
    fi
    
    log_info "性能优化措施: $optimizations/5"
    
    if [ $optimizations -lt 3 ]; then
        log_warn "性能优化不足，建议添加更多优化措施"
        return 1
    fi
    
    return 0
}

# 检查LLVM特定配置
check_llvm_specifics() {
    local file=$1
    log_info "检查LLVM插件特定配置: $file"
    
    local issues=0
    
    # 检查LLVM_DIR设置
    if grep -q "LLVM_DIR" "$file"; then
        log_success "正确设置了LLVM_DIR"
    else
        log_error "未设置LLVM_DIR，可能导致找不到LLVM"
        ((issues++))
    fi
    
    # 检查交叉编译特殊处理
    if grep -q "unresolved-symbols\|allow-shlib-undefined" "$file"; then
        log_success "包含了插件交叉编译的特殊处理"
    else
        log_warn "可能缺少插件交叉编译的特殊链接选项"
    fi
    
    # 检查插件测试
    if grep -q "opt.*--load-pass-plugin" "$file"; then
        log_success "包含了插件功能测试"
    else
        log_warn "缺少插件功能测试步骤"
        ((issues++))
    fi
    
    return $issues
}

# 估算构建时间
estimate_build_time() {
    local file=$1
    log_info "估算构建时间: $file"
    
    local estimated_time=0
    
    # 基础时间
    estimated_time=$((estimated_time + 2))  # checkout + setup
    
    # LLVM安装时间
    if grep -q "apt.*install.*llvm" "$file"; then
        if grep -q "cache" "$file"; then
            estimated_time=$((estimated_time + 2))  # 有缓存
        else
            estimated_time=$((estimated_time + 8))  # 无缓存
        fi
    fi
    
    # 编译时间
    if grep -q "ccache\|cache" "$file"; then
        estimated_time=$((estimated_time + 5))  # 有缓存的编译
    else
        estimated_time=$((estimated_time + 15)) # 无缓存编译
    fi
    
    # ARM64额外时间
    if grep -q "aarch64\|arm64" "$file"; then
        estimated_time=$((estimated_time + 3))  # 交叉编译额外时间
    fi
    
    # 测试时间
    if grep -q "test\|opt.*--load-pass-plugin" "$file"; then
        estimated_time=$((estimated_time + 2))
    fi
    
    echo "预估构建时间: ~${estimated_time}分钟"
    
    if [ $estimated_time -gt 30 ]; then
        log_warn "构建时间可能过长，考虑更多优化"
        return 1
    elif [ $estimated_time -gt 45 ]; then
        log_error "构建时间过长，需要重新设计"
        return 2
    fi
    
    return 0
}

# 主检查函数
check_workflow_file() {
    local file=$1
    local basename=$(basename "$file")
    
    echo "=================================="
    echo "🔍 检查工作流: $basename"
    echo "=================================="
    
    local total_issues=0
    
    # YAML语法检查
    check_yaml_syntax "$file" || ((total_issues++))
    echo
    
    # Actions配置检查
    check_actions_config "$file"
    local config_issues=$?
    ((total_issues += config_issues))
    echo
    
    # 构建逻辑检查
    check_build_logic "$file"
    local logic_issues=$?
    ((total_issues += logic_issues))
    echo
    
    # 性能优化检查
    check_performance_optimizations "$file" || ((total_issues++))
    echo
    
    # LLVM特定检查
    check_llvm_specifics "$file"
    local llvm_issues=$?
    ((total_issues += llvm_issues))
    echo
    
    # 构建时间估算
    estimate_build_time "$file"
    echo
    
    # 总结
    if [ $total_issues -eq 0 ]; then
        log_success "✅ $basename 配置检查通过"
    elif [ $total_issues -le 3 ]; then
        log_warn "⚠️  $basename 有 $total_issues 个潜在问题"
    else
        log_error "❌ $basename 有 $total_issues 个问题需要修复"
    fi
    
    return $total_issues
}

# 生成改进建议
generate_suggestions() {
    local workflow_dir=".github/workflows"
    
    echo
    echo "=================================="
    echo "💡 改进建议"
    echo "=================================="
    
    echo "1. 性能优化建议:"
    echo "   - 使用 ccache 编译缓存"
    echo "   - 设置合适的缓存键"
    echo "   - 使用 Ninja 构建系统"
    echo "   - 添加并行编译 (-j\$(nproc))"
    echo
    
    echo "2. 可靠性改进:"
    echo "   - 设置合理的超时时间"
    echo "   - 添加重试机制"
    echo "   - 使用特定版本的Actions"
    echo "   - 添加失败时的调试信息"
    echo
    
    echo "3. LLVM插件特定:"
    echo "   - 确保LLVM_DIR正确设置"
    echo "   - ARM64交叉编译使用特殊链接选项"
    echo "   - 添加插件功能测试"
    echo "   - 验证生成的.so文件架构"
    echo
    
    echo "4. 监控和反馈:"
    echo "   - 添加构建时间统计"
    echo "   - 输出详细的构建日志"
    echo "   - 添加制品上传"
    echo "   - 设置通知机制"
}

# 主函数
main() {
    echo "🚀 GitHub Actions 配置检查工具"
    echo "=================================="
    
    local workflow_dir=".github/workflows"
    
    if [ ! -d "$workflow_dir" ]; then
        log_error "未找到 .github/workflows 目录"
        exit 1
    fi
    
    # 检查依赖工具
    local missing_tools=()
    command -v python3 >/dev/null || missing_tools+=("python3")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warn "建议安装以下工具以获得更好的检查效果:"
        echo "  sudo apt-get install -y yamllint python3-yaml"
    fi
    
    local total_files=0
    local total_issues=0
    
    # 检查所有工作流文件
    for workflow_file in "$workflow_dir"/*.yml "$workflow_dir"/*.yaml; do
        if [ -f "$workflow_file" ]; then
            ((total_files++))
            check_workflow_file "$workflow_file"
            local file_issues=$?
            ((total_issues += file_issues))
            echo
        fi
    done
    
    # 总结报告
    echo "=================================="
    echo "📊 检查总结"
    echo "=================================="
    echo "检查文件数: $total_files"
    echo "发现问题数: $total_issues"
    echo
    
    if [ $total_issues -eq 0 ]; then
        log_success "🎉 所有工作流配置都很好！"
    elif [ $total_issues -le 5 ]; then
        log_warn "⚠️  发现一些小问题，建议修复"
    else
        log_error "❌ 发现较多问题，建议重新检查配置"
    fi
    
    # 生成建议
    generate_suggestions
    
    return $total_issues
}

# 显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "GitHub Actions 配置检查工具"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "该脚本会检查 .github/workflows/ 目录下的所有工作流文件，"
    echo "包括YAML语法、配置逻辑、性能优化等方面。"
    echo
    echo "建议安装以下工具以获得最佳检查效果:"
    echo "  sudo apt-get install -y yamllint python3-yaml"
    exit 0
fi

# 运行主函数
main "$@"
