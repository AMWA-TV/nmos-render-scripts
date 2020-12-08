# Copyright 2020 British Broadcasting Corporation
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
# This file is sourced from build scripts
# It now pulls in settings from _config.yml

.PHONY: build source-repo docs indexes fix-links layouts server push clean

build: source-repo docs indexes fix-links layouts

source-repo:
	.scripts/get-source-repo.sh

docs:
	.scripts/extract-docs.sh

indexes:
	.scripts/make-indexes.sh

fix-links:
	.scripts/fix-links.sh

layouts:
	.scripts/make-layouts.sh

server:
	.scripts/run-server.sh

push:
	.scripts/push-to-github.sh

clean:
	.scripts/make-clean.sh
