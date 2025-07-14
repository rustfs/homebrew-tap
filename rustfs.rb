class Rustfs < Formula
  VERSION = "1.0.0-alpha.17".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze

  BINARY_CONFIGS = {
    "aarch64-apple-darwin" => "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d",
    "x86_64-apple-darwin" => "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071",
    "aarch64-unknown-linux-musl" => "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1",
    "x86_64-unknown-linux-musl" => "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607"
  }.freeze

  PLATFORM_MAPPING = {
    macos: { arm: "aarch64-apple-darwin", intel: "x86_64-apple-darwin" },
    linux: { arm: "aarch64-unknown-linux-musl", intel: "x86_64-unknown-linux-musl" }
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "25254ec106022f290b7e74c8f8ada879cdc2cf2953bd170258e1fab54edf14c3"
  license "Apache-2.0"
  head "https://github.com/#{GITHUB_REPO}.git", branch: "main", shallow: false

  # 标准的构建依赖声明。Homebrew 会在需要时自动处理。
  depends_on "rust" => :build
  depends_on "protobuf" => :build
  depends_on "flatbuffers" => :build
  depends_on "pkg-config" => :build if OS.linux?
  depends_on "openssl@3" if OS.linux?

  def install
    # 如果二进制可用且 Homebrew 决定使用它 (build.bottle? is true), 则进行二进制安装。
    # 否则 (包括 --build-from-source, --HEAD, 或无可用 bottle 的情况), 从源码构建。
    if binary_available? && build.bottle?
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
    platform_info = "#{OS.mac? ? "macOS" : "Linux"} (#{Hardware::CPU.arch})"

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

    if build.head?
      s += "\n\nNote: You have installed the latest development version from HEAD."
    end

    s
  end

  def test
    version_output = shell_output("#{bin}/rustfs --version")
    assert_match "rustfs #{version}", version_output
  end

  private

  def platform_target
    @platform_target ||= PLATFORM_MAPPING.dig(OS.mac? ? :macos : :linux, Hardware::CPU.arm? ? :arm : :intel)
  end

  def binary_available?
    target = platform_target
    target && BINARY_CONFIGS.key?(target)
  end

  def install_from_binary
    ohai "Installing from pre-compiled binary..."
    target = platform_target
    url = "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-#{target}.zip"
    sha256 = BINARY_CONFIGS[target]

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

    target = platform_target
    cargo_args = %w[build --release --bin rustfs]
    install_path = "target/release/rustfs"

    if OS.linux? && target
      system "rustup", "target", "add", target
      cargo_args.concat(["--target", target])
      install_path = "target/#{target}/release/rustfs"
    end

    system "cargo", *cargo_args
    bin.install install_path
  end
end