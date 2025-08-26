cmake_minimum_required(VERSION 3.10)
project(Kotoamatsukami)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
# Find LLVM package - support environment variable or default paths
if(NOT DEFINED LLVM_DIR)
    if(DEFINED ENV{LLVM_DIR})
        set(LLVM_DIR $ENV{LLVM_DIR})
        message(STATUS "Using LLVM_DIR from environment: ${LLVM_DIR}")
    else()
        # Try common LLVM installation paths
        set(LLVM_SEARCH_PATHS
                "/usr/lib/llvm-17/lib/cmake/llvm"
                "/usr/local/lib/cmake/llvm"
                "/usr/local/llvm-17/lib/cmake/llvm"
                "/opt/llvm-17/lib/cmake/llvm"
        )

        foreach(SEARCH_PATH ${LLVM_SEARCH_PATHS})
            if(EXISTS "${SEARCH_PATH}/LLVMConfig.cmake")
                set(LLVM_DIR ${SEARCH_PATH})
                message(STATUS "Found LLVM at: ${LLVM_DIR}")
                break()
            endif()
        endforeach()

        if(NOT DEFINED LLVM_DIR)
            message(WARNING "Could not find LLVM. Please set LLVM_DIR environment variable or install LLVM-17")
        endif()
    endif()
endif()

find_package(LLVM REQUIRED CONFIG)
# Print LLVM information
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# 引入json处理库
# 添加 nlohmann/json 作为子模块
include(FetchContent)

FetchContent_Declare(
        json
        GIT_REPOSITORY https://github.com/nlohmann/json.git
        GIT_TAG v3.11.3
        GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(json)


# Include LLVM directories
message(${LLVM_INCLUDE_DIRS})
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/include)

# nlohmann/json库配置 - 支持本地和远程下载两种方式
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lib/json/single_include/nlohmann/json.hpp")
    # 本地json库存在，使用本地版本
    include_directories("${CMAKE_CURRENT_SOURCE_DIR}/lib/json/single_include/nlohmann")
    message(STATUS "Using local nlohmann/json from: ${CMAKE_CURRENT_SOURCE_DIR}/lib/json/single_include/nlohmann")
    set(JSON_LOCAL_AVAILABLE TRUE)
else()
    # 本地json库不存在，依赖FetchContent下载
    message(STATUS "Local json library not found, will use FetchContent to download")
    set(JSON_LOCAL_AVAILABLE FALSE)
endif()

# 检测是否是交叉编译
if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross-compiling detected for ${CMAKE_SYSTEM_PROCESSOR}")
    message(STATUS "Using selective LLVM library linking for cross-compilation")
    # ARM64交叉编译时仍然需要链接LLVM库目录，但会选择性链接库
    link_directories(${LLVM_LIBRARY_DIRS})
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--allow-shlib-undefined")
else()
    link_directories(${LLVM_LIBRARY_DIRS})
endif()

message(STATUS "WORKING_DIRECTORY: ${WORKING_DIRECTORY}")
add_definitions("${LLVM_DEFINITIONS}")

# 源文件列表
set(KOTOAMATSUKAMI_SOURCES
        src/PassPlugin.cpp
        src/pass/AddJunkCodePass.cpp
        src/pass/Branch2Call.cpp
        src/pass/Branch2Call_32.cpp
        src/pass/ForObsPass.cpp
        src/pass/Loopen.cpp
        src/pass/AntiDebugPass.cpp
        src/pass/SplitBasicBlock.cpp
        src/pass/IndirectBranch.cpp
        src/pass/IndirectCall.cpp
        src/pass/BogusControlFlow.cpp
        src/pass/Substitution.cpp
        src/pass/Flatten.cpp
        src/pass/GVEncrypt.cpp
        src/utils/utils.cpp
        src/utils/config.cpp
        src/utils/TaintAnalysis.cpp
)

if(CMAKE_CROSSCOMPILING)
    # ARM64交叉编译：创建插件，手动控制链接过程避免依赖冲突
    message(STATUS "ARM64 cross-compilation: Creating plugin with manual library linking")

    # 不使用HandleLLVMOptions避免额外依赖检查
    add_library(Kotoamatsukami SHARED ${KOTOAMATSUKAMI_SOURCES})

    # 设置为LLVM插件的标准属性
    set_target_properties(Kotoamatsukami PROPERTIES
            CXX_STANDARD 17
            CXX_STANDARD_REQUIRED ON
            POSITION_INDEPENDENT_CODE ON
            # 关键：允许未定义符号，运行时由opt工具解析
            LINK_FLAGS "-Wl,--unresolved-symbols=ignore-all -Wl,--allow-shlib-undefined"
    )

    # 添加LLVM编译定义和包含路径
    target_compile_definitions(Kotoamatsukami PRIVATE ${LLVM_DEFINITIONS})
    target_include_directories(Kotoamatsukami PRIVATE ${LLVM_INCLUDE_DIRS})
    
    # 根据json库类型决定是否链接target (ARM64交叉编译)
    if(NOT JSON_LOCAL_AVAILABLE)
        target_link_libraries(Kotoamatsukami PRIVATE nlohmann_json::nlohmann_json)
    endif()

    # ARM64交叉编译时不链接LLVM库，运行时由opt工具提供符号解析

else()
    # x86_64本机编译：使用标准LLVM插件方法
    include(AddLLVM)
    include(HandleLLVMOptions)

    add_llvm_pass_plugin(Kotoamatsukami ${KOTOAMATSUKAMI_SOURCES})
    
    # 根据json库类型决定是否链接target (x86_64本地编译)
    if(NOT JSON_LOCAL_AVAILABLE)
        target_link_libraries(Kotoamatsukami PRIVATE nlohmann_json::nlohmann_json)
    endif()
endif()


# # # Define the executable
# add_executable(jit_asm
#               src/utils/jitter.cpp
#               src/utils/json_utils.cpp
#               src/utils/o-mvll_utils.cpp)

# Link against LLVM libraries
# 链接LLVM库
# llvm_map_components_to_libnames(llvm_libs
#   ExecutionEngine
#   MCJIT
#   OrcJIT
#   Core
#   Support
#   nativecodegen
#   X86AsmParser
#   X86CodeGen
#   X86Desc
#   X86Disassembler
#   X86Info
#   native
#   irreader
# )

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic")
# Use LLVM's target link libraries
# target_link_libraries(Kotoamatsukami ${llvm_libs} ${LLVM_LIBRARIES})
# # 添加 ASan 编译器和链接器标志
# set(SANITIZER_FLAGS "-fsanitize=address -fno-omit-frame-pointer -g")

# # 应用到所有目标
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SANITIZER_FLAGS}")
# set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${SANITIZER_FLAGS}")


# # 为 Kotoamatsukami 插件单独设置 ASan
# target_compile_options(Kotoamatsukami PRIVATE -fsanitize=address -fno-omit-frame-pointer)
# target_link_options(Kotoamatsukami PRIVATE -fsanitize=address)

# nlohmann/json is header-only, no need to link - just include directories
# which are already added above in include_directories()