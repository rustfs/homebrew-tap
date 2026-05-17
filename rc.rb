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
  VERSION = "0.1.16".freeze
  GITHUB_REPO = "rustfs/cli".freeze
  BINARIES = {
    "macos-arm64" => "002e94f5f44b4b92ba8fe3a9a986deadcb79e03aa1aa4333a889c59d2b164a8a",
    "macos-amd64" => "262614dddb58086ad601bb7b59944cd59da44d83ac93853834e443e2b7ea5633",
    "linux-arm64" => "ec603f69daad0a64651eee10812c1873d28d8e8c4f73448670692ea76fa70830",
    "linux-amd64" => "2c5e4e6177fb9d8c9a4a64b338471c9f7e1f759d4b5af2eed018d630050f9cd2",
  }.freeze

  desc "A S3-compatible command-line client written in Rust."
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/v#{VERSION}.tar.gz"
  sha256 "7c7f7ea9b5d22bf5593934fe377cec10d6dafe3f2c7e23fe467a127abc6a6844"
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
