# Rockchip RGA 跨平台构建工具

[English](./README_EN.md) | 中文

这是一个使用 Zig 编译器构建 Rockchip RGA (Raster Graphic Acceleration) 库的跨平台工具。它支持多种目标平台的交叉编译，包括但不限于 Linux、Android、Windows、macOS 和 HarmonyOS。

## ⚠️ 重要说明

**Rockchip 官方仅发布 Android 和 ARM Linux 版本的 RGA 库。本项目中支持的其他平台版本（如 x86、Windows、macOS 等）仅用于测试和开发目的，不保证在生产环境中的稳定性。请根据您的实际需求谨慎使用。**

## 🚀 特性

- 🎯 **多平台支持**: 支持 10+ 种目标平台架构
- ⚡ **快速构建**: 使用 Zig 编译器实现快速交叉编译
- 📦 **自动依赖管理**: 自动下载和配置必要的依赖
- 🔧 **灵活配置**: 支持多种构建选项和优化
- 🌐 **现代工具链**: 基于 Meson 构建系统和 Zig 编译器

## 📋 支持的目标平台

### Linux 平台
- `x86_64-linux-gnu` - x86_64 Linux (GNU libc)
- `aarch64-linux-gnu` - ARM64 Linux (GNU libc) ✅ **官方支持**
- `arm-linux-gnueabihf` - ARM 32-bit Linux (GNU libc) ✅ **官方支持**
- `riscv64-linux-gnu` - RISC-V 64-bit Linux
- `loongarch64-linux-gnu` - LoongArch64 Linux

### Android 平台 ✅ **官方支持**
- `aarch64-linux-android` - ARM64 Android
- `arm-linux-android` - ARM 32-bit Android
- `x86_64-linux-android` - x86_64 Android
- `x86-linux-android` - x86 32-bit Android

### Windows 平台
- `x86_64-windows-gnu` - x86_64 Windows (MinGW)
- `aarch64-windows-gnu` - ARM64 Windows (MinGW)

### macOS 平台
- `x86_64-macos` - x86_64 macOS
- `aarch64-macos` - ARM64 macOS (Apple Silicon)

### HarmonyOS 平台
- `aarch64-linux-harmonyos` - ARM64 HarmonyOS
- `arm-linux-harmonyos` - ARM 32-bit HarmonyOS
- `x86_64-linux-harmonyos` - x86_64 HarmonyOS

## 🛠️ 环境要求

### 必需工具
- **Zig 编译器** (≥0.11.0)
- **Meson 构建系统** (≥0.60.0)
- **Python 3** (用于脚本处理)
- **Git** (用于源码下载)

### 可选工具
- **jq** (用于 JSON 处理，提升体验)
- **curl/wget** (用于文件下载)

### 平台特定 SDK
- **Android**: Android NDK (推荐 r21e+)
- **HarmonyOS**: HarmonyOS SDK (4.1+)

## 📥 安装

1. **安装 Zig 编译器**
   ```bash
   # 从官网下载: https://ziglang.org/download/
   # 或使用包管理器
   wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
   tar -xf zig-linux-x86_64-0.11.0.tar.xz
   export PATH=$PWD/zig-linux-x86_64-0.11.0:$PATH
   ```

2. **安装 Meson**
   ```bash
   pip3 install meson ninja
   ```

3. **克隆项目**
   ```bash
   git clone <this-repo>
   cd rkrga-cross-build
   ```

## 🚀 使用方法

### 基本构建

```bash
# 构建默认平台 (x86_64-linux-gnu)
./build_with_zig.sh

# 构建指定平台
./build_with_zig.sh aarch64-linux-gnu

# 使用完整参数形式
./build_with_zig.sh --target=aarch64-linux-android
```

### 高级选项

```bash
# 启用大小优化
./build_with_zig.sh --target=aarch64-linux-gnu --optimize-size

# 启用 libdrm 支持
./build_with_zig.sh --target=x86_64-linux-gnu --enable-libdrm

# 启用示例程序
./build_with_zig.sh --target=aarch64-linux-gnu --enable-demos

# 指定 RGA 版本
./build_with_zig.sh --target=aarch64-linux-gnu --version=1.10.4
```

### 清理选项

```bash
# 清理构建缓存
./build_with_zig.sh clean

# 清理构建和安装目录
./build_with_zig.sh clean-dist
```

## 📁 输出结构

构建完成后，文件将输出到以下目录：

```
rkrga_install/Release/
└── <target-platform>/
    ├── lib/          # 库文件 (.so, .a)
    ├── include/      # 头文件
    └── bin/          # 示例程序 (如果启用)
```

## 🔧 配置选项

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `--target=<arch>` | 目标平台架构 | `x86_64-linux-gnu` |
| `--version=<ver>` | RGA 库版本 | `1.10.4` |
| `--optimize-size` | 启用库大小优化 | `false` |
| `--enable-demos` | 编译示例程序 | `false` |
| `--enable-libdrm` | 启用 libdrm 支持 | `false` |

## 🎯 平台特定说明

### Android 构建
需要设置 Android NDK 路径：
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r21e
./build_with_zig.sh aarch64-linux-android
```

### HarmonyOS 构建
需要设置 HarmonyOS SDK 路径：
```bash
export HARMONYOS_SDK_HOME=/path/to/ohos-sdk
./build_with_zig.sh aarch64-linux-harmonyos
```

### Windows 构建
使用 MinGW 工具链通过 Zig 进行交叉编译：
```bash
./build_with_zig.sh x86_64-windows-gnu
```

## 🐛 故障排除

### 常见问题

1. **Zig 编译器未找到**
   ```bash
   # 确保 Zig 在 PATH 中
   which zig
   zig version
   ```

2. **Meson 配置失败**
   ```bash
   # 清理并重试
   ./build_with_zig.sh clean
   ./build_with_zig.sh --target=your-target
   ```

3. **Android NDK 路径问题**
   ```bash
   # 检查 NDK 路径
   ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
   ```

4. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x build_with_zig.sh
   ```

## 📚 技术细节

### 构建系统
- **前端**: Meson 构建系统
- **编译器**: Zig 编译器 (交叉编译)
- **源码**: Rockchip RGA 官方镜像

### 优化特性
- 函数级别的垃圾回收 (`-ffunction-sections`)
- 数据段优化 (`-fdata-sections`)
- 链接时优化 (`--gc-sections`)
- 符号表裁剪 (`--strip-all`)

### 兼容性处理
- 自动处理 64 位指针转换
- 修复缺失的宏定义
- 解决时钟偏差问题

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

## 📄 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Rockchip](https://www.rock-chips.com/) - RGA 库的原始开发者
- [Zig 项目](https://ziglang.org/) - 现代的系统编程语言
- [Meson 构建系统](https://mesonbuild.com/) - 快速友好的构建系统

## 📞 支持

如有问题或建议，请：
- 提交 [GitHub Issue](../../issues)
- 查看 [Wiki 文档](../../wiki)
- 参与 [Discussions](../../discussions)

---

**免责声明**: 本项目为非官方实现，仅供学习和测试使用。生产环境请使用 Rockchip 官方发布的版本。
