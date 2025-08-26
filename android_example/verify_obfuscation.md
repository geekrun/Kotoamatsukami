# Kotoamatsukami 混淆效果验证指南

## 1. 编译时验证

### 查看CMake构建日志
```bash
# 在Android Studio的Build输出中查找这些信息：
✅ Kotoamatsukami obfuscation enabled for ARM64
   Plugin: /path/to/Kotoamatsukami.so
   Config: /path/to/Kotoamatsukami.config
Applied Kotoamatsukami obfuscation to all sources
```

### 查看C++编译详细信息
```bash
# 在Gradle构建日志中查找类似内容：
-fpass-plugin=/path/to/Kotoamatsukami.so
```

## 2. 运行时验证

### 在Logcat中查看混淆日志
```bash
# 搜索这些tag:
KotoamatsukamiDemo
[Kotoamatsukami] Info: start to parse config file
```

## 3. 二进制文件验证

### APK大小对比
- 开启混淆前的APK大小
- 开启混淆后的APK大小（通常会增大）

### .so文件分析
```bash
# 提取APK中的.so文件
unzip app-debug.apk lib/arm64-v8a/libollvm_demo.so

# 检查文件大小
ls -lh lib/arm64-v8a/libollvm_demo.so

# 使用objdump查看符号（混淆后应该看到更多复杂的代码结构）
objdump -t lib/arm64-v8a/libollvm_demo.so
```

## 4. 代码结构验证

### 反编译分析
```bash
# 使用IDA Pro、Ghidra或Radare2分析.so文件
# 查看函数是否包含：
- 虚假控制流分支
- 额外的基本块
- 复杂化的跳转逻辑
- 加密的全局变量
```

## 5. 功能测试

### App运行测试
1. 安装APK到ARM64设备
2. 调用JNI函数
3. 检查返回结果是否正确
4. 查看Logcat输出

### 计算验证
```java
// 在MainActivity中测试
int result = calculateDemo(100);
Log.d("Test", "Calculate result: " + result);
```

## 预期效果

### 混淆成功的标志：
- ✅ 编译时间明显增加
- ✅ .so文件大小增大（可能2-10倍）
- ✅ 反编译后代码结构复杂化
- ✅ 全局字符串加密
- ✅ 控制流混淆可见

### 混淆失败的标志：
- ❌ 编译时间无明显变化
- ❌ .so文件大小无变化
- ❌ 反编译后代码结构简单
- ❌ 全局字符串明文可见
