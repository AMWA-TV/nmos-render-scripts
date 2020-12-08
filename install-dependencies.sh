#!/usr/bin/env bash

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

set -o errexit

[ ! -e README.md ] && echo Run this from the top-level directory && exit 1

. .scripts/get-config.sh


if [[ ! "$AMWA_ID" =~ "IS-" ]]; then
    echo Nothing to install
    exit 0
fi

rm -rf raml2html-nmos-theme
git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
cp .scripts/package.json .
yarn install
sudo pip3 install jsonref pathlib
