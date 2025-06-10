#!/bin/bash

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 默认参数
TARGET="x86_64-linux-gnu"
ACTION=""
FIRST_ARG_SET=""
OPTIMIZE_SIZE=false
ENABLE_DEMOS=false
ENABLE_LIBDRM=false
RKRGA_VERSION="1.10.4"

# 解析命令行参数
for arg in "$@"; do
  case $arg in
    --target=*)
      TARGET="${arg#*=}"
      shift
      ;;
    --version=*)
      RKRGA_VERSION="${arg#*=}"
      shift
      ;;
    --optimize-size)
      OPTIMIZE_SIZE=true
      shift
      ;;
    --enable-demos)
      ENABLE_DEMOS=true
      shift
      ;;
    --enable-libdrm)
      ENABLE_LIBDRM=true
      shift
      ;;
    clean)
      ACTION="clean"
      shift
      ;;
    clean-dist)
      ACTION="clean-dist"
      shift
      ;;
    --help)
      echo "用法: $0 [选项] [动作]"
      echo "选项:"
      echo "  --target=<目标>       指定目标架构 (默认: x86_64-linux-gnu)"
      echo "  --version=<版本>      指定rkrga版本 (默认: 1.10.4)"
      echo "  --optimize-size       启用库文件大小优化 (保持性能)"
      echo "  --enable-demos        启用示例程序编译"
      echo "  --enable-libdrm       启用libdrm支持"
      echo "  --help                显示此帮助信息"
      echo ""
      echo "动作:"
      echo "  clean              清除build目录和缓存"
      echo "  clean-dist         清除build目录和install目录"
      echo ""
      echo "支持的目标架构示例:"
      echo "  x86_64-linux-gnu      - x86_64 Linux (GNU libc)"
      echo "  arm-linux-gnueabihf     - ARM64 32-bit Linux (GNU libc)"
      echo "  aarch64-linux-gnu     - ARM64 Linux (GNU libc)"
      echo "  arm-linux-android         - ARM 32-bit Android"   
      echo "  aarch64-linux-android     - ARM64 Android"
      echo "  x86-linux-android         - x86 32-bit Android"      
      echo "  x86_64-linux-android     - x86_64 Android"
      echo "  x86_64-windows-gnu    - x86_64 Windows (MinGW)"
      echo "  aarch64-windows-gnu    - aarch64 Windows (MinGW)"
      echo "  x86_64-macos          - x86_64 macOS"
      echo "  aarch64-macos         - ARM64 macOS"
      echo "  riscv64-linux-gnu      - RISC-V 64-bit Linux"      
      echo "  loongarch64-linux-gnu   - LoongArch64 Linux"
      echo "  aarch64-linux-harmonyos     - ARM64 HarmonyOS"
      echo "  arm-linux-harmonyos         - ARM 32-bit HarmonyOS"  
      echo "  x86_64-linux-harmonyos     - x86_64 harmonyos"
      exit 0
      ;;
    *)
      # 处理位置参数 (第一个参数作为target)
      if [ -z "$FIRST_ARG_SET" ]; then
        TARGET="$arg"
        FIRST_ARG_SET=1
      fi
      ;;
  esac
done

# 参数配置
PROJECT_ROOT_DIR="$(pwd)"
RKRGA_SOURCE_DIR="${PROJECT_ROOT_DIR}/rkrga-${RKRGA_VERSION}"
BUILD_TYPE="release"
INSTALL_DIR="$PROJECT_ROOT_DIR/rkrga_install/Release/${TARGET}"
BUILD_DIR="$PROJECT_ROOT_DIR/rkrga_build/${TARGET}"

# 函数：下载并解压 rkrga 源码
download_rkrga() {
    local version="$1"
    local source_dir="$2"
    local download_url="https://github.com/nyanmisaka/rk-mirrors.git"
    
    echo -e "${YELLOW}检查 rkrga-${version} 源码目录...${NC}"
    
    # 检查源码目录是否存在
    if [ -d "$source_dir" ]; then
        echo -e "${GREEN}源码目录已存在: $source_dir${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}源码目录不存在，开始下载 rkrga-${version}...${NC}"
    
    # 检查必要的工具
    if ! command -v git &> /dev/null; then
        echo -e "${RED}错误: 需要 git 来下载文件${NC}"
        exit 1
    fi
    
    # 创建临时下载目录
    
    echo -e "${BLUE}下载地址: $download_url${NC}"
    echo -e "${BLUE}下载到: $source_dir${NC}"
    
    # 下载文件
    git clone -b jellyfin-rga --depth=1 $download_url $source_dir
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载失败: $download_url${NC}"
        rm -rf "$archive_path"
        exit 1
    fi
    
    
    # 验证解压结果
    if [ -d "$source_dir" ]; then
        echo -e "${GREEN}rkrga-${version} 源码准备完成: $source_dir${NC}"
    else
        echo -e "${RED}解压后未找到预期的源码目录: $source_dir${NC}"
        exit 1
    fi
}

# 下载并准备 rkrga 源码
download_rkrga "$RKRGA_VERSION" "$RKRGA_SOURCE_DIR"

# 函数：下载并解压 libdrm 依赖
download_libdrm() {
    local target="$1"
    local deps_dir="$PROJECT_ROOT_DIR/build_deps/libdrm"
    
    if [ "$ENABLE_LIBDRM" = false ]; then
        echo ""
        return 0
    fi
    
    echo -e "${YELLOW}检查 libdrm 依赖目录...${NC}" >&2
    
    # 检查必要的工具
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo -e "${RED}错误: 需要 curl 或 wget 来下载文件${NC}" >&2
        exit 1
    fi
    
    
    # GitHub releases API URL
    local api_url="https://api.github.com/repos/ChungTak/libdrm/releases/latest"
    local download_url=""
    
    # 获取最新release信息
    echo -e "${BLUE}获取最新 libdrm release 信息...${NC}" >&2
    if command -v curl &> /dev/null; then
        local release_info=$(curl -s "$api_url")
    else
        local release_info=$(wget -qO- "$api_url")
    fi
    
    if [ $? -ne 0 ] || [ -z "$release_info" ]; then
        echo -e "${RED}获取 libdrm release 信息失败${NC}" >&2
        exit 1
    fi
    
    # 查找对应架构的压缩包URL
    if command -v jq &> /dev/null; then
        # 使用jq解析JSON
        download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | contains(\"$target\")) | .browser_download_url" | head -1)
    else
        # 使用grep和sed简单解析（备用方案）
        download_url=$(echo "$release_info" | grep -o "\"browser_download_url\"[^,]*$target[^\"]*" | sed 's/.*"browser_download_url": "//' | sed 's/"//' | head -1)
    fi
    
    if [ -z "$download_url" ]; then
        echo -e "${RED}未找到适合架构 $target 的 libdrm 压缩包${NC}" >&2
        echo -e "${YELLOW}尝试使用通用版本...${NC}" >&2
        # 尝试获取第一个可用的压缩包
        if command -v jq &> /dev/null; then
            download_url=$(echo "$release_info" | jq -r ".assets[0].browser_download_url")
        else
            download_url=$(echo "$release_info" | grep -o "\"browser_download_url\"[^,]*\.tar\.gz[^\"]*" | sed 's/.*"browser_download_url": "//' | sed 's/"//' | head -1)
        fi
    fi
    
    if [ -z "$download_url" ]; then
        echo -e "${RED}无法获取 libdrm 下载链接${NC}" >&2
        exit 1
    fi

    file_zip_name=$(basename "$download_url") #libdrm-2.4.125-aarch64-linux-gnu.tar.gz
    filename="${file_zip_name%.tar.gz}" # 去掉 .tar.gz
    source_dir="$deps_dir/$filename"
    # 如果依赖目录已存在，直接返回
    if [ -d "$source_dir" ]; then
        echo -e "${GREEN}libdrm依赖源代码目录已存在: $source_dir${NC}" >&2
        echo "$source_dir"
        return 0
    fi
    
    echo -e "${YELLOW}libdrm 依赖源代码目录不存在，开始下载...${NC}" >&2
    
    # 创建依赖源代码目录
    mkdir -p "$deps_dir"
    
    echo -e "${BLUE}下载地址: $download_url${NC}" >&2
    echo -e "${BLUE}下载到: $deps_dir/$file_zip_name${NC}" >&2
    
    # 下载文件
    if command -v curl &> /dev/null; then
        curl -L -o "$deps_dir/$file_zip_name" "$download_url"
    else
        wget -O "$deps_dir/$file_zip_name" "$download_url"
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载失败: $download_url${NC}" >&2
        rm -rf "$deps_dir/$file_zip_name"
        exit 1
    fi
    
    # 解压文件
    echo -e "${BLUE}解压 libdrm...${NC}" >&2
    cd "$deps_dir"
    tar -xzf "$file_zip_name"
    if [ $? -ne 0 ]; then
        echo -e "${RED}解压失败: $deps_dir/$file_zip_name${NC}" >&2
        exit 1
    fi
    
    # 清理压缩包
    rm -f "$deps_dir/$file_zip_name"
    
    # 验证解压结果
    if [ -d "$source_dir/include" ] && [ -d "$source_dir/lib" ]; then
        echo -e "${GREEN}libdrm 依赖准备完成: $source_dir${NC}" >&2
    else
        echo -e "${RED}解压后未找到预期的 libdrm 目录结构${NC}" >&2
        exit 1
    fi
    
    cd "$PROJECT_ROOT_DIR"
    # 返回source_dir路径供外部使用
    echo "$source_dir"
}

# 下载并准备 libdrm 依赖
if [ "$ENABLE_LIBDRM" = true ]; then
    LIBDRM_SOURCE_DIR=$(download_libdrm "$TARGET")
else
    LIBDRM_SOURCE_DIR=""
fi


# patch meson 源码 fix_clock_skew_issues
echo "Patching meson to skip clock skew checks..."
python3 patch_meson_clockskew.py
echo "✅ Clock skew 修复完成"

# 设置架构特定的预处理器定义
ARCH_DEFINES=""
case "$TARGET" in
    aarch64-*)
        ARCH_DEFINES="-D__aarch64__ -D__arm64__"
        ;;
    x86_64-*)
        # 为了使用64位代码路径，定义ARM64的宏（代码中使用这些来判断64位）
        ARCH_DEFINES="-D__x86_64__ -D_M_X64 -D__aarch64__"
        ;;
    riscv64-*)
        # 为了使用64位代码路径，定义ARM64的宏
        ARCH_DEFINES="-D__riscv64__ -D__aarch64__"
        ;;
    loongarch64-*)
        # 为了使用64位代码路径，定义ARM64的宏
        ARCH_DEFINES="-D__loongarch64__ -D__aarch64__"
        ;;
esac

# 设置libdrm环境变量
LIBDRM_CFLAGS=""
LIBDRM_LDFLAGS=""
if [ "$ENABLE_LIBDRM" = true ] && [ -n "$LIBDRM_SOURCE_DIR" ]; then
    if [ -d "$LIBDRM_SOURCE_DIR" ]; then
        LIBDRM_CFLAGS="-I$LIBDRM_SOURCE_DIR/include"
        LIBDRM_LDFLAGS="-L$LIBDRM_SOURCE_DIR/lib"
        export PKG_CONFIG_PATH="$LIBDRM_SOURCE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
        echo -e "${BLUE}libdrm 环境变量已设置:${NC}"
        echo -e "${BLUE}  包含路径: $LIBDRM_SOURCE_DIR/include${NC}"
        echo -e "${BLUE}  库路径: $LIBDRM_SOURCE_DIR/lib${NC}"
        echo -e "${BLUE}  PKG_CONFIG_PATH: $LIBDRM_SOURCE_DIR/lib/pkgconfig${NC}"
    fi
fi

# 处理清理动作
if [ "$ACTION" = "clean" ]; then
    echo -e "${YELLOW}清理构建目录和缓存...${NC}"
    rm -rf "$PROJECT_ROOT_DIR/rkrga_build"
    rm -rf "$PROJECT_ROOT_DIR/build_deps"
    echo -e "${GREEN}构建目录和依赖已清理!${NC}"
    exit 0
elif [ "$ACTION" = "clean-dist" ]; then
    echo -e "${YELLOW}清理构建目录和安装目录...${NC}"
    rm -rf "$PROJECT_ROOT_DIR/rkrga_build"
    rm -rf "$PROJECT_ROOT_DIR/rkrga_install"
    rm -rf "$PROJECT_ROOT_DIR/build_deps"
    rm -rf "$PROJECT_ROOT_DIR/build_deps"
    echo -e "${GREEN}构建目录、安装目录和依赖已清理!${NC}"
    exit 0
fi

# 检查Zig是否安装
if ! command -v zig &> /dev/null; then
    echo -e "${RED}错误: 未找到Zig。请安装Zig: https://ziglang.org/download/${NC}"
    exit 1
fi

# 检查Meson是否安装
if ! command -v meson &> /dev/null; then
    echo -e "${RED}错误: 未找到meson。请安装meson: https://mesonbuild.com/Getting-meson.html${NC}"
    exit 1
fi


# 检查meson.build是否存在
if [ ! -f "$RKRGA_SOURCE_DIR/meson.build" ]; then
    echo -e "${RED}错误: RKRGA meson.build文件不存在: $RKRGA_SOURCE_DIR/meson.build${NC}"
    exit 1
fi

# 创建安装目录
mkdir -p "$INSTALL_DIR"

# 创建RKRGA构建目录（每次都清理，避免 Meson 缓存污染）
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 进入构建目录
cd "$BUILD_DIR"

# 使用 Zig 作为编译器
ZIG_PATH=$(command -v zig)

# 函数：根据目标架构获取系统信息
get_target_info() {
    local target="$1"
    
    case "$target" in
        x86_64-linux-gnu|x86_64-linux-android|x86_64-linux-harmonyos)
            echo "linux x86_64 x86_64 little"
            ;;
        aarch64-linux-gnu|aarch64-linux-android|aarch64-linux-harmonyos|aarch64-macos)
            echo "linux aarch64 aarch64 little"
            ;;
        arm-linux-gnueabihf|arm-linux-android|arm-linux-harmonyos)
            echo "linux arm arm little"
            ;;
        x86-linux-android|i686-linux-gnu)
            echo "linux x86 i386 little"
            ;;
        x86_64-windows-gnu)
            echo "windows x86_64 x86_64 little"
            ;;
        aarch64-windows-gnu)
            echo "windows aarch64 aarch64 little"
            ;;
        x86_64-macos)
            echo "darwin x86_64 x86_64 little"
            ;;
        riscv64-linux-gnu)
            echo "linux riscv64 riscv64 little"
            ;;
        loongarch64-linux-gnu)
            echo "linux loongarch64 loongarch64 little"
            ;;
        *)
            echo "linux unknown unknown little"
            ;;
    esac
}

# 设置交叉编译配置
export PKG_CONFIG=""
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR=""
echo -e "${YELLOW}交叉编译模式：已禁用pkg-config以避免主机系统库冲突${NC}"

# 获取目标架构信息
TARGET_INFO=($(get_target_info "$TARGET"))
TARGET_SYSTEM="${TARGET_INFO[0]}"
TARGET_CPU_FAMILY="${TARGET_INFO[1]}"
TARGET_CPU="${TARGET_INFO[2]}"
TARGET_ENDIAN="${TARGET_INFO[3]}"

# 根据优化设置确定编译参数
LDFLAGS_OPTIMIZE=""
# 添加64位兼容性编译参数，解决指针转换问题
COMPAT_FLAGS="-Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -Wno-narrowing"
# 添加缺失的宏定义，解决 __BEGIN_DECLS 和 __END_DECLS 未定义问题
DECLS_FLAGS="-D__BEGIN_DECLS= -D__END_DECLS="
if [ "$OPTIMIZE_SIZE" = true ]; then
    # 大小优化标志
    ZIG_OPTIMIZE_FLAGS="-Os -DNDEBUG -ffunction-sections -fdata-sections -fvisibility=hidden $ARCH_DEFINES $COMPAT_FLAGS $DECLS_FLAGS"
    export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"
    LDFLAGS_OPTIMIZE="-Wl,--gc-sections -Wl,--strip-all"
else
    ZIG_OPTIMIZE_FLAGS="-O2 -DNDEBUG $ARCH_DEFINES $COMPAT_FLAGS $DECLS_FLAGS"
    LDFLAGS_OPTIMIZE=""    
    export LDFLAGS=""
fi


CROSS_FILE=""
# 根据目标平台配置编译器和工具链
if [[ "$TARGET" == *"-linux-android"* ]]; then
    export ANDROID_NDK_ROOT="${ANDROID_NDK_HOME:-~/sdk/android_ndk/android-ndk-r21e}"
    HOST_TAG=linux-x86_64
    TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG
    export PATH=$TOOLCHAIN/bin:$PATH
    API_LEVEL=23

    case "$TARGET" in
        aarch64-linux-android)
            ANDROID_ABI=arm64-v8a
            ANDROID_TARGET=aarch64-linux-android
            ;;
        arm-linux-android)
            ANDROID_ABI=armeabi-v7a
            ANDROID_TARGET=armv7a-linux-androideabi
            ;;
        x86_64-linux-android)
            ANDROID_ABI=x86_64
            ANDROID_TARGET=x86_64-linux-android
            ;;
        x86-linux-android)
            ANDROID_ABI=x86
            ANDROID_TARGET=i686-linux-android
            ;;
        *)
            echo -e "${RED}未知的 Android 架构: $TARGET${NC}"
            exit 1
            ;;
    esac

# 创建动态交叉编译配置文件
CROSS_FILE="$PROJECT_ROOT_DIR/cross-build.txt"
cat > "$CROSS_FILE" << EOF
[binaries]
c = '${TOOLCHAIN}/bin/${ANDROID_TARGET}${API_LEVEL}-clang'
cpp = '${TOOLCHAIN}/bin/${ANDROID_TARGET}${API_LEVEL}-clang++'
ar = '${TOOLCHAIN}/bin/llvm-ar'
strip = '${TOOLCHAIN}/bin/llvm-strip'
pkgconfig = 'pkg-config'

[host_machine]
system = '$TARGET_SYSTEM'
cpu_family = '$TARGET_CPU_FAMILY'
cpu = '$TARGET_CPU'
endian = '$TARGET_ENDIAN'

[built-in options]
c_std = 'c11'
default_library = 'both'
EOF
elif [[ "$TARGET" == *"-linux-harmonyos"* ]]; then
    # 检查 HarmonyOS SDK
    export HARMONYOS_SDK_ROOT="${HARMONYOS_SDK_HOME:-~/sdk/harmonyos/ohos-sdk/linux/native-linux-x64-4.1.9.4-Release/native}"
    if [ ! -d "$HARMONYOS_SDK_ROOT" ]; then
        echo -e "${RED}错误: HarmonyOS SDK 未找到: $HARMONYOS_SDK_ROOT${NC}"
        echo -e "${RED}请设置 HARMONYOS_SDK_HOME 环境变量${NC}"
        exit 1
    fi
    
    # HarmonyOS 工具链路径
    HOST_TAG=linux-x86_64
    TOOLCHAIN=$HARMONYOS_SDK_ROOT/llvm/bin
    export PATH=$TOOLCHAIN:$PATH
    
    case "$TARGET" in
        aarch64-linux-harmonyos)
            OHOS_ARCH=aarch64
            HARMONYOS_TARGET=aarch64-linux-ohos
            NDK_ARCH_DIR=aarch64
            ;;
        arm-linux-harmonyos)
            OHOS_ARCH=armv7
            HARMONYOS_TARGET=arm-linux-ohos
            NDK_ARCH_DIR=arm
            ;;
        x86_64-linux-harmonyos)
            OHOS_ARCH=x86_64
            HARMONYOS_TARGET=x86_64-linux-ohos
            NDK_ARCH_DIR=x86_64
            ;;
        *)
            echo -e "${RED}未知的 HarmonyOS 架构: $TARGET${NC}"
            exit 1
            ;;
    esac
    
    # HarmonyOS SDK 路径 - 使用统一 sysroot
    HARMONYOS_SYSROOT="$HARMONYOS_SDK_ROOT/sysroot"
    HARMONYOS_INCLUDE="$HARMONYOS_SYSROOT/usr/include"
    # 库文件路径
    HARMONYOS_LIB="$HARMONYOS_SYSROOT/usr/lib/$NDK_ARCH_DIR-linux-ohos"
    
    # 检查必要的文件是否存在
    if [ ! -d "$HARMONYOS_INCLUDE" ]; then
        echo -e "${RED}错误: HarmonyOS SDK 包含目录未找到: $HARMONYOS_INCLUDE${NC}"
        exit 1
    fi
    
    if [ ! -d "$HARMONYOS_LIB" ]; then
        echo -e "${RED}错误: HarmonyOS SDK 库目录未找到: $HARMONYOS_LIB${NC}"
        exit 1
    fi
    
    # 检查工具链是否存在
    if [ ! -f "$TOOLCHAIN/clang" ]; then
        echo -e "${RED}错误: HarmonyOS clang 编译器未找到: $TOOLCHAIN/clang${NC}"
        exit 1
    fi
    # 设置 LDFLAGS 来指定额外的库搜索路径
    export LDFLAGS="-L$HARMONYOS_LIB $LDFLAGS_OPTIMIZE"
    
    # 设置 HarmonyOS 兼容性标志，包含缺失的宏定义
    HARMONYOS_COMPAT_FLAGS="-D__BEGIN_DECLS= -D__END_DECLS="
    
    # 创建动态交叉编译配置文件
    CROSS_FILE="$PROJECT_ROOT_DIR/cross-build.txt"
    
    # 处理链接器优化标志 - 将单个字符串拆分为数组元素
    LINK_ARGS_OPTIMIZE=""
    if [ -n "$LDFLAGS_OPTIMIZE" ]; then
        # 将 LDFLAGS_OPTIMIZE 拆分为单独的参数
        IFS=' ' read -ra LDFLAGS_ARRAY <<< "$LDFLAGS_OPTIMIZE"
        for flag in "${LDFLAGS_ARRAY[@]}"; do
            if [ -n "$flag" ]; then
                LINK_ARGS_OPTIMIZE="$LINK_ARGS_OPTIMIZE'$flag', "
            fi
        done
        # 移除最后的逗号和空格
        LINK_ARGS_OPTIMIZE="${LINK_ARGS_OPTIMIZE%, }"
    fi
    
    # 处理 libdrm 链接标志
    LINK_ARGS_LIBDRM=""
    if [ -n "$LIBDRM_LDFLAGS" ]; then
        IFS=' ' read -ra LIBDRM_LDFLAGS_ARRAY <<< "$LIBDRM_LDFLAGS"
        for flag in "${LIBDRM_LDFLAGS_ARRAY[@]}"; do
            if [ -n "$flag" ]; then
                LINK_ARGS_LIBDRM="$LINK_ARGS_LIBDRM'$flag', "
            fi
        done
        # 移除最后的逗号和空格
        LINK_ARGS_LIBDRM="${LINK_ARGS_LIBDRM%, }"
    fi
    
    # 组合所有链接参数
    ALL_LINK_ARGS=""
    if [ -n "$LINK_ARGS_OPTIMIZE" ]; then
        ALL_LINK_ARGS="$LINK_ARGS_OPTIMIZE"
    fi
    if [ -n "$LINK_ARGS_LIBDRM" ]; then
        if [ -n "$ALL_LINK_ARGS" ]; then
            ALL_LINK_ARGS="$ALL_LINK_ARGS, $LINK_ARGS_LIBDRM"
        else
            ALL_LINK_ARGS="$LINK_ARGS_LIBDRM"
        fi
    fi

cat > "$CROSS_FILE" << EOF
[binaries]
c = '${TOOLCHAIN}/$OHOS_ARCH-unknown-linux-ohos-clang'
cpp = '${TOOLCHAIN}/$OHOS_ARCH-unknown-linux-ohos-clang++'
ar = '${TOOLCHAIN}/llvm-ar'
strip = '${TOOLCHAIN}/llvm-strip'
pkg-config = 'pkg-config'

[host_machine]
system = '$TARGET_SYSTEM'
cpu_family = '$TARGET_CPU_FAMILY'
cpu = '$TARGET_CPU'
endian = '$TARGET_ENDIAN'

[built-in options]
c_std = 'c11'
default_library = 'both'
c_args = ['$HARMONYOS_COMPAT_FLAGS', '$ZIG_OPTIMIZE_FLAGS', '$LIBDRM_CFLAGS']
cpp_args = ['$HARMONYOS_COMPAT_FLAGS', '$ZIG_OPTIMIZE_FLAGS', '$LIBDRM_CFLAGS', '-fpermissive']
c_link_args = [$ALL_LINK_ARGS]
cpp_link_args = [$ALL_LINK_ARGS]
EOF

else
# 创建动态交叉编译配置文件
CROSS_FILE="$PROJECT_ROOT_DIR/cross-build.txt"
# 将ZIG_OPTIMIZE_FLAGS和libdrm标志转换为数组格式
COMBINED_FLAGS="$ZIG_OPTIMIZE_FLAGS $LIBDRM_CFLAGS"
IFS=' ' read -ra FLAGS_ARRAY <<< "$COMBINED_FLAGS"
FLAGS_STRING=""
for flag in "${FLAGS_ARRAY[@]}"; do
    if [ -n "$flag" ]; then
        FLAGS_STRING="$FLAGS_STRING'$flag', "
    fi
done
FLAGS_STRING=${FLAGS_STRING%, }  # 移除最后的逗号和空格

# 准备链接标志
COMBINED_LDFLAGS="$LDFLAGS $LIBDRM_LDFLAGS"
IFS=' ' read -ra LDFLAGS_ARRAY <<< "$COMBINED_LDFLAGS"
LDFLAGS_STRING=""
for flag in "${LDFLAGS_ARRAY[@]}"; do
    if [ -n "$flag" ]; then
        LDFLAGS_STRING="$LDFLAGS_STRING'$flag', "
    fi
done
LDFLAGS_STRING=${LDFLAGS_STRING%, }  # 移除最后的逗号和空格

cat > "$CROSS_FILE" << EOF
[binaries]
c = ['zig', 'cc', '-target', '$TARGET']
cpp = ['zig', 'c++', '-target', '$TARGET']
ar = ['zig', 'ar']
strip = ['zig', 'strip']
pkg-config = 'pkg-config'

[host_machine]
system = '$TARGET_SYSTEM'
cpu_family = '$TARGET_CPU_FAMILY'
cpu = '$TARGET_CPU'
endian = '$TARGET_ENDIAN'

[built-in options]
c_std = 'c11'
default_library = 'both'
cpp_args = [$FLAGS_STRING]
c_args = [$FLAGS_STRING]
cpp_link_args = [$LDFLAGS_STRING]
c_link_args = [$LDFLAGS_STRING]
EOF
fi

echo -e "${BLUE}动态生成交叉编译配置文件: $CROSS_FILE${NC}"
echo -e "${BLUE}  系统: $TARGET_SYSTEM${NC}"
echo -e "${BLUE}  CPU族: $TARGET_CPU_FAMILY${NC}"
echo -e "${BLUE}  CPU: $TARGET_CPU${NC}"
echo -e "${BLUE}  字节序: $TARGET_ENDIAN${NC}"

export CC="$ZIG_PATH cc -target $TARGET $ZIG_OPTIMIZE_FLAGS"
export CXX="$ZIG_PATH c++ -target $TARGET $ZIG_OPTIMIZE_FLAGS"

# 对于 HarmonyOS，使用 clang 而不是 zig
if [[ "$TARGET" == *"-linux-harmonyos"* ]]; then
    export CC="$TOOLCHAIN/clang --target=$HARMONYOS_TARGET --sysroot=$HARMONYOS_SYSROOT $HARMONYOS_COMPAT_FLAGS $ZIG_OPTIMIZE_FLAGS"
    export CXX="$TOOLCHAIN/clang++ --target=$HARMONYOS_TARGET --sysroot=$HARMONYOS_SYSROOT $HARMONYOS_COMPAT_FLAGS $ZIG_OPTIMIZE_FLAGS"
fi

echo -e "${BLUE}Zig 编译器配置:${NC}"
echo -e "${BLUE}  原始目标: $TARGET${NC}"
echo -e "${BLUE}  Zig 目标: $TARGET${NC}"
echo -e "${BLUE}  Meson 系统名: $MESON_SYSTEM_NAME${NC}"
echo -e "${BLUE}  Meson 处理器: $MESON_SYSTEM_PROCESSOR${NC}"
echo -e "${BLUE}  大小优化: $OPTIMIZE_SIZE${NC}"
echo -e "${BLUE}  启用示例: $ENABLE_DEMOS${NC}"
echo -e "${BLUE}  CC: $CC${NC}"
echo -e "${BLUE}  CXX: $CXX${NC}"



MESON_CMD="meson setup $BUILD_DIR $RKRGA_SOURCE_DIR -Dprefix=$INSTALL_DIR -Dbuildtype=$BUILD_TYPE -Dlibdir=lib"
if [ -n "$CROSS_FILE" ]; then
    MESON_CMD="$MESON_CMD --cross-file=$CROSS_FILE"
fi
# Always add meson options
LIBDRM_OPTION="false"
if [ "$ENABLE_LIBDRM" = true ]; then
    LIBDRM_OPTION="true"
fi

# 为HarmonyOS构建设置特殊的编译参数
if [[ "$TARGET" == *"-linux-harmonyos"* ]]; then
    MESON_CMD="$MESON_CMD --default-library=shared -Dcpp_args='-fpermissive -w -ferror-limit=0 -Wno-everything $ARCH_DEFINES $HARMONYOS_COMPAT_FLAGS $LIBDRM_CFLAGS' -Dc_args='-w -ferror-limit=0 -Wno-everything $ARCH_DEFINES $HARMONYOS_COMPAT_FLAGS $LIBDRM_CFLAGS' -Dlibdrm=$LIBDRM_OPTION -Dlibrga_demo=false"
else
    MESON_CMD="$MESON_CMD --default-library=shared -Dcpp_args='-fpermissive -w -ferror-limit=0 -Wno-everything $ARCH_DEFINES $LIBDRM_CFLAGS' -Dc_args='-w -ferror-limit=0 -Wno-everything $ARCH_DEFINES $LIBDRM_CFLAGS' -Dlibdrm=$LIBDRM_OPTION -Dlibrga_demo=false"
fi


# 打印配置信息
echo -e "${BLUE}RKRGA 构建配置:${NC}"
echo -e "${BLUE}  目标架构: $TARGET${NC}"
echo -e "${BLUE}  源码目录: $RKRGA_SOURCE_DIR${NC}"
echo -e "${BLUE}  构建目录: $BUILD_DIR${NC}"
echo -e "${BLUE}  构建类型: $BUILD_TYPE${NC}"
echo -e "${BLUE}  安装目录: $INSTALL_DIR${NC}"
echo -e "${BLUE}  大小优化: $OPTIMIZE_SIZE${NC}"
echo -e "${BLUE}  启用示例: $ENABLE_DEMOS${NC}"
echo -e "${BLUE}  启用libdrm: $ENABLE_LIBDRM${NC}"
echo -e "${BLUE}  Meson 选项: $meson_options${NC}"

# 执行Meson配置
echo -e "${GREEN}执行配置: $MESON_CMD${NC}"
eval "$MESON_CMD"

if [ $? -ne 0 ]; then
    echo -e "${RED}Meson配置失败!${NC}"
    exit 1
fi

# 编译
echo -e "${GREEN}开始编译RKRGA...${NC}"
ninja -C $BUILD_DIR

# 安装
echo -e "${GREEN}开始安装...${NC}"
ninja -C $BUILD_DIR install

# 检查安装结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}安装成功!${NC}"
    # 如果启用了libdrm，复制libdrm动态库到安装目录
    if [ "$ENABLE_LIBDRM" = true ] && [ -n "$LIBDRM_SOURCE_DIR" ] && [ -d "$LIBDRM_SOURCE_DIR" ]; then
        echo -e "${YELLOW}复制 libdrm 库到安装目录...${NC}"
        if [ -d "$LIBDRM_SOURCE_DIR/lib" ]; then
            cp -r "$LIBDRM_SOURCE_DIR/lib/"* "$INSTALL_DIR/lib/" 2>/dev/null || true
        fi
        if [ -d "$LIBDRM_SOURCE_DIR/include" ]; then
            cp -r "$LIBDRM_SOURCE_DIR/include/"* "$INSTALL_DIR/include/" 2>/dev/null || true
        fi
        echo -e "${GREEN}libdrm 库已复制到: $INSTALL_DIR/lib/${NC}"
    fi

    # 如果启用了大小优化，进行额外的压缩处理
    if [ "$OPTIMIZE_SIZE" = true ]; then
        echo -e "${YELLOW}执行额外的库文件压缩...${NC}"
        
        # 检查strip工具是否可用
        STRIP_TOOL="strip"
        if command -v "${TARGET%-*}-strip" &> /dev/null; then
            STRIP_TOOL="${TARGET%-*}-strip"
        elif command -v "llvm-strip" &> /dev/null; then
            STRIP_TOOL="llvm-strip"
        fi
        
        # 压缩所有共享库
        if [ -d "$INSTALL_DIR/lib" ]; then
            find "$INSTALL_DIR/lib" -name "*.so*" -type f -exec $STRIP_TOOL --strip-unneeded {} \; 2>/dev/null || true
            find "$INSTALL_DIR/lib" -name "*.a" -type f -exec $STRIP_TOOL --strip-debug {} \; 2>/dev/null || true
            echo -e "${GREEN}库文件压缩完成!${NC}"
        fi
        
    fi
    
    echo -e "${GREEN}RKRGA库文件位于: $INSTALL_DIR/lib/${NC}"
    echo -e "${GREEN}RKRGA头文件位于: $INSTALL_DIR/include/${NC}"
    
    # 显示安装的文件和大小
    if [ -d "$INSTALL_DIR/lib" ]; then
        echo -e "${BLUE}安装的库文件:${NC}"
        find "$INSTALL_DIR/lib" -name "*.so*" -o -name "*.a" | head -10 | while read file; do
            size=$(du -h "$file" 2>/dev/null | cut -f1)
            echo "  $file ($size)"
        done
    fi
    
    if [ -d "$INSTALL_DIR/include" ]; then
        echo -e "${BLUE}安装的头文件目录:${NC}"
        find "$INSTALL_DIR/include" -type d | head -5
    fi
    
    # 如果启用了示例，显示示例程序位置
    if [ "$ENABLE_DEMOS" = true ] && [ -d "$INSTALL_DIR/bin" ]; then
        echo -e "${BLUE}安装的示例程序:${NC}"
        find "$INSTALL_DIR/bin" -type f | head -10 | while read file; do
            size=$(du -h "$file" 2>/dev/null | cut -f1)
            echo "  $file ($size)"
        done
    fi
    
    # 返回到项目根目录
    cd "$PROJECT_ROOT_DIR"
else
    echo -e "${RED}安装RKRGA失败!${NC}"
    exit 1
fi
