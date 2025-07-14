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

  # 移除条件依赖，改为运行时检查
  # 只有在源码安装时才会检查这些依赖

  on_macos do
    if Hardware::CPU.arm?
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-aarch64-apple-darwin.zip"
        sha256 BINARY_CONFIGS["aarch64-apple-darwin"]
      end
    elsif Hardware::CPU.intel?
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-x86_64-apple-darwin.zip"
        sha256 BINARY_CONFIGS["x86_64-apple-darwin"]
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-aarch64-unknown-linux-musl.zip"
        sha256 BINARY_CONFIGS["aarch64-unknown-linux-musl"]
      end
    elsif Hardware::CPU.intel?
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-x86_64-unknown-linux-musl.zip"
        sha256 BINARY_CONFIGS["x86_64-unknown-linux-musl"]
      end
    end
  end

  def install
    @install_method = binary_available? ? "binary" : "source"

    case @install_method
    when "binary"
      install_from_binary
    when "source"
      ensure_build_dependencies
      configure_git_for_large_repos
      install_from_source
    end
  rescue StandardError => e
    odie "Installation failed: #{e.message}"
  end

  def caveats
    CaveatsGenerator.new(self).generate
  end

  def test
    version_output = shell_output("#{bin}/rustfs --version")
    assert_match "rustfs #{VERSION}", version_output

    help_output = shell_output("#{bin}/rustfs --help")
    assert_match "Usage:", help_output
  end

  private

  def binary_available?
    return false unless OS.mac? || OS.linux?
    return false unless Hardware::CPU.arm? || Hardware::CPU.intel?

    current_platform = OS.mac? ? :macos : :linux
    arch = Hardware::CPU.arm? ? :arm : :intel
    target = PLATFORM_MAPPING.dig(current_platform, arch)

    target && BINARY_CONFIGS[target]
  end

  def ensure_build_dependencies
    ohai "Checking build dependencies for source installation..."

    missing_deps = []

    # 检查 Rust/Cargo
    unless system "which", "cargo", out: File::NULL, err: File::NULL
      missing_deps << "rust (cargo command not found)"
    end

    # 检查 protobuf
    unless system "which", "protoc", out: File::NULL, err: File::NULL
      missing_deps << "protobuf (protoc command not found)"
    end

    # 检查 flatbuffers
    unless system "which", "flatc", out: File::NULL, err: File::NULL
      missing_deps << "flatbuffers (flatc command not found)"
    end

    if OS.linux?
      # 检查 pkg-config
      unless system "which", "pkg-config", out: File::NULL, err: File::NULL
        missing_deps << "pkg-config"
      end

      # 检查 openssl
      unless system "pkg-config", "--exists", "openssl", out: File::NULL, err: File::NULL
        missing_deps << "openssl (development libraries)"
      end
    end

    return if missing_deps.empty?

    # 生成安装建议
    install_suggestions = build_install_suggestions(missing_deps)

    odie <<~EOS
      Missing build dependencies for source installation:
      #{missing_deps.map { |dep| "- #{dep}" }.join("\n")}

      Please install the missing dependencies first:
      #{install_suggestions}

      Alternatively, try forcing a binary installation if available.
    EOS
  end

  def build_install_suggestions(missing_deps)
    suggestions = []

    if OS.mac?
      suggestions << "# Install with Homebrew:"
      missing_deps.each do |dep|
        case dep
        when /rust/
          suggestions << "brew install rust"
        when /protobuf/
          suggestions << "brew install protobuf"
        when /flatbuffers/
          suggestions << "brew install flatbuffers"
        end
      end
    elsif OS.linux?
      suggestions << "# Install with your package manager:"
      suggestions << "# Ubuntu/Debian:"
      missing_deps.each do |dep|
        case dep
        when /rust/
          suggestions << "sudo apt-get install cargo rustc"
        when /protobuf/
          suggestions << "sudo apt-get install protobuf-compiler"
        when /flatbuffers/
          suggestions << "sudo apt-get install flatbuffers-compiler"
        when /pkg-config/
          suggestions << "sudo apt-get install pkg-config"
        when /openssl/
          suggestions << "sudo apt-get install libssl-dev"
        end
      end
    end

    suggestions.join("\n")
  end

  def configure_git_for_large_repos
    system "git", "config", "--global", "http.postBuffer", "524288000"
    system "git", "config", "--global", "http.lowSpeedLimit", "0"
    system "git", "config", "--global", "http.lowSpeedTime", "999999"
    system "git", "config", "--global", "core.preloadindex", "true"
  rescue StandardError
    # 忽略 Git 配置失败，继续安装
  end

  def install_from_binary
    ohai "Installing from pre-compiled binary..."
    resource("binary").stage { bin.install "rustfs" }
  end

  def install_from_source
    ohai "Installing from source code..."
    target = determine_target
    cargo_args = build_cargo_args(target)
    install_path = build_install_path(target)

    setup_target(target) if target

    execute_with_retry do
      system "cargo", *cargo_args
    end

    bin.install install_path
  end

  def execute_with_retry(max_retries: 3)
    retry_count = 0
    begin
      yield
    rescue StandardError => e
      retry_count += 1
      if retry_count <= max_retries
        ohai "Operation failed, retrying (#{retry_count}/#{max_retries})..."
        sleep retry_count * 2
        retry
      else
        raise e
      end
    end
  end

  def determine_target
    return nil unless OS.linux?

    arch = Hardware::CPU.arm? ? :arm : :intel
    PLATFORM_MAPPING.dig(:linux, arch)
  end

  def build_cargo_args(target)
    args = %w[build --release --bin rustfs]
    args.concat(["--target", target]) if target
    args
  end

  def build_install_path(target)
    target ? "target/#{target}/release/rustfs" : "target/release/rustfs"
  end

  def setup_target(target)
    system "rustup", "target", "add", target
  end
end

class CaveatsGenerator
  def initialize(formula)
    @formula = formula
  end

  def generate
    [
      header_section,
      commands_section,
      additional_info_section,
      performance_tips_section
    ].compact.join("\n\n")
  end

  private

  def header_section
    platform_info = "#{OS.mac? ? 'macOS' : 'Linux'} (#{Hardware::CPU.arch})"
    install_method = @formula.instance_variable_get(:@install_method) || "unknown"

    <<~EOS.chomp
      Thank you for installing rustfs!

      Platform: #{platform_info}
      Installation method: #{install_method}
    EOS
  end

  def commands_section
    <<~EOS.chomp
      You can get started with the following commands:

      # View all available commands and help information
      rustfs --help

      # Check the version
      rustfs --version
    EOS
  end

  def additional_info_section
    info = collect_additional_info
    return nil if info.empty?

    "Additional information:\n#{info.map { |i| "- #{i}" }.join("\n")}"
  end

  def performance_tips_section
    tips = collect_performance_tips
    return nil if tips.empty?

    "Performance tips:\n#{tips.map { |tip| "- #{tip}" }.join("\n")}"
  end

  def collect_additional_info
    info = []
    install_method = @formula.instance_variable_get(:@install_method)

    case install_method
    when "binary"
      info << "Using pre-compiled binary for optimal performance."
      info << "No build dependencies were required."
    when "source"
      info << "Compiled from source code with all dependencies checked."
      info << "Build dependencies were verified before compilation."
    end

    info << "This is an alpha release. Please report issues to GitHub." if Rustfs::VERSION.include?("alpha")
    info
  end

  def collect_performance_tips
    tips = []
    tips << "Set RUSTFS_THREADS=#{Hardware::CPU.cores} for optimal threading." if OS.linux?
    tips << "ARM-optimized binary provides excellent performance on Apple Silicon." if Hardware::CPU.arm?
    tips
  end
end