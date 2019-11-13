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

echo "Fixing links in documents"

for file in {branches,tags}/*/docs/*.md; do

    # Change .raml links to .html and rename APIs folder
    perl -pi -e 's:\.raml\):.html\):g; s:/APIs:/html-APIs:g;' "$file"

    # Change .json links to .html and use with-refs for schemas
    perl -pi -e 's:\.json\):.html\):g; s:/html-APIs/schemas:/html-APIs/schemas/with-refs:g;' "$file"

    # Change %20 escaped spaces in links to understores
    perl -ni -e '@parts = split /(\(.*?\.md\))/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$file"

    # Same but for reference links
    perl -ni -e '@parts = split /(\]:.*?\.md)/ ; for ($n = 1; $n < @parts; $n += 2) { $parts[$n] =~ s/%20/_/g; }; print @parts' "$file"

    # For other repos, link to documentation
    perl -pi -e 's:github\.com/AMWA-TV/:amwa-tv.github.io/:gi;' "$file"
done

# Removing the unwanted "schemas/" in .html links due to raml2html v6 workaround
# for file in {branches,tags}/*/html-APIs/*.html; do
#     perl -pi -e 's:schemas/::g;' "$file"
# done
    
