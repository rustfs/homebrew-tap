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
  VERSION = "1.0.5".freeze
  GITHUB_REPO = "rustfs/rustfs".freeze
  BINARIES = {
    "macos-aarch64" => "7c568946ab86df54bb3a7fffee66b4d05896219bec6629f0f7e6366aa69a26ac",
    "linux-aarch64-musl" => "082834d38167f2fa581e98d14a7126e3e203153e38ae5882eca8d02a4207d12f",
    "linux-x86_64-musl" => "3d9d42bb4cb7a1589266090d4f9f8238465506cdd9d5e897193377dd6f610aac",
  }.freeze

  desc "High-performance distributed object storage written in Rust"
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/#{VERSION}.tar.gz"
  sha256 "c9772a08ca85727483c890b2bffede6ff8dd064caa407931b0391cb4c65eb3b6"
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
