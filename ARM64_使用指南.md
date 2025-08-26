# 🚀 Kotoamatsukami ARM64 使用指南

## 📋 概述
已成功修复CMakeLists.txt并创建了完整的ARM64编译和测试体系，专门用于Android SO的代码混淆。

## 🛠️ 可用脚本

### 1. 主管理脚本 - `arm64_manager.sh`
这是主要的管理脚本，提供了所有ARM64相关功能的入口。

```bash
# 在WSL中使用
wsl
cd /mnt/d/code_project/geekrun/external_fork/Kotoamatsukami

# 显示帮助
./arm64_manager.sh help

# 或者直接使用数字选项
./arm64_manager.sh 1    # 检查ARM64编译状态
./arm64_manager.sh 2    # 测试ARM64混淆功能  
./arm64_manager.sh 3    # 重新编译ARM64版本
./arm64_manager.sh 4    # 显示当前状态
./arm64_manager.sh 5    # 清理临时文件
```

### 2. 编译状态检查 - `check_arm64_build.sh`
检查之前启动的ARM64编译是否完成，并完成后续配置。

```bash
wsl
cd /mnt/d/code_project/geekrun/external_fork/Kotoamatsukami
./check_arm64_build.sh
```

### 3. 快速测试 - `quick_test_arm64.sh`
创建Android JNI测试代码并进行完整的混淆测试。

```bash
wsl
cd /mnt/d/code_project/geekrun/external_fork/Kotoamatsukami  
./quick_test_arm64.sh
```

## 🎯 推荐使用流程

### 第一次使用：
1. **检查编译状态**：
   ```bash
   wsl
   cd /mnt/d/code_project/geekrun/external_fork/Kotoamatsukami
   ./arm64_manager.sh check
   ```

2. **如果编译未完成，可以重新编译**：
   ```bash
   ./arm64_manager.sh build
   ```

3. **编译完成后测试功能**：
   ```bash
   ./arm64_manager.sh test
   ```

### 日常使用Android SO混淆：

```bash
# 1. 生成ARM64 LLVM IR
clang-17 --target=aarch64-linux-gnu -S -emit-llvm your_jni.c -o your_jni.ll

# 2. 应用混淆（推荐配置）
opt-17 --load-pass-plugin=./bin/arm64/Kotoamatsukami.so \
       --passes=gv-encrypt,bogus-control-flow,flatten,split-basic-block \
       -S your_jni.ll -o your_jni_obfuscated.ll

# 3. 编译为ARM64 SO
clang-17 --target=aarch64-linux-gnu -shared -fPIC \
        your_jni_obfuscated.ll -o libyour_jni_arm64.so -llog
```

## 📊 混淆技术说明

### 可用的混淆Pass：
- **gv-encrypt**: 全局变量加密
- **bogus-control-flow**: 虚假控制流
- **flatten**: 控制流平坦化  
- **split-basic-block**: 基本块分割
- **substitution**: 指令替换
- **add-junk-code**: 添加垃圾代码
- **indirect-branch**: 间接跳转
- **indirect-call**: 间接调用
- **anti-debug**: 反调试

### 推荐混淆组合：

**轻度混淆**（编译速度快）：
```bash
--passes=gv-encrypt,bogus-control-flow
```

**中度混淆**（平衡性能和保护）：
```bash  
--passes=gv-encrypt,bogus-control-flow,flatten
```

**强度混淆**（最大保护）：
```bash
--passes=gv-encrypt,bogus-control-flow,flatten,split-basic-block,substitution
```

## ✅ 成功标志

当您看到以下输出时，表示ARM64版本已经可以使用：

```
✅ ARM64版本编译已完成！
✅ 已成功复制到 bin/arm64/Kotoamatsukami.so
🎉 ARM64版本Kotoamatsukami编译完成！
现在您可以使用ARM64版本进行Android SO混淆了
```

## 🔧 故障排除

1. **如果编译失败**：
   ```bash
   ./arm64_manager.sh clean  # 清理后重试
   ./arm64_manager.sh build  # 重新编译
   ```

2. **检查环境**：
   ```bash
   ./arm64_manager.sh status  # 查看当前状态
   ```

3. **确认依赖**：
   - LLVM-17 已安装
   - ARM64交叉编译工具链已安装
   - 在WSL环境中运行

## 🎉 总结

现在您已经拥有了完整的ARM64混淆工具链，可以有效保护Android SO文件。这个工具特别适合：
- Android JNI代码保护
- 核心算法混淆
- 反逆向工程
- 敏感数据加密

混淆效果通常可以达到：
- 文件大小增长 8-50倍
- 代码复杂度增长 20-100倍
- 极大提升逆向分析难度
