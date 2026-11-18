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
  VERSION = "0.1.38".freeze
  GITHUB_REPO = "rustfs/cli".freeze
  BINARIES = {
    "macos-arm64" => "899939290acc6ce07254d7ead738e3be37a1decdb039cd5e131042e0125ea9fe",
    "macos-amd64" => "364ee997d726ac6fc89a9a4074d909f6b30fb2665b09fa9cd24c06af3ddaeb2d",
    "linux-arm64" => "3b4c38698174ff13844bf4a824230cb2e26930712ac3fb149dcd460934c6367c",
    "linux-amd64" => "9741028f46f5f5a152da1e3257980e9c7be2714c21b5b14a8bb5ac7d93f882e9",
  }.freeze

  desc "A S3-compatible command-line client written in Rust."
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/v#{VERSION}.tar.gz"
  sha256 "4ea2da587f809e9ba5076c0a3c3683306dd4d4799072a4d693a184bfa29d3916"
  license "Apache-2.0 or MIT"

  on_macos do
    on_arm do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/v#{VERSION}/rustfs-cli-macos-arm64-v#{VERSION}.tar.gz"
        sha256 BINARIES["macos-arm64"]
      end
    end

    on_intel do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/v#{VERSION}/rustfs-cli-macos-amd64-v#{VERSION}.tar.gz"
        sha256 BINARIES["macos-amd64"]
      end
    end
  end

  on_linux do
    on_arm do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/v#{VERSION}/rustfs-cli-linux-arm64-v#{VERSION}.tar.gz"
        sha256 BINARIES["linux-arm64"]
      end
    end

    on_intel do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/v#{VERSION}/rustfs-cli-linux-amd64-v#{VERSION}.tar.gz"
        sha256 BINARIES["linux-amd64"]
      end
    end
  end

  def install
    odie "This formula has no pre-compiled binary for your platform: #{system_target}" unless BINARIES.key?(system_target)

    ohai "Installing from pre-compiled binary..."
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
         cargo build --release -p rustfs-cli

      3. The binary will be located at:
         ./target/release/rc

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

  # Note: Homebrew formulas must be reproducible and cannot hit the network
  # to determine versions at install time. This livecheck tells `brew livecheck`
  # to use GitHub releases to find new versions. We also provide a workflow in
  # this tap to automatically bump this formula when a new release appears.
  livecheck do
    url :stable
    strategy :github_latest
  end
end
