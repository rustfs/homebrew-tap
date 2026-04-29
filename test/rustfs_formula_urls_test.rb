# frozen_string_literal: true

require 'minitest/autorun'

class RustfsFormulaUrlsTest < Minitest::Test
  FORMULA = File.expand_path('../rustfs.rb', __dir__)

  def formula
    @formula ||= File.read(FORMULA)
  end

  def test_source_archive_uses_prefixed_release_tag
    assert_includes formula, 'archive/refs/tags/v#{VERSION}.tar.gz'
  end

  def test_binary_download_uses_prefixed_release_tag
    assert_includes formula, 'releases/download/v#{VERSION}/rustfs-#{target}-v#{VERSION}.zip'
  end
end
