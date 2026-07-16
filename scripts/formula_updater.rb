# frozen_string_literal: true
#
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

require 'digest'
require 'json'
require 'net/http'
require 'uri'

module FormulaUpdater
  module_function

  def run(config)
    release = latest_release(config)
    tag = release.fetch('tag_name')
    version = normalize_version(tag)

    write_version_file(version)

    source_sha = compute_source_tarball_sha(config.fetch(:repo), version)
    artifact_shas = compute_artifact_sha_map(release, version, config)

    changed = update_formula_file(config.fetch(:formula_path), version, source_sha, artifact_shas)
    puts "Updated formula to version #{version}" if changed
  end

  def latest_release(config)
    repo = config.fetch(:repo)
    releases = http_get_json("https://api.github.com/repos/#{repo}/releases?per_page=20")
    allow_prerelease = env_bool('ALLOW_PRERELEASE', default: config.fetch(:allow_prerelease, true))

    release = releases.find do |candidate|
      next false if candidate['draft']
      next false if candidate['prerelease'] && !allow_prerelease

      release_has_required_assets?(candidate, normalize_version(candidate.fetch('tag_name')), config)
    end

    abort "No release found with all required assets for #{repo}" unless release
    release
  end

  def release_has_required_assets?(release, version, config)
    asset_names = release.fetch('assets', []).map { |asset| asset['name'] }
    missing = config.fetch(:targets).each_with_object([]) do |target, list|
      name = config.fetch(:artifact_name).call(target, version)
      list << name unless asset_names.include?(name)
    end

    return true if missing.empty?

    warn "Skipping #{release.fetch('tag_name')}: missing #{missing.join(', ')}"
    false
  end

  def normalize_version(tag_name)
    tag_name.sub(/^v/, '')
  end

  def compute_artifact_sha_map(release, version, config)
    assets = release.fetch('assets', [])
    shas = {}

    config.fetch(:targets).each do |target|
      name = config.fetch(:artifact_name).call(target, version)
      asset = assets.find { |candidate| candidate['name'] == name }
      abort "Missing asset for #{target}: expected #{name}" unless asset

      shas[target] = asset_sha(asset)
    end

    shas
  end

  def asset_sha(asset)
    digest = asset['digest']
    return digest.delete_prefix('sha256:') if digest&.start_with?('sha256:')

    url = asset.fetch('browser_download_url')
    puts "Computing sha256 for #{asset.fetch('name')} ..."
    http_stream_digest(url)
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
      end
    end

    abort("Failed to compute source tarball sha256: #{last_error}")
  end

  def update_formula_file(path, version, source_sha, artifact_shas)
    content = File.read(path)
    original = content.dup

    content.sub!(
      /VERSION\s*=\s*"[^"]+"\.freeze/,
      "VERSION = \"#{version}\".freeze"
    ) || abort('Failed to update VERSION')

    content.sub!(
      /\n\s*sha256\s*"[0-9a-f]{64}"/,
      "\n  sha256 \"#{source_sha}\""
    ) || abort('Failed to update source tarball sha256')

    artifact_shas.each do |target, sha|
      replaced = content.sub!(
        /("#{Regexp.escape(target)}"\s*=>\s*")[0-9a-f]{64}(")/,
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

  def write_version_file(version)
    ENV['LATEST_VERSION'] = version
    version_file = File.expand_path('../.latest_version', __dir__)
    File.write(version_file, version)
  end

  def http_get_json(url)
    uri = URI(url)
    req = Net::HTTP::Get.new(uri)
    token = ENV['GITHUB_TOKEN'] || ENV['HOMEBREW_GITHUB_API_TOKEN']
    req['Authorization'] = "token #{token}" if token && !token.empty?
    req['User-Agent'] = 'rustfs-homebrew-tap-updater'
    req['Accept'] = 'application/vnd.github+json'

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      res = http.request(req)
      abort "GitHub API request failed: #{res.code} #{res.message} - #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    end
  end

  def http_stream_digest(url)
    uri = URI(url)
    digest = Digest::SHA256.new
    headers = { 'User-Agent' => 'rustfs-homebrew-tap-updater' }
    token = ENV['GITHUB_TOKEN'] || ENV['HOMEBREW_GITHUB_API_TOKEN']
    headers['Authorization'] = "token #{token}" if token && !token.empty?

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      http.request(request) do |response|
        case response
        when Net::HTTPRedirection
          return http_stream_digest(response['location'])
        when Net::HTTPSuccess
          response.read_body { |chunk| digest.update(chunk) }
        else
          abort "Download failed: #{response.code} #{response.message} for #{url}"
        end
      end
    end

    digest.hexdigest
  end

  def env_bool(name, default:)
    value = ENV[name]
    return default if value.nil? || value.empty?

    %w[1 true yes on].include?(value.downcase)
  end
end
