class Rustfs < Formula
  VERSION = "1.0.0-alpha.17".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "25254ec106022f290b7e74c8f8ada879cdc2cf2953bd170258e1fab54edf14c3"
  license "Apache-2.0"
  head "https://github.com/#{GITHUB_REPO}.git", branch: "main", shallow: false

  # Only required for source builds
  depends_on "protobuf" => :build
  depends_on "flatbuffers" => :build
  depends_on "pkgconf" => :build
  depends_on "zstd"
  depends_on "openssl@3"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    cargo_bin = File.expand_path("~/.cargo/bin")

    if File.directory?(cargo_bin)
      ENV.prepend_path "PATH", cargo_bin
      ohai "Added #{cargo_bin} to PATH for building Rust sources."
    else
      opoo "#{cargo_bin} not found. Make sure Rust toolchain is installed and activated."
    end

    if binary_available? && !build.head? && !build.with?("build-from-source")
      ohai "Installing from pre-compiled binary..."
      install_from_binary
    else
      check_build_tools!
      ohai "Installing from source code..."
      install_from_source
    end
  rescue StandardError => e
    odie "Installation failed: #{e.message}\nFor support, please open an issue at: #{homepage}"
  end

  def caveats
    install_method = if build.head? || !binary_available?
                       "source (build from source)"
                     else
                       "binary (precompiled)"
                     end
    platform_info = "#{OS.kernel_name} (#{Hardware::CPU.arch})"

    <<~EOS
      Thank you for installing rustfs!

      Platform: #{platform_info}
      Installation method: #{install_method}

      ✅ Get started:
        rustfs --help        # View all available commands
        rustfs --version     # Check version

      🛠️ To build from source explicitly:
        brew install --build-from-source rustfs

      📦 If you encounter issues, please ensure you have the Rust toolchain installed:
        brew install rust
        rustup install stable
        rustup default stable
        rustup target add #{rust_target}  # If applicable

      If you choose to build from source, please ensure the Rust toolchain is installed and visible to Homebrew.

      You can install Rust via https://rustup.rs

      For example, you may need to add Rust tools to your PATH:
        ln -s ~/.cargo/bin/cargo /usr/local/bin/cargo
        ln -s ~/.cargo/bin/rustc /usr/local/bin/rustc

      For more information, visit: #{homepage}
      If you prefer to use a precompiled binary, ensure you have the correct architecture:
      - macOS: aarch64-apple-darwin or x86_64-apple-darwin
      - Linux: aarch64-unknown-linux-musl or x86_64-unknown-linux-musl
      If you need to build from source, ensure you have the required dependencies:
      - protobuf
      - flatbuffers
      - pkgconf
      - zstd
      - openssl@3
      For more details, refer to the documentation at: #{homepage}
      #{binary_available? ? "🔗 Precompiled binary available for your platform: #{binary_url_and_sha[0]}" : "⚠️ No precompiled binary available for your platform."}
      #{binary_available? ? "SHA256: #{binary_url_and_sha[1]}" : ""}
      #{binary_available? ? "To use the precompiled binary, ensure it is in your PATH." : ""}
      #{binary_available? ? "To build from source, ensure you have the Rust toolchain installed." : ""}
      #{binary_available? ? "To build from source, run: brew install --build-from-source rustfs" : ""}
      #{binary_available? ? "To build from source, ensure you have the required dependencies installed." : ""}
    EOS
  end

  def test
    version_output = shell_output("#{bin}/rustfs --version")
    assert_match "rustfs #{version}", version_output
  end

  private

  def check_build_tools!
    %w[cargo rustc].each do |cmd|
      odie "#{cmd} not found. Please install the Rust toolchain from https://rustup.rs or use precompiled binary." unless which(cmd)
    end
  end

  def binary_info
    @binary_info ||= begin
                       target, sha256 = on_macos do
                         on_arm { ["aarch64-apple-darwin", "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d"] }
                         on_intel { ["x86_64-apple-darwin", "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071"] }
                       end || on_linux do
                         on_arm { ["aarch64-unknown-linux-musl", "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1"] }
                         on_intel { ["x86_64-unknown-linux-musl", "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607"] }
                       end

                       if target && sha256
                         url = "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-#{target}.zip"
                         [target, url, sha256]
                       else
                         [nil, nil, nil]
                       end
                     end
  end

  def rust_target
    binary_info[0]
  end

  def binary_url_and_sha
    binary_info[1..2]
  end

  def binary_available?
    binary_url_and_sha.all?
  end

  def install_from_binary
    ohai "Installing from precompiled binary..."
    url, sha256 = binary_url_and_sha

    odie "No binary available for this platform." unless url

    resource "binary" do
      url url
      sha256 sha256
    end

    resource("binary").stage do
      bin.install "rustfs"
    end
  end

  def install_from_source
    ohai build.head? ? "Installing from HEAD (source)..." : "Installing from source..."

    # Additional build dependencies
    ENV["CARGO_BUILD_JOBS"] = ENV.make_jobs.to_s
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    target = rust_target
    cargo_args = %w[--release --bin rustfs]
    install_path = "target/release/rustfs"

    if OS.linux? && target
      system "rustup", "target", "add", target
      cargo_args += ["--target", target]
      install_path = "target/#{target}/release/rustfs"
    end

    system "cargo", "build", *cargo_args
    bin.install install_path
  end
end
