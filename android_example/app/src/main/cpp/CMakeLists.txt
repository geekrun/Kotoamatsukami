# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html.
# For more examples on how to use CMake, see https://github.com/android/ndk-samples.

# Sets the minimum CMake version required for this project.
cmake_minimum_required(VERSION 3.22.1)

# Declares the project name. The project name can be accessed via ${ PROJECT_NAME},
# Since this is the top level CMakeLists.txt, the project name is also accessible
# with ${CMAKE_PROJECT_NAME} (both CMake variables are in-sync within the top level
# build script scope).
project("ollvm_demo")

# 混淆配置 - 支持灵活的路径设置
option(ENABLE_OBFUSCATION "Enable code obfuscation" OFF)
set(KOTOAMATSUKAMI_PATH "" CACHE STRING "Path to Kotoamatsukami plugin directory")

# 源文件列表
set(DEMO_SOURCES
    native-lib.cpp
)

# 可选的安全模块（如果存在）
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/security.cpp")
    list(APPEND DEMO_SOURCES security.cpp)
    message(STATUS "Added security module")
endif()

# 两阶段编译设置
if(ENABLE_OBFUSCATION)
    # 只在ARM64架构下启用混淆
    if(NOT ANDROID_ABI STREQUAL "arm64-v8a")
        message(WARNING "Kotoamatsukami obfuscation only supports arm64-v8a, current ABI: ${ANDROID_ABI}")
        set(ENABLE_OBFUSCATION OFF)
    else()
        message(STATUS "🔧 Two-stage compilation enabled for obfuscation")
        
        # 查找插件路径
        if(KOTOAMATSUKAMI_PATH)
            set(PLUGIN_SEARCH_DIRS ${KOTOAMATSUKAMI_PATH})
        else()
            set(PLUGIN_SEARCH_DIRS 
                "${CMAKE_CURRENT_SOURCE_DIR}/obfuscation"
                # WSL Linux路径 - 优先使用Linux本地插件
                "${CMAKE_CURRENT_SOURCE_DIR}/../../../bin"
                "/mnt/d/code_project/geekrun/external_fork/Kotoamatsukami/bin"
                "${CMAKE_SOURCE_DIR}/bin"
            )
        endif()
        
        # 搜索插件文件
        set(KOTOAMATSUKAMI_PLUGIN "")
        set(OBFUSCATION_CONFIG "")
        
        foreach(SEARCH_DIR ${PLUGIN_SEARCH_DIRS})
            if(EXISTS "${SEARCH_DIR}/Kotoamatsukami.so")
                set(KOTOAMATSUKAMI_PLUGIN "${SEARCH_DIR}/Kotoamatsukami.so")
                message(STATUS "Found Kotoamatsukami plugin: ${KOTOAMATSUKAMI_PLUGIN}")
                break()
            endif()
        endforeach()
        
        # 搜索配置文件
        foreach(SEARCH_DIR ${PLUGIN_SEARCH_DIRS} "${CMAKE_CURRENT_SOURCE_DIR}/../../../compiler" "/mnt/d/code_project/geekrun/external_fork/Kotoamatsukami/compiler")
            if(EXISTS "${SEARCH_DIR}/Kotoamatsukami.config")
                set(OBFUSCATION_CONFIG "${SEARCH_DIR}/Kotoamatsukami.config")
                message(STATUS "Found Kotoamatsukami config: ${OBFUSCATION_CONFIG}")
                break()
            endif()
        endforeach()
        
        # 验证文件是否找到
        if(NOT KOTOAMATSUKAMI_PLUGIN OR NOT EXISTS "${KOTOAMATSUKAMI_PLUGIN}")
            message(WARNING "Kotoamatsukami plugin not found, disabling obfuscation")
            set(ENABLE_OBFUSCATION OFF)
        elseif(NOT OBFUSCATION_CONFIG OR NOT EXISTS "${OBFUSCATION_CONFIG}")
            message(WARNING "Kotoamatsukami config not found, disabling obfuscation")
            set(ENABLE_OBFUSCATION OFF)
        else()
            message(STATUS "✅ Two-stage obfuscation enabled for ARM64")
            message(STATUS "   Plugin: ${KOTOAMATSUKAMI_PLUGIN}")
            message(STATUS "   Config: ${OBFUSCATION_CONFIG}")
            
            # 复制配置文件到构建目录
            configure_file("${OBFUSCATION_CONFIG}" "${CMAKE_BINARY_DIR}/Kotoamatsukami.config" COPYONLY)
            
            # 第一阶段：使用系统LLVM生成混淆后的IR文件，然后编译为.o文件
            set(OBFUSCATED_OBJ_FILES "")
            foreach(SOURCE_FILE ${DEMO_SOURCES})
                get_filename_component(SOURCE_NAME ${SOURCE_FILE} NAME_WE)
                set(IR_FILE "${CMAKE_BINARY_DIR}/${SOURCE_NAME}_obfuscated.ll")
                set(OBJ_FILE "${CMAKE_BINARY_DIR}/${SOURCE_NAME}_obfuscated.o")
                list(APPEND OBFUSCATED_OBJ_FILES ${OBJ_FILE})
                
                # 第一阶段：系统LLVM + 插件 -> 混淆IR文件
                add_custom_command(
                    OUTPUT ${IR_FILE}
                    COMMAND clang-17 
                        -S -emit-llvm 
                        -fpass-plugin=${KOTOAMATSUKAMI_PLUGIN}
                        -std=c++17
                        -stdlib=libc++
                        -I/root/Android/Sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include
                        -I/root/Android/Sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/aarch64-linux-android
                        -I/root/Android/Sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1
                        -DANDROID
                        -fPIC
                        -target aarch64-linux-android24
                        -o ${IR_FILE}
                        ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_FILE}
                    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_FILE} ${KOTOAMATSUKAMI_PLUGIN}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                    COMMENT "🔒 Stage 1: Obfuscating ${SOURCE_FILE} with system LLVM..."
                )
                
                # 第二阶段：Android NDK -> IR文件编译为目标文件
                add_custom_command(
                    OUTPUT ${OBJ_FILE}
                    COMMAND ${CMAKE_CXX_COMPILER}
                        --target=aarch64-none-linux-android24
                        --sysroot=/root/Android/Sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/linux-x86_64/sysroot
                        -DANDROID -fdata-sections -ffunction-sections -funwind-tables 
                        -fstack-protector-strong -no-canonical-prefixes 
                        -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security
                        -std=c++17 -fno-limit-debug-info -fPIC
                        -c ${IR_FILE} -o ${OBJ_FILE}
                    DEPENDS ${IR_FILE}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                    COMMENT "🎯 Stage 2: Compiling obfuscated IR ${SOURCE_NAME} with Android NDK..."
                )
            endforeach()
            
            # 创建一个自定义目标来生成所有混淆目标文件
            add_custom_target(generate_obfuscated_objects 
                DEPENDS ${OBFUSCATED_OBJ_FILES}
                COMMENT "🔒 Generating all obfuscated object files..."
            )
            
            # 创建库：从预编译的目标文件
            add_library(${CMAKE_PROJECT_NAME} SHARED)
            
            # 设置库的语言为C++
            set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES LINKER_LANGUAGE CXX)
            
            # 手动设置目标文件作为库的源
            target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${OBFUSCATED_OBJ_FILES})
            
            # 确保目标文件在库编译之前生成
            add_dependencies(${CMAKE_PROJECT_NAME} generate_obfuscated_objects)
            
            message(STATUS "🎯 Two-stage compilation configured:")
            message(STATUS "   Stage 1: System clang-17 + plugin -> IR files")
            message(STATUS "   Stage 2: Android NDK clang++ -> final .so")
        endif()
    endif()
endif()

# 如果没有启用混淆，使用常规编译
if(NOT ENABLE_OBFUSCATION)
    message(STATUS "📝 Using standard compilation (no obfuscation)")
    add_library(${CMAKE_PROJECT_NAME} SHARED ${DEMO_SOURCES})
endif()

# Specifies libraries CMake should link to your target library. You
# can link libraries from various origins, such as libraries defined in this
# build script, prebuilt third-party libraries, or Android system libraries.
target_link_libraries(${CMAKE_PROJECT_NAME}
        # List libraries link to the target library
        android
        log)