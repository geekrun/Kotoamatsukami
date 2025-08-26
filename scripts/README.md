# Scripts 目录说明

本目录包含了Kotoamatsukami项目的所有脚本文件。

## 脚本分类

### 构建相关脚本
- `build_arm64_full.sh` - 完整ARM64构建脚本，包含依赖安装
- `build_arm64_so.sh` - ARM64共享库构建脚本
- `build_arm64.sh` - 基础ARM64构建脚本

### ARM64管理脚本
- `arm64_manager.sh` - ARM64环境管理脚本

### 演示和测试脚本
- `arm64_obfuscation_demo.sh` - ARM64混淆演示脚本
- `check_arm64_build.sh` - ARM64构建检查脚本
- `create_obfuscated_arm64_lib.sh` - 创建混淆ARM64库脚本
- `quick_test_arm64.sh` - ARM64快速测试脚本

### CI/CD脚本
- `local-ci-test.sh` - 本地CI测试脚本
- `check-github-actions.sh` - GitHub Actions配置检查脚本

## 使用说明

1. 构建项目前请确保已安装必要的依赖
2. ARM64相关脚本需要交叉编译环境
3. CI脚本用于验证构建环境和配置

## 注意事项

- 所有脚本应该在项目根目录下执行
- ARM64脚本需要相应的交叉编译工具链
- 建议在执行前先查看脚本内容了解具体操作
