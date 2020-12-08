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

# TODO: just read _config.yml once!

_CONFIG_YML=_config.yml

if [ ! -f $_CONFIG_YML ]; then
    echo Cannot find $_CONFIG_YML >&2 
    exit 1
else
    echo Getting config from $_CONFIG_YML
fi

AMWA_ID="$(awk '/amwa_id/ { print $2 }' $_CONFIG_YML)"
REPO_ORIGIN="$(git remote get-url origin)"
REPO_ADDRESS="${REPO_ORIGIN%.git}"
DEFAULT_TREE="$(awk '/default_tree:/ { print $2 }' $_CONFIG_YML)"
SHOW_TAGS="$(awk '/show_tags:/ { print $2 }' $_CONFIG_YML)"
SHOW_BRANCHES="$(awk '/show_branches:/ { print $2 }' $_CONFIG_YML)"
