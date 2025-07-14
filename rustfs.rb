class Rustfs < Formula
  desc "A command-line tool for Object written in Rust"
  homepage "https://rustfs.com"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/rustfs/rustfs/releases/download/1.0.0-alpha.17/rustfs-aarch64-apple-darwin.zip"
      sha256 "ac6bee72fb24fab611bdc7c427b7c174c86d543d1ec7c58cb7eeb89fe62d671d"
    else
      url "https://github.com/rustfs/rustfs/releases/download/1.0.0-alpha.17/rustfs-x86_64-apple-darwin.zip"
      sha256 "8e30fb72a59f0a657c8f4eecde69485596cb83d6eb831e54515a81b5d0b6d071"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/rustfs/rustfs/releases/download/1.0.0-alpha.17/rustfs-aarch64-unknown-linux-musl.zip"
      sha256 "0c332a1c9f05330ac24598dd29ddc15819c5a5783b8e95ef513a7fa3921675b1"
    else
      url "https://github.com/rustfs/rustfs/releases/download/1.0.0-alpha.17/rustfs-x86_64-unknown-linux-gnu.zip"
      sha256 "96081fa567496aa95c755cc4ff8e3366adc7f7da9db72525e18a57bf5b44d607"
    end
  end

  license "Apache-2.0"
  head "https://github.com/rustfs/rustfs.git", branch: "main"

  def install
    bin.install "rustfs"
  end

  def caveats
    <<~EOS
      Thank you for installing RustFS!

      You can get started with the following command:

      # View all available commands and help information
      rustfs --help

      # (Add more specific usage examples here)
      # For example: rustfs <subcommand> [options]
    EOS
  end

  test do
    assert_match "rustfs", shell_output("#{bin}/rustfs --version")
  end
end