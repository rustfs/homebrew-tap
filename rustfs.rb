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
  VERSION = "1.0.2-preview.2".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "016c1918165813e675fa5f4c5e71a2781882ee41495f796dce02fda4fc35df48",
    "linux-aarch64-musl" => "1c7746e70bdfd33503d86665b20e83ce61c5765a63315769a0684a36450d9af5",
    "linux-x86_64-musl" => "984bdd01889f81afa35aab0534b69ea568f1b06bf5dd429c52efd6d885d6389e",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "8d5f15c90e9043bc4d46f7bc1bcdb21ca3d2cb7ac063ba46ad253a87afbde2dd"
  license "Apache-2.0"

  on_macos do
    on_arm do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-macos-aarch64-v#{VERSION}.zip"
        sha256 BINARIES["macos-aarch64"]
      end
    end
  end

  on_linux do
    on_arm do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-linux-aarch64-musl-v#{VERSION}.zip"
        sha256 BINARIES["linux-aarch64-musl"]
      end
    end

    on_intel do
      resource "binary" do
        url "https://github.com/#{GITHUB_REPO}/releases/download/#{VERSION}/rustfs-linux-x86_64-musl-v#{VERSION}.zip"
        sha256 BINARIES["linux-x86_64-musl"]
      end
    end
  end

  def install
    if system_target == "macos-x86_64"
      odie "macOS Intel (x86_64) is not supported by this formula. Install from crates.io instead: cargo install rustfs"
    end

    unless BINARIES.key?(system_target)
      odie "This formula has no pre-compiled binary for your platform: #{system_target}. Install from crates.io instead: cargo install rustfs"
    end

    ohai "Installing from pre-compiled binary..."
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

      === Alternative Installation ===
      To build and install RustFS directly from crates.io, use Cargo:
        cargo install rustfs

      Cargo resolves Rust dependencies automatically. Use a compatible Rust toolchain.
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

  # Note: Homebrew formulas must be reproducible and cannot hit the network
  # to determine versions at install time. This livecheck tells `brew livecheck`
  # to use GitHub releases to find new versions. We also provide a workflow in
  # this tap to automatically bump this formula when a new release appears.
  livecheck do
    url :stable
    strategy :github_latest
  end
end
