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
  VERSION = "1.0.1".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "18aac7101c3484b98f93de64a0609aaa8e02aba072ba7927172c4b2eae7d4843",
    "linux-aarch64-musl" => "d2533e293204597416cb8d30790ea35df14cb4521633fa3574c64333141bafdf",
    "linux-x86_64-musl" => "a834096dafa1f1a55825a2cdaf49d006a193978d344f2d508c2be475133738a3",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "612ae16743723de917d9c8aadfe06aac8516bd9cc2f648d2679128561cb1fe28"
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
