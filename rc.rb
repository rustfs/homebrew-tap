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
  VERSION = "0.1.20".freeze
  GITHUB_REPO = "rustfs/cli".freeze
  BINARIES = {
    "macos-arm64" => "c8aee6a739b5612e691e7b860a883f2074f4278ce07112f71c2df04861485327",
    "macos-amd64" => "882b5201354030fef88fc703f93e3f8be7545d5a661ac760ac6bb666ab17706e",
    "linux-arm64" => "8f884fa6298d1389be9bcab25a17b001e9785d2264af116d0d04493090c9b675",
    "linux-amd64" => "0520809369863ad583ec380f446f913398657d0beab0d80f64e9cba845a499f1",
  }.freeze

  desc "A S3-compatible command-line client written in Rust."
  homepage "https://rustfs.com"
  url "https://github.com/#{GITHUB_REPO}/archive/refs/tags/v#{VERSION}.tar.gz"
  sha256 "7de945b294c3f51076d1cf4daa7439f45673092ef8d27cf7f011d8a703b0498e"
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
