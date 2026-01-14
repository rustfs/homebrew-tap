# RustFS Homebrew Tap

English | [简体中文](README_ZH.md)

This repository is the official Homebrew Tap for [RustFS](https://github.com/rustfs/rustfs). `RustFS` is a high-performance distributed object storage software built using Rust.

## Installation

You can install `RustFS` and `RustFS-cli` in several ways.

### Via Homebrew (Recommended)

This is the easiest way to get started.

1. **Add the Tap:**
   ```sh
   brew tap rustfs/homebrew-tap
   ```

2. **Install RustFS:**
   ```sh
   brew install rustfs
   ```

3. **Install RustFS-cli:**
   ```sh
   brew install rc
   ```

4. **Update RustFS and RustFS-cli:**
   ```sh
   brew upgrade rustfs rc
   ```

### Manual Installation

#### RustFS

1. Go to the [GitHub Releases](https://github.com/rustfs/rustfs/releases) page.
2. Download the appropriate archive for your operating system and CPU architecture.
3. Unzip the archive and move the `rustfs` executable to a directory in your `PATH` (e.g., `/usr/local/bin`).

#### RustFS-cli

1. Go to the [RustFS-cli Releases](https://github.com/rustfs/cli/releases) page.
2. Download the appropriate archive for your operating system and CPU architecture.
3. Unzip the archive and move the `rc` executable to a directory in your `PATH` (e.g., `/usr/local/bin`).

## Usage

After installation, you can verify it and get help by running:

### RustFS

```sh
# Check the version
rustfs --version

# View all available commands
rustfs --help
```

### RustFS-cli

```sh
# Check the version
rc --version

# View all available commands
rc --help
```

For more detailed usage and documentation, please visit the official website: [https://rustfs.com](https://rustfs.com)

## Supported Platforms

We provide pre-compiled binaries for the following platforms:

- **macOS**
    - Apple Silicon (`arm64`)
    - Intel (`x86_64`)
- **Linux**
    - ARM (`aarch64`)
    - Intel/AMD (`x86_64`)

## Contributing

Contributions are welcome via Issues and Pull Requests.

- For issues related to this Homebrew Tap, please file them in this repository.
- For issues or feature requests related to the `RustFS` tool itself, please file them in the [main project repository](https://github.com/rustfs/rustfs).
- For issues or feature requests related to the `RustFS-cli` tool, please file them in the [RustFS-cli repository](https://github.com/rustfs/cli).
- Before submitting a Pull Request, please ensure you follow the project's code style and contribution guidelines.

## License

This project is licensed under the [Apache-2.0](LICENSE) License.
