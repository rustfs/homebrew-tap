class Rustfs < Formula
  VERSION = "1.0.0-alpha.17".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "aarch64-apple-darwin" => "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d",
    "x86_64-apple-darwin" => "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071",
    "aarch64-unknown-linux-musl" => "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1",
    "x86_64-unknown-linux-musl" => "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "25254ec106022f290b7e74c8f8ada879cdc2cf2953bd170258e1fab54edf14c3"
  license "Apache-2.0"

  # Runtime dependencies
  depends_on "zstd"
  depends_on "openssl@3"

  def install
    url, sha = binary_url_and_sha
    odie "This formula has no pre-compiled binary for your platform: #{system_target}" unless url

    ohai "Installing from pre-compiled binary..."
    resource "binary" do
      url url
      sha256 sha
    end

    resource("binary").stage do
      bin.install "rustfs"
    end
  end

  def caveats
    <<~EOS
      Thank you for installing rustfs!

      === Quick Start ===
      # View all available commands and help information:
      rustfs --help

      # Check the version:
      rustfs --version

      === Developer Guide ===
      If you want to build from source manually:

      1. Clone the repository:
         git clone https://github.com/#{GITHUB_REPO}.git
         cd rustfs

      2. Install dependencies:
         brew install rust protobuf flatbuffers pkg-conf zstd openssl@3

      3. Compile the project:
         cargo build --release

      4. The binary will be located at:
         ./target/release/rustfs

      === Additional Notes ===
      If you encounter issues with missing dependencies, ensure the following are installed:
      - Rust: brew install rust
      - Protobuf: brew install protobuf
      - Flatbuffers: brew install flatbuffers
      - OpenSSL: brew install openssl@3
      - Zstd: brew install zstd
    EOS
  end

  def test
    version_output = shell_output("#{bin}/rustfs --version")
    assert_match "rustfs #{version}", version_output
  end

  private

  def system_target
    @system_target ||= begin
                         os = OS.mac? ? "apple-darwin" : "unknown-linux-musl"
                         arch = Hardware::CPU.arch == :arm ? "aarch64" : "x86_64"
                         "#{arch}-#{os}"
                       end
  end

  def binary_url_and_sha
    target = system_target
    sha256 = BINARIES[target]
    return [nil, nil] unless sha256
    url = "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-#{target}.zip"
    [url, sha256]
  end
end