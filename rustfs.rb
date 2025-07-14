class Rustfs < Formula
  VERSION = "1.0.0-alpha.17".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "25254ec106022f290b7e74c8f8ada879cdc2cf2953bd170258e1fab54edf14c3"
  license "Apache-2.0"
  head "https://github.com/#{GITHUB_REPO}.git", branch: "main", shallow: false

  depends_on "rust" => :build
  depends_on "protobuf" => :build
  depends_on "flatbuffers" => :build
  depends_on "pkg-config" => :build
  depends_on "zstd"
  depends_on "openssl@3", on_linux: true

  def install
    # 如果 Homebrew 不使用官方 bottle (例如 --build-from-source) 且我们有二进制包，则使用它。
    # 安装 --HEAD 时，build.bottle? 为 false，将从源码构建。
    if binary_available? && build.bottle? && !build.head?
      install_from_binary
    else
      install_from_source
    end
  rescue StandardError => e
    odie "Installation failed: #{e.message}\nFor support, please open an issue at: #{homepage}"
  end

  def caveats
    install_method = if !build.bottle? || build.head?
                       "source"
                     else
                       "binary"
                     end
    platform_info = "#{OS.kernel_name} (#{Hardware::CPU.arch})"

    s = <<~EOS
      Thank you for installing rustfs!

      Platform: #{platform_info}
      Installation method: #{install_method}

      You can get started with the following commands:
      # View all available commands and help information
      rustfs --help

      # Check the version
      rustfs --version
    EOS

    s += "\n\nNote: You have installed the latest development version from HEAD." if build.head?
    s
  end

  def test
    version_output = shell_output("#{bin}/rustfs --version")
    assert_match "rustfs #{version}", version_output
  end

  private

  def binary_info
    @binary_info ||= begin
                       target, sha256 = nil
                       on_macos do
                         on_arm do
                           target = "aarch64-apple-darwin"
                           sha256 = "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d"
                         end
                         on_intel do
                           target = "x86_64-apple-darwin"
                           sha256 = "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071"
                         end
                       end
                       on_linux do
                         on_arm do
                           target = "aarch64-unknown-linux-musl"
                           sha256 = "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1"
                         end
                         on_intel do
                           target = "x86_64-unknown-linux-musl"
                           sha256 = "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607"
                         end
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
    target, = binary_info
    target
  end

  def binary_available?
    _, url, sha256 = binary_info
    !url.nil? && !sha256.nil?
  end

  def install_from_binary
    ohai "Installing from pre-compiled binary..."
    _, url, sha256 = binary_info

    resource "binary" do
      url url
      sha256 sha256
    end

    resource("binary").stage do
      bin.install "rustfs"
    end
  end

  def install_from_source
    install_message = build.head? ? "Installing from HEAD (latest source)..." : "Installing from source code..."
    ohai install_message

    ENV["CARGO_BUILD_JOBS"] = ENV.make_jobs.to_s
    ENV.deparallelize

    target = rust_target
    cargo_args = %w[build --release --bin rustfs]
    install_path = "target/release/rustfs"

    if target
      system "rustup", "target", "add", target
      cargo_args.concat(["--target", target])
      install_path = "target/#{target}/release/rustfs"
    end

    system "cargo", *cargo_args
    bin.install install_path
  end
end