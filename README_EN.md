# Rockchip RGA Cross-Platform Build Tool

English | [中文](./README.md)

This is a cross-platform tool for building Rockchip RGA (Raster Graphic Acceleration) library using the Zig compiler. It supports cross-compilation for multiple target platforms including Linux, Android, Windows, macOS, and HarmonyOS.

## ⚠️ Important Notice

**Rockchip officially only releases RGA library for Android and ARM Linux versions. Other platform versions supported in this project (such as x86, Windows, macOS, etc.) are for testing and development purposes only, and stability in production environments is not guaranteed. Please use with caution based on your actual needs.**

## 🚀 Features

- 🎯 **Multi-platform Support**: Supports 10+ target platform architectures
- ⚡ **Fast Build**: Fast cross-compilation using Zig compiler
- 📦 **Automatic Dependency Management**: Automatically downloads and configures necessary dependencies
- 🔧 **Flexible Configuration**: Supports multiple build options and optimizations
- 🌐 **Modern Toolchain**: Based on Meson build system and Zig compiler

## 📋 Supported Target Platforms

### Linux Platforms
- `x86_64-linux-gnu` - x86_64 Linux (GNU libc)
- `aarch64-linux-gnu` - ARM64 Linux (GNU libc) ✅ **Officially Supported**
- `arm-linux-gnueabihf` - ARM 32-bit Linux (GNU libc) ✅ **Officially Supported**
- `riscv64-linux-gnu` - RISC-V 64-bit Linux
- `loongarch64-linux-gnu` - LoongArch64 Linux

### Android Platforms ✅ **Officially Supported**
- `aarch64-linux-android` - ARM64 Android
- `arm-linux-android` - ARM 32-bit Android
- `x86_64-linux-android` - x86_64 Android
- `x86-linux-android` - x86 32-bit Android

### Windows Platforms
- `x86_64-windows-gnu` - x86_64 Windows (MinGW)
- `aarch64-windows-gnu` - ARM64 Windows (MinGW)

### macOS Platforms
- `x86_64-macos` - x86_64 macOS
- `aarch64-macos` - ARM64 macOS (Apple Silicon)

### HarmonyOS Platforms
- `aarch64-linux-harmonyos` - ARM64 HarmonyOS
- `arm-linux-harmonyos` - ARM 32-bit HarmonyOS
- `x86_64-linux-harmonyos` - x86_64 HarmonyOS

## 🛠️ Requirements

### Required Tools
- **Zig Compiler** (≥0.11.0)
- **Meson Build System** (≥0.60.0)
- **Python 3** (for script processing)
- **Git** (for source code download)

### Optional Tools
- **jq** (for JSON processing, improves experience)
- **curl/wget** (for file downloads)

### Platform-specific SDKs
- **Android**: Android NDK (recommended r21e+)
- **HarmonyOS**: HarmonyOS SDK (4.1+)

## 📥 Installation

1. **Install Zig Compiler**
   ```bash
   # Download from official site: https://ziglang.org/download/
   # Or use package manager
   wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
   tar -xf zig-linux-x86_64-0.11.0.tar.xz
   export PATH=$PWD/zig-linux-x86_64-0.11.0:$PATH
   ```

2. **Install Meson**
   ```bash
   pip3 install meson ninja
   ```

3. **Clone Project**
   ```bash
   git clone <this-repo>
   cd rkrga-cross-build
   ```

## 🚀 Usage

### Basic Build

```bash
# Build for default platform (x86_64-linux-gnu)
./build_with_zig.sh

# Build for specific platform
./build_with_zig.sh aarch64-linux-gnu

# Use full parameter format
./build_with_zig.sh --target=aarch64-linux-android
```

### Advanced Options

```bash
# Enable size optimization
./build_with_zig.sh --target=aarch64-linux-gnu --optimize-size

# Enable libdrm support
./build_with_zig.sh --target=x86_64-linux-gnu --enable-libdrm

# Enable demo programs
./build_with_zig.sh --target=aarch64-linux-gnu --enable-demos

# Specify RGA version
./build_with_zig.sh --target=aarch64-linux-gnu --version=1.10.4
```

### Cleanup Options

```bash
# Clean build cache
./build_with_zig.sh clean

# Clean build and install directories
./build_with_zig.sh clean-dist
```

## 📁 Output Structure

After successful build, files will be output to the following directory:

```
rkrga_install/Release/
└── <target-platform>/
    ├── lib/          # Library files (.so, .a)
    ├── include/      # Header files
    └── bin/          # Demo programs (if enabled)
```

## 🔧 Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `--target=<arch>` | Target platform architecture | `x86_64-linux-gnu` |
| `--version=<ver>` | RGA library version | `1.10.4` |
| `--optimize-size` | Enable library size optimization | `false` |
| `--enable-demos` | Compile demo programs | `false` |
| `--enable-libdrm` | Enable libdrm support | `false` |

## 🎯 Platform-specific Notes

### Android Build
Set Android NDK path:
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r21e
./build_with_zig.sh aarch64-linux-android
```

### HarmonyOS Build
Set HarmonyOS SDK path:
```bash
export HARMONYOS_SDK_HOME=/path/to/ohos-sdk
./build_with_zig.sh aarch64-linux-harmonyos
```

### Windows Build
Cross-compile using MinGW toolchain via Zig:
```bash
./build_with_zig.sh x86_64-windows-gnu
```

## 🐛 Troubleshooting

### Common Issues

1. **Zig compiler not found**
   ```bash
   # Ensure Zig is in PATH
   which zig
   zig version
   ```

2. **Meson configuration failed**
   ```bash
   # Clean and retry
   ./build_with_zig.sh clean
   ./build_with_zig.sh --target=your-target
   ```

3. **Android NDK path issues**
   ```bash
   # Check NDK path
   ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
   ```

4. **Permission issues**
   ```bash
   # Ensure script has execute permission
   chmod +x build_with_zig.sh
   ```

## 📚 Technical Details

### Build System
- **Frontend**: Meson build system
- **Compiler**: Zig compiler (cross-compilation)
- **Source**: Rockchip RGA official mirror

### Optimization Features
- Function-level garbage collection (`-ffunction-sections`)
- Data section optimization (`-fdata-sections`)
- Link-time optimization (`--gc-sections`)
- Symbol table stripping (`--strip-all`)

### Compatibility Handling
- Automatic 64-bit pointer conversion handling
- Fix missing macro definitions
- Resolve clock skew issues

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this project
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is open source under the MIT License. See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Rockchip](https://www.rock-chips.com/) - Original developer of RGA library
- [Zig Project](https://ziglang.org/) - Modern systems programming language
- [Meson Build System](https://mesonbuild.com/) - Fast and friendly build system

## 📞 Support

For questions or suggestions, please:
- Submit [GitHub Issue](../../issues)
- Check [Wiki Documentation](../../wiki)
- Join [Discussions](../../discussions)

---

**Disclaimer**: This project is an unofficial implementation for learning and testing purposes only. For production environments, please use the official versions released by Rockchip.
