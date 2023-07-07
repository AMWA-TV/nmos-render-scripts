#!/usr/bin/env bash

# Copyright 2021 British Broadcasting Corporation
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

shopt -s globstar nullglob

# shellcheck source=get-config.sh
. .scripts/get-config.sh

echo "Fixing links in documents"

function process_file {
    # Fix overview links
    perl -pi -e 's~https://github.com/AMWA-TV/nmos/blob/master/NMOS%20Technical%20Overview.md~https://specs.amwa.tv/nmos/branches/main/docs/2.0._Technical_Overview.html~gi;' "$1" 

    # Change .raml links to .html
    perl -pi -e 's:\.raml\):.html\):g;' "$1"

    # Change .webidl links to .html
    perl -pi -e 's:\.webidl\):.html\):g;' "$1"

    # Change .json links to .html and use with-refs for schemas (but not for schema indexes)
    if [ "${1##*/}" != "index.md" ]; then
        perl -pi -e 's:\.json\):.html\):g; s:/APIs/schemas/([^)]+):/APIs/schemas/with-refs/$1:g;' "$1"
    fi

    # Change %20 escaped spaces in links to underscores. Allow for possible #target-in-page links.
    perl -ni -e '@parts = split /(\(.*?\.md(?:#.*\b)?\))/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$1"

    # Same but for reference links
    perl -ni -e '@parts = split /(\]:.*?\.md(?:#.*\b)?)/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$1"

    # Change .md links to .html
    perl -pi -e 's:\.md\):.html\):g;' "$1"

    # Replace any copyright with blank line (because it is added in a footer)
    perl -pi -e 's:_\(c\) AMWA.*_$::' "$1"

    # Workaround for https://github.com/rouge-ruby/rouge/issues/1704
    perl -pi -e 's:^```http:```:' "$1"
}

for file in index.md {branches,releases}/**/*.md; do
    process_file "$file"
done

# Special case: relative links that need to go to the repo not the pages
if [[ "$AMWA_ID" == "NMOS-TESTING" ]]; then

    function rewrite_link {
        perl -pi -e "s~\]\($1~]($2~g;" "$3"
   }

    rewrite_link docs/ branches/master/docs/ index.md

    for tree in {branches,releases}/*; do
        [[ ! -d "$tree" ]] && continue

        linkto="$REPO_ADDRESS/blob/${tree##*/}"
        (
        cd "$tree"
            for file in docs/*.md; do
                rewrite_link "../testssl/" "${linkto}/testssl/" "$file"
                rewrite_link "../test_data/" "${linkto}/test_data/" "$file"
            done
        )
    done
fi
