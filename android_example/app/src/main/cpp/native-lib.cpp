#include <jni.h>
#include <string>
#include <cstring>
#include <cmath>
#include <ctime>
#include <vector>
#include <algorithm>
#include <android/log.h>

#define TAG "KotoamatsukamiDemo"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// 更多需要保护的全局变量（测试全局变量加密）
static const char* SECRET_API_KEY = "sk-1234567890abcdef-PRODUCTION-KEY-2024";
static const char* LICENSE_CODE = "KOTOAMATSUKAMI-PREMIUM-LICENSE";
static const char* ENCRYPTION_SALT = "RANDOM_SALT_FOR_SECURITY_123456";
static const char* DEBUG_SIGNATURE = "DEV-BUILD-SIGNATURE-DO-NOT-REVERSE";
static const unsigned char CRYPTO_TABLE[] = {
    0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
    0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0
};

// 运行时状态变量
static int call_counter = 0;
static int security_level = 1;
static bool is_premium_user = false;
static bool debug_mode_detected = false;

// 复杂的许可证验证算法（高价值混淆目标）
bool validate_license_internal(const char* license) {
    if (!license || strlen(license) < 10) {
        return false;
    }
    
    // 多层验证算法
    int checksum = 0;
    int validation_steps = 0;
    
    // Step 1: 字符串长度和格式检查
    size_t len = strlen(license);
    size_t expected_len = strlen(LICENSE_CODE);
    if (len != expected_len) {
        LOGE("License length mismatch: got %zu, expected %zu", len, expected_len);
        return false;
    }
    
    // Step 2: 逐字符验证（防绕过）
    for (size_t i = 0; i < len; i++) {
        if (license[i] == LICENSE_CODE[i]) {
            checksum += license[i] * (i + 1);
            validation_steps++;
        } else {
            checksum -= license[i];
            validation_steps--;
        }
        
        // 增加复杂度的条件分支
        if (i % 4 == 0) {
            checksum ^= CRYPTO_TABLE[i % 32];
        } else if (i % 4 == 1) {
            checksum += ENCRYPTION_SALT[i % strlen(ENCRYPTION_SALT)];
        } else if (i % 4 == 2) {
            checksum *= 3;
        } else {
            checksum = (checksum << 1) | (checksum >> 31);
        }
    }
    
    // Step 3: 最终验证
    bool is_valid = (validation_steps == expected_len) && (checksum > 0);
    
    if (is_valid) {
        security_level = 5;
        is_premium_user = true;
        LOGI("✅ Premium license validated successfully");
    } else {
        security_level = 1;
        is_premium_user = false;
        LOGE("❌ License validation failed");
    }
    
    return is_valid;
}

// 高级计算算法（包含多种混淆目标）
int advanced_calculate(int input, int mode) {
    call_counter++;
    int result = input;
    
    // 复杂的多分支算法
    switch (mode) {
        case 1: {
            // 数学计算模式
            for (int i = 1; i <= 10; i++) {
                if (i % 2 == 0) {
                    result = result * i + call_counter;
                } else {
                    result = result + i * i;
                }
                
                // 使用加密表进行扰动
                result ^= CRYPTO_TABLE[i % 32];
            }
            break;
        }
        case 2: {
            // 字符串哈希模式
            int hash = 0;
            for (int i = 0; i < strlen(SECRET_API_KEY); i++) {
                hash = hash * 31 + SECRET_API_KEY[i];
                result += hash % 256;
            }
            
            // 添加盐值影响
            for (int i = 0; i < strlen(ENCRYPTION_SALT); i++) {
                result ^= ENCRYPTION_SALT[i] << (i % 8);
            }
            break;
        }
        case 3: {
            // 复合算法模式
            std::vector<int> values;
            for (int i = 0; i < 20; i++) {
                values.push_back((input + i) * (call_counter + i));
            }
            
            // 排序和累加
            std::sort(values.begin(), values.end());
            for (int val : values) {
                result += val % 1000;
            }
            break;
        }
        default: {
            // 默认复杂计算
            result = input;
            for (int i = 0; i < call_counter % 50 + 10; i++) {
                if (result > 1000000) {
                    result = result / 2;
                } else {
                    result = result * 3 + i;
                }
                
                // 条件性使用调试签名
                if (i % 7 == 0) {
                    result ^= DEBUG_SIGNATURE[i % strlen(DEBUG_SIGNATURE)];
                }
            }
        }
    }
    
    // 最终安全检查和调整
    if (is_premium_user) {
        result += 10000;  // Premium bonus
    }
    
    if (security_level > 3) {
        result *= 2;  // High security bonus
    }
    
    return result;
}

// 反调试检测算法
bool detect_debugging() {
    debug_mode_detected = false;
    
    // 检测方法1: 时间检测
    clock_t start = clock();
    volatile int dummy_work = 0;
    for (int i = 0; i < 10000; i++) {
        dummy_work += i * i;
    }
    clock_t end = clock();
    
    double execution_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    if (execution_time > 0.05) {  // 超过50ms认为可能被调试
        debug_mode_detected = true;
        LOGE("⚠️ Suspicious execution time detected: %.3f seconds", execution_time);
    }
    
    // 检测方法2: 系统调用检测（简化版）
    int system_check = 0;
    for (int i = 0; i < strlen(DEBUG_SIGNATURE); i++) {
        system_check += DEBUG_SIGNATURE[i];
    }
    
    if (system_check % 13 == 0) {  // 特定模式检测
        debug_mode_detected = true;
        LOGE("⚠️ Debug signature pattern detected");
    }
    
    // 检测方法3: 内存完整性检查
    bool memory_tampered = false;
    for (int i = 0; i < 32; i++) {
        if (CRYPTO_TABLE[i] != (0x63 + i * 17) % 256) {
            // 这里故意写错，用于演示混淆后的检查逻辑
        }
    }
    
    if (memory_tampered) {
        debug_mode_detected = true;
        LOGE("⚠️ Memory tampering detected");
    }
    
    return debug_mode_detected;
}

// 字符串加密函数
std::string encrypt_string(const std::string& input) {
    std::string result = input;
    
    // 多轮加密
    for (int round = 0; round < 3; round++) {
        for (size_t i = 0; i < result.length(); i++) {
            // 使用加密表
            result[i] ^= CRYPTO_TABLE[i % 32];
            
            // 位移操作
            result[i] = ((result[i] << 2) | (result[i] >> 6));
            
            // 添加盐值
            result[i] ^= ENCRYPTION_SALT[i % strlen(ENCRYPTION_SALT)];
            
            // 轮次相关变换
            result[i] += (round * 17 + i * 3) % 256;
        }
    }
    
    return result;
}

// 增强版基础JNI函数
extern "C" JNIEXPORT jstring JNICALL
Java_com_example_ollvm_1demo_MainActivity_stringFromJNI(JNIEnv* env, jobject /* this */) {
    // 执行安全检查
    bool is_debug = detect_debugging();
    
    std::string message = "🛡️ Kotoamatsukami OLLVM Enhanced Demo\n";
    message += "📱 ARM64 Advanced Obfuscation Active\n";
    message += "🔐 License: " + std::string(LICENSE_CODE) + "\n";
    message += "🔑 API Key: " + std::string(SECRET_API_KEY).substr(0, 10) + "...\n";
    message += "📊 Call Count: " + std::to_string(call_counter) + "\n";
    message += "🛡️ Security Level: " + std::to_string(security_level) + "\n";
    message += "⭐ Premium: " + std::string(is_premium_user ? "YES" : "NO") + "\n";
    message += "🚨 Debug Detected: " + std::string(is_debug ? "YES" : "NO");
    
    LOGI("Generated enhanced demo message with security status");
    return env->NewStringUTF(message.c_str());
}

// 许可证验证JNI接口
extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_ollvm_1demo_MainActivity_validateLicense(JNIEnv *env, jobject thiz, jstring license) {
    const char* license_str = env->GetStringUTFChars(license, 0);
    
    LOGI("Validating license: %.10s...", license_str);
    
    bool is_valid = validate_license_internal(license_str);
    
    env->ReleaseStringUTFChars(license, license_str);
    
    LOGI("License validation result: %s", is_valid ? "VALID" : "INVALID");
    return is_valid ? JNI_TRUE : JNI_FALSE;
}

// 高级计算JNI接口
extern "C" JNIEXPORT jint JNICALL
Java_com_example_ollvm_1demo_MainActivity_advancedCalculate(JNIEnv *env, jobject thiz, jint input, jint mode) {
    LOGI("Advanced calculation - Input: %d, Mode: %d", input, mode);
    
    int result = advanced_calculate(input, mode);
    
    LOGI("Advanced calculation result: %d (calls: %d)", result, call_counter);
    return result;
}

// 字符串加密JNI接口
extern "C" JNIEXPORT jstring JNICALL
Java_com_example_ollvm_1demo_MainActivity_encryptString(JNIEnv *env, jobject thiz, jstring input) {
    const char* input_str = env->GetStringUTFChars(input, 0);
    
    LOGI("Encrypting string of length: %zu", strlen(input_str));
    
    std::string encrypted = encrypt_string(std::string(input_str));
    
    env->ReleaseStringUTFChars(input, input_str);
    
    // 转换为十六进制显示
    std::string hex_result;
    for (char c : encrypted) {
        char hex_char[3];
        sprintf(hex_char, "%02X", (unsigned char)c);
        hex_result += hex_char;
    }
    
    LOGI("Encryption completed, output length: %zu", hex_result.length());
    return env->NewStringUTF(hex_result.c_str());
}

// 反调试检测JNI接口
extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_ollvm_1demo_MainActivity_detectDebugging(JNIEnv *env, jobject thiz) {
    LOGI("Performing debug detection analysis...");
    
    bool is_debugging = detect_debugging();
    
    LOGI("Debug detection result: %s", is_debugging ? "DETECTED" : "CLEAR");
    return is_debugging ? JNI_TRUE : JNI_FALSE;
}

// 获取系统状态JNI接口
extern "C" JNIEXPORT jstring JNICALL
Java_com_example_ollvm_1demo_MainActivity_getSystemStatus(JNIEnv *env, jobject thiz) {
    LOGI("Generating system status report...");
    
    // 计算系统指纹
    int system_fingerprint = 0;
    for (int i = 0; i < strlen(DEBUG_SIGNATURE); i++) {
        system_fingerprint += DEBUG_SIGNATURE[i] * (i + 1);
    }
    
    for (int i = 0; i < 32; i++) {
        system_fingerprint ^= CRYPTO_TABLE[i] << (i % 16);
    }
    
    std::string status = "📊 System Status Report\n";
    status += "═══════════════════════\n";
    status += "🔢 Call Counter: " + std::to_string(call_counter) + "\n";
    status += "🛡️ Security Level: " + std::to_string(security_level) + "\n";
    status += "⭐ Premium Status: " + std::string(is_premium_user ? "ACTIVE" : "INACTIVE") + "\n";
    status += "🚨 Debug Status: " + std::string(debug_mode_detected ? "DETECTED" : "CLEAN") + "\n";
    status += "🔐 System Fingerprint: " + std::to_string(system_fingerprint) + "\n";
    status += "📝 API Key Hash: " + std::to_string((int)SECRET_API_KEY[0] * strlen(SECRET_API_KEY)) + "\n";
    status += "🧂 Salt Length: " + std::to_string(strlen(ENCRYPTION_SALT)) + "\n";
    status += "📋 Crypto Table Size: 32 bytes\n";
    status += "═══════════════════════\n";
    status += "🛠️ All systems operational";
    
    LOGI("System status generated successfully");
    return env->NewStringUTF(status.c_str());
}

// 性能测试JNI接口
extern "C" JNIEXPORT jlong JNICALL
Java_com_example_ollvm_1demo_MainActivity_performanceTest(JNIEnv *env, jobject thiz, jint iterations) {
    LOGI("Starting performance test with %d iterations", iterations);
    
    clock_t start_time = clock();
    
    int total_result = 0;
    for (int i = 0; i < iterations; i++) {
        // 执行各种复杂计算
        int mode = i % 4;
        int calc_result = advanced_calculate(i, mode);
        total_result += calc_result % 10000;
        
        // 每隔一定次数执行许可证验证
        if (i % 100 == 0 && i > 0) {
            validate_license_internal(LICENSE_CODE);
        }
        
        // 每隔一定次数执行字符串加密
        if (i % 50 == 0) {
            std::string test_str = "Performance test " + std::to_string(i);
            encrypt_string(test_str);
        }
    }
    
    clock_t end_time = clock();
    long duration_ms = ((long)(end_time - start_time)) * 1000 / CLOCKS_PER_SEC;
    
    LOGI("Performance test completed in %ld ms, result: %d", duration_ms, total_result);
    return duration_ms;
}