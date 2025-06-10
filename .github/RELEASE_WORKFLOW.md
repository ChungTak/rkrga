# Rockchip RGA Release Build

这个 GitHub Actions 工作流程用于自动构建 Rockchip RGA 库的多平台二进制包。

## 源码信息

- **源码地址**: https://github.com/ChungTak/rkrga
- **基础分支**: main
- **上游项目**: https://github.com/airockchip/librga

## 版本获取

工作流程会自动从 [airockchip/librga 的提交历史](https://github.com/airockchip/librga/commits/main/) 中提取最新版本号。版本号提取规则：

- 查找包含 "Update librga version to " 的提交信息
- 提取 "version to " 后面的版本号
- 例如：从 "Update librga version to 1.10.4_[1]" 提取版本号 "1.10.4_[1]"

## 支持的平台

### Linux
- x86_64-linux-gnu
- aarch64-linux-gnu  
- arm-linux-gnueabihf

### RISC-V
- riscv64-linux-gnu

### LoongArch
- loongarch64-linux-gnu

### Android
- aarch64-linux-android
- arm-linux-android
- x86_64-linux-android

### HarmonyOS
- aarch64-linux-harmonyos
- arm-linux-harmonyos
- x86_64-linux-harmonyos

## 使用方法

1. 在 GitHub 仓库的 "Actions" 页面找到 "Release Build ALL Platforms" 工作流程
2. 点击 "Run workflow" 按钮
3. 配置参数：
   - **version_tag**: 版本标签（留空自动获取）
   - **build_targets**: 构建目标（"all" 或指定目标列表）
   - **enable_debug**: 是否启用调试构建
   - **optimize_size**: 是否启用大小优化

## 构建输出

每个平台的构建产物包含：

```
rockchip-rga-{version}-{target}/
├── include/          # 头文件
├── lib/             # 库文件 (.so, .a)
├── pkgconfig/       # pkg-config 文件（如果可用）
├── BUILD_INFO.txt   # 构建信息
└── CHECKSUMS.txt    # 文件校验和
```

## 构建脚本

项目使用 `build_with_zig.sh` 脚本进行跨平台构建，支持：

- 使用 Zig 编译器进行交叉编译
- 自动配置 Android NDK
- 自动配置 HarmonyOS SDK
- 库文件大小优化
- 示例程序编译（可选）

## 验证

构建完成后会自动运行验证脚本 `.github/scripts/validate_build.sh`，检查：

- 必需的目录结构（include/, lib/）
- 关键头文件（rga.h, RgaApi.h, RockchipRga.h）
- 库文件存在性
- im2d API 头文件（如果存在）

## 发布

构建成功后会自动创建 GitHub Release，包含：

- 版本信息和变更说明
- 所有平台的二进制包
- 构建元数据和校验和

## 注意事项

- Windows 和 macOS 平台目前可能不完全支持（RGA 主要面向 Linux/Android）
- HarmonyOS 构建需要特殊的 SDK 配置
- 某些平台可能需要特定的系统依赖
