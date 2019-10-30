#!/bin/bash

set -o errexit

shopt -s nullglob

echo "Fixing links in documents"

for file in {branches,tags}/*/docs/*.md; do

    # Change .raml links to .html and rename APIs folder
    perl -pi -e 's:\.raml\):.html\):g; s:/APIs:/html-APIs:g;' "$file"

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
    
