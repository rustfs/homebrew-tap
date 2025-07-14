class Rustfs < Formula
  VERSION = "1.0.0-alpha.17".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "25254ec106022f290b7e74c8f8ada879cdc2cf2953bd170258e1fab54edf14c3"
  license "Apache-2.0"
  head "https://github.com/#{GITHUB_REPO}.git", branch: "main", shallow: false

  # 仅在需要从源代码构建时依赖 Rust 等构建工具
  depends_on "rust" => [:build, { if: -> { build.from_source? || build.head? } }]
  depends_on "protobuf" => [:build, { if: -> { build.from_source? || build.head? } }]
  depends_on "flatbuffers" => [:build, { if: -> { build.from_source? || build.head? } }]
  depends_on "pkgconf" => [:build, { if: -> { build.from_source? || build.head? } }]
  depends_on "zstd"
  depends_on "openssl@3"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    if binary_available? && !build.from_source? && !build.head?
      install_from_binary
    else
      install_from_source
    end
  rescue StandardError => e
    odie "Installation failed: #{e.message}\nFor support, please open an issue at: #{homepage}"
  end

  def caveats
    install_method = if build.from_source? || build.head? || !binary_available?
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
    assert_match "rustfs #{VERSION}", version_output
  end

  private

  def binary_info
    @binary_info ||= begin
                       target, sha256 = on_macos do
                         on_arm do
                           ["aarch64-apple-darwin", "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d"]
                         end
                         on_intel do
                           ["x86_64-apple-darwin", "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071"]
                         end
                       end || on_linux do
                         on_arm do
                           ["aarch64-unknown-linux-musl", "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1"]
                         end
                         on_intel do
                           ["x86_64-unknown-linux-musl", "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607"]
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
    binary_info[0]
  end

  def binary_url_and_sha
    binary_info[1..2]
  end

  def binary_available?
    binary_url_and_sha.all?
  end

  def install_from_binary
    ohai "Installing from pre-compiled binary..."
    url, sha256 = binary_url_and_sha

    odie "Pre-compiled binary not available for this platform." unless url

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