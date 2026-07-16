#!/usr/bin/env ruby
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

require_relative 'formula_updater'

FormulaUpdater.run(
  repo: ENV.fetch('GITHUB_UPSTREAM_REPO', 'rustfs/cli'),
  formula_path: ENV.fetch('FORMULA_PATH', File.expand_path('../rc.rb', __dir__)),
  targets: [
    'macos-arm64',
    'macos-amd64',
    'linux-arm64',
    'linux-amd64',
  ],
  artifact_name: ->(target, version) { "rustfs-cli-#{target}-v#{version}.tar.gz" },
  allow_prerelease: false,
)
