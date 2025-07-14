# RustFS Homebrew Tap

English | [简体中文](README_ZH.md)

This is the official Homebrew Tap
for [RustFS](https://github.com/rustfs/rustfs), [RustFS](https://github.com/rustfs/rustfs) is a high-performance
distributed object storage software built using Rust

## Installation

You can install `RustFS` in several ways.

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

### From Source (For Developers)

If you want to install the latest development version, you can build from source.

```sh
brew install --HEAD rustfs
```

### Manual Installation

1. Go to the [GitHub Releases](https://github.com/rustfs/rustfs/releases) page.
2. Download the appropriate `.zip` archive for your operating system and CPU architecture.
3. Unzip the archive and move the `RustFS` executable to a directory in your `PATH` (e.g., `/usr/local/bin`).

## Usage

After installation, you can verify it and get help by running:

```sh
# Check the version
rustfs --version

# View all available commands
rustfs --help
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
- For issues or feature requests related to the `RustFS` tool itself, please file them in
  the [main project repository](https://github.com/rustfs/rustfs).

## License

This project is licensed under the [Apache-2.0](LICENSE) License.