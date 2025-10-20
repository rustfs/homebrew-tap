class Rustfs < Formula
  VERSION = "1.0.0-alpha.64".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "b7471afd21e966b458473fe958fa0f93a8d5418ac19ae27e17163e9db34522fd",
    "macos-x86_64" => "b83b456aa6422c96105f85a492a5b5b089a1b56b2ef3344557e20268a0f9acd7",
    "linux-aarch64-musl" => "9da38d3cb349900772ee4368a20d0d5879222e54678ca2dd9627e4b78f5d87ab",
    "linux-x86_64-musl" => "c84c9e3f88dafc2115b2a5830e48f4bf9ad32ba112cc2b70221cc7a4a73a77f1",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "bd2ca1bd5e2a303672bd3d5b91aca0511e091a469bdc3621d253cf52869c04c7"
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

  # Note: Homebrew formulas must be reproducible and cannot hit the network
  # to determine versions at install time. This livecheck tells `brew livecheck`
  # to use GitHub releases to find new versions. We also provide a workflow in
  # this tap to automatically bump this formula when a new release appears.
  livecheck do
    url :stable
    strategy :github_latest
  end
end
