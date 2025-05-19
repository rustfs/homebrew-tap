class RustFS < Formula
  desc "A command-line tool for Object written in Rust"
  homepage "https://github.com/rustfs/s3-rustfs"
  url "https://github.com/rustfs/s3-rustfs/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "replace_with_actual_sha256"
  license " Apache-2.0" # Replace with the actual license, such as MIT or Apache-2.0

  # Supports building from the latest Git code (optional)
  head "https://github.com/rustfs/s3-rustfs.git", branch: "main"

  # Depend on the Rust compiler
  depends_on "rust" => :build

  def install
    # Build and install with cargo
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Test whether the installation is successful
    assert_match "rustfs 0.1.0", shell_output("#{bin}/rustfs --version")
  end
end
