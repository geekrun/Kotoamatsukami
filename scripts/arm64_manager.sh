#!/bin/bash

echo "🚀 Kotoamatsukami ARM64 管理器"
echo "用于Android SO混淆的ARM64版本管理"
echo "=================================="

# 动态检测项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

case "${1:-help}" in
    "check"|"1")
        echo "📋 检查ARM64编译状态..."
        bash "$SCRIPT_DIR/check_arm64_build.sh"
        ;;
    
    "test"|"2") 
        echo "🧪 测试ARM64混淆功能..."
        bash "$SCRIPT_DIR/quick_test_arm64.sh"
        ;;
    
    "build"|"3")
        echo "🔨 重新编译ARM64版本..."
        cd "$PROJECT_ROOT"
        bash ./scripts/build_arm64_full.sh
        ;;
    
    "status"|"4")
        echo "📊 显示当前状态..."
        cd "$PROJECT_ROOT"
        echo "=== 文件状态 ==="
        echo "x86_64版本: $([ -f bin/Kotoamatsukami.so ] && ls -lh bin/Kotoamatsukami.so | awk '{print $5}' || echo '❌ 不存在')"
        echo "ARM64版本:  $([ -f bin/arm64/Kotoamatsukami.so ] && ls -lh bin/arm64/Kotoamatsukami.so | awk '{print $5}' || echo '❌ 不存在')"
        echo ""
        echo "=== 编译环境 ==="
        echo "LLVM: $(llvm-config-17 --version 2>/dev/null || echo '未安装')"
        echo "ARM64 GCC: $(aarch64-linux-gnu-gcc --version 2>/dev/null | head -1 || echo '未安装')"
        ;;
    
    "clean"|"5")
        echo "🧹 清理编译文件..."
        cd "$PROJECT_ROOT"
        rm -rf build-arm64-full
        rm -f android_test*.ll android_test.c lib*.so
        echo "✅ 清理完成"
        ;;
    
    "help"|*)
        echo "使用方法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  1 | check  - 检查ARM64编译状态并完成配置"
        echo "  2 | test   - 快速测试ARM64混淆功能"  
        echo "  3 | build  - 重新编译ARM64版本"
        echo "  4 | status - 显示当前状态"
        echo "  5 | clean  - 清理临时文件"
        echo "  help       - 显示此帮助"
        echo ""
        echo "示例:"
        echo "  $0 1        # 检查并完成ARM64配置"
        echo "  $0 test     # 测试Android SO混淆"
        echo ""
        echo "🎯 主要用途: Android SO文件的代码混淆保护"
        ;;
esac
