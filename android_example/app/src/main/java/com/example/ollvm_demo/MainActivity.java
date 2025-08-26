package com.example.ollvm_demo;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.*;

public class MainActivity extends AppCompatActivity {
    
    private static final String TAG = "KotoamatsukamiDemo";
    static { System.loadLibrary("ollvm_demo"); }

    private TextView statusText, resultText;
    private EditText inputText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        createLayout();
        refreshStatus();
    }

    private void createLayout() {
        ScrollView scrollView = new ScrollView(this);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(32, 32, 32, 32);

        // 标题
        TextView title = new TextView(this);
        title.setText("🛡️ Kotoamatsukami OLLVM Enhanced Demo");
        title.setTextSize(18);
        title.setPadding(0, 0, 0, 24);
        layout.addView(title);

        // 状态显示
        statusText = new TextView(this);
        statusText.setBackgroundColor(0xFFF5F5F5);
        statusText.setPadding(16, 16, 16, 16);
        statusText.setTextIsSelectable(true);
        layout.addView(statusText);

        // 输入框
        inputText = new EditText(this);
        inputText.setHint("输入测试内容...");
        inputText.setText("KOTOAMATSUKAMI-PREMIUM-LICENSE");
        layout.addView(inputText);

        // 按钮
        addButton(layout, "🔄 刷新状态", this::refreshStatus);
        addButton(layout, "🔐 验证许可证", this::testLicense);
        addButton(layout, "🧮 高级计算", this::testCalculation);
        addButton(layout, "🔒 字符串加密", this::testEncryption);
        addButton(layout, "🔍 调试检测", this::testDebug);
        addButton(layout, "📊 系统状态", this::testSystemStatus);
        addButton(layout, "⚡ 性能测试", this::testPerformance);

        // 结果显示
        resultText = new TextView(this);
        resultText.setBackgroundColor(0xFFF0F0F0);
        resultText.setPadding(16, 16, 16, 16);
        resultText.setTextIsSelectable(true);
        layout.addView(resultText);

        scrollView.addView(layout);
        setContentView(scrollView);
    }

    private void addButton(LinearLayout parent, String text, Runnable action) {
        Button button = new Button(this);
        button.setText(text);
        button.setOnClickListener(v -> action.run());
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 
            LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, 8, 0, 8);
        button.setLayoutParams(params);
        parent.addView(button);
    }

    private void refreshStatus() {
        try {
            String status = stringFromJNI();
            statusText.setText(status);
            resultText.setText("✅ 状态刷新完成");
            Log.d(TAG, "Status refreshed");
        } catch (Exception e) {
            showError("刷新失败", e);
        }
    }

    private void testLicense() {
        try {
            String license = inputText.getText().toString().trim();
            if (license.isEmpty()) license = "KOTOAMATSUKAMI-PREMIUM-LICENSE";
            
            long start = System.currentTimeMillis();
            boolean valid = validateLicense(license);
            long duration = System.currentTimeMillis() - start;
            
            resultText.setText(String.format(
                "🔐 许可证验证:\n结果: %s\n用时: %d ms",
                valid ? "✅ 有效" : "❌ 无效", duration));
            Toast.makeText(this, valid ? "验证成功!" : "验证失败!", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            showError("许可证验证失败", e);
        }
    }

    private void testCalculation() {
        try {
            String input = inputText.getText().toString().replaceAll("[^0-9]", "");
            int value = input.isEmpty() ? 100 : Integer.parseInt(input);
            
            StringBuilder result = new StringBuilder("🧮 高级计算结果:\n");
            for (int mode = 1; mode <= 4; mode++) {
                long start = System.currentTimeMillis();
                int calcResult = advancedCalculate(value, mode);
                long duration = System.currentTimeMillis() - start;
                result.append(String.format("模式%d: %d (%dms)\n", mode, calcResult, duration));
            }
            resultText.setText(result.toString());
            Toast.makeText(this, "计算完成!", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            showError("计算失败", e);
        }
    }

    private void testEncryption() {
        try {
            String input = inputText.getText().toString().trim();
            if (input.isEmpty()) input = "Hello Kotoamatsukami!";
            
            long start = System.currentTimeMillis();
            String encrypted = encryptString(input);
            long duration = System.currentTimeMillis() - start;
            
            resultText.setText(String.format(
                "🔒 字符串加密:\n原文: %s\n密文: %s\n用时: %d ms",
                input.length() > 20 ? input.substring(0, 20) + "..." : input,
                encrypted.length() > 40 ? encrypted.substring(0, 40) + "..." : encrypted,
                duration));
            Toast.makeText(this, "加密完成!", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            showError("加密失败", e);
        }
    }

    private void testDebug() {
        try {
            long start = System.currentTimeMillis();
            boolean debugging = detectDebugging();
            long duration = System.currentTimeMillis() - start;
            
            resultText.setText(String.format(
                "🔍 调试检测:\n结果: %s\n用时: %d ms",
                debugging ? "⚠️ 检测到调试器" : "✅ 环境安全", duration));
            Toast.makeText(this, debugging ? "检测到调试!" : "环境安全", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            showError("调试检测失败", e);
        }
    }

    private void testSystemStatus() {
        try {
            String status = getSystemStatus();
            resultText.setText(status);
            Toast.makeText(this, "状态获取完成!", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            showError("获取状态失败", e);
        }
    }

    private void testPerformance() {
        new Thread(() -> {
            try {
                runOnUiThread(() -> {
                    resultText.setText("⚡ 性能测试中...");
                    Toast.makeText(this, "测试开始!", Toast.LENGTH_SHORT).show();
                });
                
                long duration = performanceTest(1000);
                
                runOnUiThread(() -> {
                    resultText.setText(String.format(
                        "⚡ 性能测试结果:\n测试次数: 1000\n耗时: %d ms\n平均: %.2f ms/次\n性能: %s",
                        duration, (double)duration/1000, getPerformanceGrade(duration)));
                    Toast.makeText(this, "测试完成!", Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> showError("性能测试失败", e));
            }
        }).start();
    }

    private String getPerformanceGrade(long duration) {
        if (duration < 100) return "极快 🚀";
        else if (duration < 500) return "很快 ⚡";  
        else if (duration < 1000) return "快速 🏃";
        else if (duration < 2000) return "正常 🚶";
        else return "较慢 🐌";
    }

    private void showError(String operation, Exception e) {
        String msg = String.format("❌ %s\n错误: %s", operation, 
            e.getMessage() != null ? e.getMessage() : "未知错误");
        resultText.setText(msg);
        Toast.makeText(this, operation, Toast.LENGTH_SHORT).show();
        Log.e(TAG, operation, e);
    }

    // Native方法声明
    public native String stringFromJNI();
    public native boolean validateLicense(String license);
    public native int advancedCalculate(int input, int mode);
    public native String encryptString(String input);
    public native boolean detectDebugging();
    public native String getSystemStatus();
    public native long performanceTest(int iterations);
}