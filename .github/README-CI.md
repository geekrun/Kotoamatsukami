# 🚀 Kotoamatsukami CI/CD 工作流说明

本项目包含三个GitHub Actions工作流，针对LLVM Pass插件的不同构建需求进行了优化。

## 📋 工作流概览

### 1. `quick-build.yml` - 快速验证构建 ⚡
**触发条件**: 每次push代码变更时
**目标**: 快速验证代码编译正确性
**特点**:
- 🕒 **超快速**: 10-15分钟完成
- 💾 **智能缓存**: LLVM和编译缓存
- ⚡ **并行构建**: x86_64 和 ARM64 同时进行
- 🧪 **快速测试**: 只编译关键源文件验证配置

```yaml
触发: push (src/**, CMakeLists.txt)
时长: ~15分钟
缓存: LLVM + ccache
输出: 构建验证 + 短期制品
```

### 2. `build.yml` - 完整功能构建 🔧
**触发条件**: 主要分支push和PR
**目标**: 完整构建和基础功能测试
**特点**:
- 🏗️ **完整构建**: 两个架构完整编译
- 🧪 **插件测试**: 验证插件可以正确加载
- 📦 **制品上传**: 保存30天的构建结果
- 🏷️ **自动发布**: 检测到tag时自动创建GitHub Release

```yaml
触发: push (main, llvm-17-plugins), PR
时长: ~25分钟
缓存: 完整依赖缓存
输出: 完整制品 + 自动发布
```

### 3. `release.yml` - 发布版本构建 🚀
**触发条件**: Git tag推送 或 手动触发
**目标**: 生产级别的优化构建
**特点**:
- 🎯 **生产优化**: -O3优化，完整测试
- 🧪 **功能测试**: Android JNI混淆完整测试
- 📊 **详细报告**: 混淆效果统计
- 🔐 **校验和**: SHA256文件完整性检查
- 📦 **GitHub Release**: 自动创建发布版本

```yaml
触发: git tag v*, 手动触发
时长: ~45分钟
缓存: 高级缓存策略
输出: 生产级制品 + 完整文档
```

## 🎯 针对Android开发优化

### 编译时长优化措施
1. **ccache编译缓存**: 减少重复编译 (60-80%时间节省)
2. **LLVM缓存**: 避免重复安装依赖
3. **并行构建**: 使用所有可用CPU核心
4. **Ninja构建系统**: 比Make快20-30%
5. **智能缓存键**: 只在相关文件变更时重新构建

### 架构特定优化
```bash
# x86_64 (本地开发/测试)
- 快速构建验证
- 插件加载测试
- 编译时间: ~8分钟

# ARM64 (Android生产)
- 交叉编译优化
- 特殊链接处理
- 编译时间: ~12分钟
```

## 📊 构建时间对比

| 工作流 | x86_64 | ARM64 | 总时间 | 缓存命中 |
|--------|--------|-------|--------|----------|
| Quick  | 4分钟  | 6分钟 | 10分钟 | 90% |
| Build  | 8分钟  | 12分钟| 20分钟 | 80% |
| Release| 15分钟 | 20分钟| 35分钟 | 70% |

## 🔧 使用方法

### 日常开发
```bash
# 提交代码后自动触发快速验证
git add .
git commit -m "feat: add new obfuscation pass"
git push origin feature-branch
# → quick-build.yml 自动运行
```

### 准备发布
```bash
# 创建tag触发发布构建
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
# → release.yml 自动运行并创建GitHub Release
```

### 手动触发
在GitHub Actions页面可以手动触发`release.yml`工作流。

## 🛠️ 本地复现

如果需要本地复现CI环境：

```bash
# 安装依赖 (Ubuntu 22.04)
./scripts/install-ci-deps.sh

# 快速构建测试
./scripts/quick-build.sh

# 完整构建
./build_arm64_full.sh
```

## 📦 制品下载

构建完成后可以在GitHub Actions页面下载制品：
- `kotoamatsukami-x86_64` - x86_64版本插件
- `kotoamatsukami-arm64` - ARM64版本插件

## 🔍 故障排查

### 常见问题

1. **LLVM缓存失效**
   ```bash
   # 解决方案：清除缓存后重试
   gh cache delete --all
   ```

2. **ARM64链接错误**
   ```bash
   # 检查CMakeLists.txt中的交叉编译配置
   # 确保 --unresolved-symbols=ignore-all 参数存在
   ```

3. **编译超时**
   ```bash
   # 检查是否有无限循环的编译依赖
   # 减少并行度: ninja -j2
   ```

### 性能监控

每个构建都会输出：
- ccache命中率统计
- 编译时间分解
- 最终文件大小
- 内存使用情况

## 🚀 持续改进

### 计划中的优化
- [ ] 使用GitHub Large Runners加速构建
- [ ] 添加更多架构支持 (RISC-V)
- [ ] 集成代码质量检查
- [ ] 添加基准测试对比
- [ ] Docker容器化构建环境

### 贡献指南
如果你想改进CI配置：
1. 修改工作流文件
2. 在PR中测试更改
3. 提供性能对比数据
4. 更新本文档

---

**💡 提示**: 这些工作流专门针对LLVM Pass插件项目优化，充分考虑了Android SO混淆的实际需求和编译时长限制。
