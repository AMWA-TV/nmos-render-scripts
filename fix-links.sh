#!/bin/bash

# Copyright 2019 British Broadcasting Corporation
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

shopt -s nullglob

. .scripts/get-config.sh

echo "Fixing links in documents"

function process_file {
    # Change .raml links to .html and rename APIs folder
    perl -pi -e 's:\.raml\):.html\):g; s:/APIs:/html-APIs:g;' "$1"

    # Change .json links to .html and use with-refs for schemas
    perl -pi -e 's:\.json\):.html\):g; s:/html-APIs/schemas:/html-APIs/schemas/with-refs:g;' "$1"

    # Change %20 escaped spaces in links to understores. Allow for possible #target-in-page links.
    perl -ni -e '@parts = split /(\(.*?\.md(?:#.*\b)?\))/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$1"

    # Same but for reference links
    perl -ni -e '@parts = split /(\]:.*?\.md(?:#.*\b)?)/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$1"

    # For other repos, link to documentation
    #perl -pi -e 's:github\.com/AMWA-TV/:amwa-tv.github.io/:gi;' "$1" 
}

# NMOS* and BCP-* repos have docs in the main dir, not docs/
if [[ "$AMWA_ID" == "NMOS" || "$AMWA_ID" =~ "BCP-" ]]; then
    for file in {branches,tags}/*/*.md index.md; do
        process_file "$file"
    done

# NMOS-PARAMETER-REGISTERS has individual dir for each register
elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
    for file in {branches,tags}/*/*/*.md index.md; do
        process_file "$file"
    done

# Other repos have docs/, APIs/, examples/
else
    for file in {branches,tags}/*/docs/*.md; do
        process_file "$file"
    done
fi

# Special case: relative links that need to go to the repo not the pages
if [[ "$AMWA_ID" == "NMOS-TESTING" ]]; then

    function rewrite_link {
        perl -pi -e "s~\]\($1~]($2~g;" $3
    }

    for tree in {branches,tags}/*; do
        linkto="$REPO_ADDRESS/blob/${tree##*/}"
        cd $tree
            for file in docs/*.md; do
                rewrite_link "../testssl/" "${linkto}/testssl/" "$file"
                rewrite_link "../test_data/" "${linkto}/test_data/" "$file"
            done
        cd ../..
    done
fi
