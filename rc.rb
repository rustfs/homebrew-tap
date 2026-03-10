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

class Rc < Formula
  VERSION = "0.1.7".freeze
  GITHUB_REPO = "rustfs/cli".freeze
  BINARIES = {
    "macos-arm64" => "d4637a4817d86a1c62f208e6131f3f2914014d334bf9f7d734076da367242e8e",
    "macos-amd64" => "8999f57504622301d8d24b0e1193c26173352a4b459d98073780af0e0a665836",
    "linux-arm64" => "ad5cfdbc874bee55868635026aff024d3a75552be5d68d6d761296a9ddfe87cd",
    "linux-amd64" => "ab3dfa2daf7370a1f3162f7b12dd70b98c5eb64ed7ee7d8f3ad217e96a0a0c64",
  }.freeze

  desc "A S3-compatible command-line client written in Rust."
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/v#{VERSION}.tar.gz"
  sha256 "d60deac99bc77fc5379f6b4f57297739b3610f03457ae8384f8370036f385b8d"
  license "Apache-2.0 or MIT"

  def install
    url, sha = binary_url_and_sha
    odie "This formula has no pre-compiled binary for your platform: #{system_target}" unless url

    ohai "Installing from pre-compiled binary..."
    resource "binary" do
      url url
      sha256 sha
    end

    resource("binary").stage do
      bin.install "rc"
    end
  end

  def caveats
    <<~EOS
      Thank you for installing rustfs-cli alias rc!

      === Quick Start ===
      # View all available commands and help information:
      rc --help

      # Check the version:
      rc --version

      === Developer Guide ===
      If you want to build from source manually:

      1. Clone the repository:
         git clone https://github.com/#{GITHUB_REPO}.git
         cd cli

      2. Compile the project:
         cargo build --release

      4. The binary will be located at:
         ./target/release/cli

      === Additional Notes ===
      If you encounter issues with missing dependencies, ensure the following are installed:
      - Rust toolchain (install via Homebrew or from https://rustup.rs/)
    EOS
  end

  def test
    version_output = shell_output("#{bin}/rc -V")
    assert_match "rc #{VERSION}", version_output
  end

  private

  def system_target
    @system_target ||= begin
                         os = OS.mac? ? "macos" : "linux"
                         arch = case Hardware::CPU.arch
                                when :arm, :arm64, :aarch64 then "arm64"
                                else "amd64"
                                end
                         "#{os}-#{arch}"
                       end
  end

  def binary_url_and_sha
    target = system_target
    sha256 = BINARIES[target]
    return [nil, nil] unless sha256
    url = "https://github.com/#{GITHUB_REPO}/releases/download/v#{VERSION}/rustfs-cli-#{target}-v#{VERSION}.tar.gz"
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
