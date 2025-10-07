#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'digest'
require 'tempfile'

# Configuration
REPO = ENV.fetch('GITHUB_UPSTREAM_REPO', 'rustfs/rustfs')
FORMULA_PATH = ENV.fetch('FORMULA_PATH', File.expand_path('../rustfs.rb', __dir__))

TARGETS = [
  'macos-aarch64',
  'macos-x86_64',
  'linux-aarch64-musl',
  'linux-x86_64-musl'
].freeze

def http_get_json(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  token = ENV['GITHUB_TOKEN'] || ENV['HOMEBREW_GITHUB_API_TOKEN']
  req['Authorization'] = "token #{token}" if token && !token.empty?
  req['User-Agent'] = 'rustfs-homebrew-tap-updater'
  req['Accept'] = 'application/vnd.github+json'

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    res = http.request(req)
    unless res.is_a?(Net::HTTPSuccess)
      abort "GitHub API request failed: #{res.code} #{res.message} - #{res.body}"
    end
    JSON.parse(res.body)
  end
end

def http_stream_digest(url)
  uri = URI(url)
  digest = Digest::SHA256.new
  headers = {}
  token = ENV['GITHUB_TOKEN'] || ENV['HOMEBREW_GITHUB_API_TOKEN']
  headers['Authorization'] = "token #{token}" if token && !token.empty?
  headers['User-Agent'] = 'rustfs-homebrew-tap-updater'

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(uri.request_uri, headers)
    http.request(request) do |response|
      case response
      when Net::HTTPRedirection
        return http_stream_digest(response['location'])
      when Net::HTTPSuccess
        response.read_body do |chunk|
          digest.update(chunk)
        end
      else
        abort "Download failed: #{response.code} #{response.message} for #{url}"
      end
    end
  end
  digest.hexdigest
end

def latest_release(repo)
  # Fetch releases list to include prereleases (GitHub /releases/latest excludes prereleases)
  releases = http_get_json("https://api.github.com/repos/#{repo}/releases?per_page=5")
  rel = releases.find { |r| !r['draft'] }
  abort 'No releases found' unless rel
  rel
end

def normalize_version(tag_name)
  tag_name.sub(/^v/, '')
end

def artifact_name_for(target, version)
  "rustfs-#{target}-v#{version}.zip"
end

def compute_artifacts_sha_map(release, version)
  assets = release.fetch('assets', [])
  shas = {}
  TARGETS.each do |t|
    name = artifact_name_for(t, version)
    asset = assets.find { |a| a['name'] == name }
    abort "Missing asset for #{t}: expected #{name}" unless asset
    url = asset['browser_download_url']
    puts "Computing sha256 for #{name} ..."
    shas[t] = http_stream_digest(url)
  end
  shas
end

def compute_source_tarball_sha(repo, tag_or_version)
    candidates = [tag_or_version]
    candidates << "v#{tag_or_version}" unless tag_or_version.start_with?('v')

    last_error = nil
    candidates.each do |tag|
        url = "https://github.com/#{repo}/archive/refs/tags/#{tag}.tar.gz"
        puts "Computing source tarball sha256 for #{url} ..."
        begin
            return http_stream_digest(url)
        rescue SystemExit => e
            last_error = e
            warn "Failed for #{tag}, trying next candidate if any..."
            next
        end
    end
    abort("Failed to compute source tarball sha256: #{last_error}")
end

def update_formula_file(path, version, source_sha, artifacts_sha)
  content = File.read(path)
  original = content.dup

  # Update VERSION constant
  content.sub!(
    /VERSION\s*=\s*"[^"]+"\.freeze/,
    "VERSION = \"#{version}\".freeze"
  ) || abort('Failed to update VERSION')

  # Update tarball sha256 (first sha256 line with quoted hash)
  content.sub!(
    /\n\s*sha256\s*"[0-9a-f]{64}"/,
    "\n  sha256 \"#{source_sha}\""
  ) || abort('Failed to update source tarball sha256')

  # Update BINARIES map values
  artifacts_sha.each do |target, sha|
    replaced = content.sub!(
      /(\"#{Regexp.escape(target)}\"\s*=>\s*\")[0-9a-f]{64}(\")/,
      "\\1#{sha}\\2"
    )
    abort("Failed to update sha for #{target}") unless replaced
  end

  if content == original
    puts 'No changes needed.'
    return false
  end

  File.write(path, content)
  true
end

# Main
rel = latest_release(REPO)
tag = rel.fetch('tag_name')
version = normalize_version(tag)

# Persist version for CI usage
ENV['LATEST_VERSION'] = version
version_file = File.expand_path('../.latest_version', __dir__)
File.write(version_file, version)

source_sha = compute_source_tarball_sha(REPO, version)
artifacts_sha = compute_artifacts_sha_map(rel, version)

changed = update_formula_file(FORMULA_PATH, version, source_sha, artifacts_sha)
puts "Updated formula to version #{version}" if changed
exit 0
