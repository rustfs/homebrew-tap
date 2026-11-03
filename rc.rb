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
  VERSION = "0.1.37".freeze
  GITHUB_REPO = "rustfs/cli".freeze
  BINARIES = {
    "macos-arm64" => "6e50068052314e45dc0048c2d6e218704c282659f11f9b6826b8e024536d9ee5",
    "macos-amd64" => "c2040e10a845af300ec90026648eeb3c566a3560bc77a455e9d3f1100b7426ac",
    "linux-arm64" => "a02091205fe4d9fbf0d16a0dac3d46ad7fac7d5266024b5b17e76327a4e88aa8",
    "linux-amd64" => "31e79fe7697c870e60f5b5c9008adbb3ad5af7f9f2ab45a3d68585c5f87238d1",
  }.freeze

  desc "A S3-compatible command-line client written in Rust."
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/v#{VERSION}.tar.gz"
  sha256 "365638c9fad6b675f7e6201031ba716a1f9b1f891af1998cc26de762be91af7a"
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
