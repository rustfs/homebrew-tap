class Rustfs < Formula
  VERSION = "1.0.0-alpha.37".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "c7d1d5b060fad53ea3c9eac9deb6d1ea20a22d441ec3494cd5a18fe6f7bbb215",
    "macos-x86_64" => "c0a5e9973a89258d3b8a28afd957d36c3fdef2f664dab4647a29c0501f062ab0",
    "linux-aarch64-musl" => "6b1df01356be386ea4b7b48c54039d784c5253f1f66f3880ce325fae43678d54",
    "linux-x86_64-musl" => "2da23771792881a82109a3669ed4f882af5061bc05734ccf9619ba815e9f33ac",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "b8962ae1cded089ae0d59b11afabe1015646d006124156bc7ac1cb9773b9e1ae"
  license "Apache-2.0"

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
         brew install rust protobuf flatbuffers pkg-config zstd openssl@3

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
    version_output = shell_output("#{bin}/rustfs -V")
    assert_match "rustfs #{VERSION}", version_output
  end

  private

  def system_target
    @system_target ||= begin
                         os = OS.mac? ? "macos" : "linux"
                         arch = case Hardware::CPU.arch
                                when :arm, :aarch64 then "aarch64"
                                else "x86_64"
                                end
                         suffix = OS.mac? ? "" : "-musl"
                         "#{os}-#{arch}#{suffix}"
                       end
  end

  def binary_url_and_sha
    target = system_target
    sha256 = BINARIES[target]
    return [nil, nil] unless sha256
    url = "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-#{target}-v#{VERSION}.zip"
    [url, sha256]
  end
end