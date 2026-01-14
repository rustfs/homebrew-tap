# RustFS Homebrew Tap

[English](README.md) | 简体中文

本仓库是 [RustFS](https://github.com/rustfs/rustfs) 的官方 Homebrew Tap。`RustFS` 是一个使用 Rust 构建的高性能分布式对象存储软件。

## 安装

您可以通过以下几种方式安装 `RustFS` 及 `RustFS-cli`。

### 通过 Homebrew (推荐)

这是最简单的安装方式。

1. **添加 Tap:**
   ```sh
   brew tap rustfs/homebrew-tap
   ```

2. **安装 RustFS:**
   ```sh
   brew install rustfs
   ```

3. **安装 RustFS-cli:**
   ```sh
   brew install rc
   ```

4. **更新 RustFS 及 RustFS-cli:**
   ```sh
   brew upgrade rustfs rc
   ```

### 手动安装

#### RustFS

1. 前往 [GitHub Releases](https://github.com/rustfs/rustfs/releases) 页面。
2. 根据您的操作系统和 CPU 架构，下载对应的 `.zip` 压缩包。
3. 解压文件，并将得到的 `RustFS` 可执行文件移动到您的 `PATH` 环境变量下的任一目录中 (例如 `/usr/local/bin`)。

#### RustFS-cli

1. 前往 [RustFS-cli Releases](https://github.com/rustfs/cli/releases) 页面。
2. 根据您的操作系统和 CPU 架构，下载对应的 `.zip` 压缩包。
3. 解压文件，并将得到的 `rc` 可执行文件移动到您的 `PATH` 环境变量下的任一目录中 (例如 `/usr/local/bin`)。

## 使用方法

安装完成后，您可以通过运行以下命令来验证安装并查看帮助信息：

### RustFS

```sh
# 查看版本
rustfs --version

# 查看所有可用命令
rustfs --help
```

### RustFS-cli

```sh
# 查看版本
rc --version

# 查看所有可用命令
rc --help
```

更多详细用法和文档，请访问官方网站：[https://rustfs.com](https://rustfs.com)

## 支持平台

我们为以下平台提供预编译的二进制文件：

- **macOS**
    - Apple Silicon (`arm64`)
    - Intel (`x86_64`)
- **Linux**
    - ARM (`aarch64`)
    - Intel/AMD (`x86_64`)

## 贡献

欢迎通过提交 Issue 或 Pull Request 为本项目做出贡献。

- 对于 Homebrew Tap 相关的问题，请在本仓库中提交。
- 对于 `RustFS` 工具本身的问题或功能建议，请在 [主项目仓库](https://github.com/rustfs/rustfs) 中提交。
- 对于 `RustFS-cli` 工具相关的问题或功能建议，请在 [RustFS-cli 仓库](https://github.com/rustfs/cli) 中提交。
- 在提交 Pull Request 之前，请确保遵循项目的代码风格和贡献指南。

## 许可证

本项目采用 [Apache-2.0](LICENSE) 许可证。