# Copyright 2024 RustFS Team
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Rustfs < Formula
  VERSION = "1.0.0-beta.6".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "96ef7155f62e0ee83941e941466317d8bccf93d11a17e1903033eacbdb5933a2",
    "macos-x86_64" => "8d1a6c3fec88a5efd50e92a20a643c779049ab3a6f09b0b536c659993954eea0",
    "linux-aarch64-musl" => "67134f0193034e5246fce7ceb7130ce2f594e25f4b80c69140f7266c764c3e8b",
    "linux-x86_64-musl" => "e2dfa35259a65f3635f754af8414e79486d5b1134ddf901252a7a9444ba7b4cc",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "371f570caf17a97ba5c7b3a83ad95f00adfeb9bf91026305ed81057ef1da63eb"
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
                                when :arm, :arm64, :aarch64 then "aarch64"
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
