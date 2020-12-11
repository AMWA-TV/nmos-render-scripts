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

. $(dirname ${BASH_SOURCE[0]})/get-config.sh

set -o errexit

# TODO: Move some of the common/looped code into functions (DRY)

shopt -s nullglob

# Text in this file will appear at the start of the top-level index
INTRO=intro.md
INTRO_COMMON=.scripts/intro_common.md

# Filename for index in each dir
INDEX=index.md

function add_unnumbered_doc {
    doc=$1

    # Spaces causing problems so rename extracted docs to use underscore
    underscore_space_doc="${doc// /_}"
    [[ "$underscore_space_doc" != "$doc" ]] && mv "$doc" "$underscore_space_doc"

    # [[ "$INDEX_DOCS" ]] && echo "${indent}- [$linktext](${underscore_space_doc##*/})" >> "$INDEX_DOCS"
    [[ "$INDEX_DOCS" ]] && echo "- [$linktext](${underscore_space_doc##*/})" >> "$INDEX_DOCS"
    echo "- [${doc%%.md}]($underscore_space_doc)" >> "$INDEX"
};

function add_numbered_doc {
    doc=$1

    no_ext="${doc%%.md}"
    # Spaces causing problems so rename extracted docs to use underscore
    underscore_space_doc="${doc// /_}"
    [[ "$underscore_space_doc" != "$doc" ]] && mv "$doc" "$underscore_space_doc"

    # Top level documents have numbers ending in '.0' or '.0.'
    match_top_level='^docs/[1-9][0-9]*\.0\.? '
    if [[ "$doc" =~ $match_top_level ]]; then
        indent=""
        linktext="${no_ext#* }"
    else
        # Removing the top-level part of lower-level link texts
        # that is the part up to the hyphen and following space
        indent="  "
        if [[ $no_ext =~ " - " ]]; then
            linktext="${no_ext#* - }"
        else
            linktext="${no_ext#* }" # no hyphen
        fi
    fi
    [[ "$INDEX_DOCS" ]] && echo "${indent}- [$linktext](${underscore_space_doc##*/})" >> "$INDEX_DOCS"
    echo "${indent}- [$linktext]($underscore_space_doc)" >> "$INDEX"
}

function add_possibly_nested_example {
    example=$1

    # Spaces causing problems so rename extracted docs to use underscore
    underscore_space_doc="${doc// /_}"
    [[ "$underscore_space_doc" != "$doc" ]] && mv "$doc" "$underscore_space_doc"

    [[ "$INDEX_DOCS" ]] && echo "${indent}- [$linktext](${underscore_space_doc##*/})" >> "$INDEX_DOCS"
    echo "- [${doc%%.md}]($underscore_space_doc)" >> "$INDEX"
};

function do_b_or_t {
    b_or_t=$1
    label=$2
    
    echo "Processing $b_or_t $INDEX..."
    cd "$b_or_t"
    for dir in */; do
        dirname="${dir%%/}"
        echo "Making $dirname/$INDEX"
        cd "$dir"

            # These repos have unnumbered docs in the main dir
            if [[ "$AMWA_ID" == "NMOS" || "$AMWA_ID" == "BCP-002" || "$AMWA_ID" == "BCP-003" ]]; then
                for doc in *.md; do
                    if [[ "$doc" != "index.md" &&
                          "$doc" != "README.md" &&
                          "$doc" != "CHANGELOG.md" &&
                          "$doc" != "CONTRIBUTING.md" ]]; then
                        add_unnumbered_doc "$doc"
                    fi
                done

            # NMOS-PARAMETER-REGISTERS has individual dir for each register
            elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
                for reg in common device-control-types device-types formats node-service-types tags transports capabilities; do
                    [[ -d $reg ]] && echo "- [$reg]($reg)" >> "$INDEX"
                done

            # NMOS-TESTING has numbered docs in docs/
            elif [[ "$AMWA_ID" == "NMOS-TESTING" ]]; then
                if [ -d docs ]; then
                    INDEX_DOCS="docs/$INDEX"
                    for doc in docs/[1-9]*.md; do
                        add_numbered_doc "$doc"
                    done
                fi

            # Other repos may have numbered docs/, APIs/, APIs/schemas/, examples/
            else
                if [ -d docs ]; then
                    INDEX_DOCS="docs/$INDEX"
                    echo -e "\n## Documentation for $label $dirname\n" >> "$INDEX"
                    echo -e "## Documentation for $label $dirname\n" >> "$INDEX_DOCS"
                    for doc in docs/[1-9]*.md; do
                        add_numbered_doc "$doc"
                    done
                fi

                if [ -d APIs ]; then
                    INDEX_APIS="APIs/$INDEX"
                    echo -e "\n## APIs for $label $dirname\n" >> "$INDEX"
                    echo -e "## APIs for $label $dirname\n" > "$INDEX_APIS"
                    for api in APIs/*.html; do
                        no_ext="${api%%.html}"
                        linktext="${no_ext##*/}"
                        echo "- [$linktext](${api##*/})" >> "$INDEX_APIS"
                        echo "- [$linktext]($api)" >> "$INDEX"
                    done
                fi

                if [ -d APIs/schemas ]; then
                    INDEX_SCHEMAS="APIs/schemas/$INDEX"
                    echo -e "\n### [JSON Schemas](APIs/schemas/)\n" >> "$INDEX"
                    echo -e "## JSON Schemas for $label $dirname\n" > "$INDEX_SCHEMAS"
                    for schema in APIs/schemas/with-refs/*.html; do
                        no_ext="${schema%%.html}"
                        linktext="${no_ext##*/}"
                        echo "- [$linktext](with-refs/$linktext.html) [(flattened)](resolved/$linktext.html)" >> "$INDEX_SCHEMAS"
                    done
                fi

                if [ -d examples ]; then
                    INDEX_EXAMPLES="examples/$INDEX"
                    echo -e "\n### [Examples](examples/)\n" >> "$INDEX"
                    echo -e "## Examples for $label $dirname\n" > "$INDEX_EXAMPLES"
                    for example in examples/*.html; do
                        no_ext="${example%%.html}"
                        linktext="${no_ext##*/}"
                        echo "- [$linktext](${example##*/})" >> "$INDEX_EXAMPLES"
                    done
                fi

            fi

            cd ..
    done
    cd ..
}

do_b_or_t branches branch

# NMOS-PARAMETER-REGISTERS has NO GIT TAGS (see comment in extract-docs.sh)
if [[ "$AMWA_ID" != "NMOS-PARAMETER-REGISTERS" ]]; then
    do_b_or_t tags release/tag
fi

echo "Making top level $INDEX"

# Add lint and render status badges
ci_url="${REPO_ADDRESS/github.com/travis-ci.com}"
default_branch="$(git remote show origin | awk '/HEAD branch/ { print $3 }')"
cat << EOF > "$INDEX"
| Repository | Default Branch | Lint (default) | Render (all) |
| --- | --- | --- | --- |
| [${REPO_ADDRESS##*/}]($REPO_ADDRESS) \
| $default_branch \
| <a href="${ci_url}?branch=${default_branch}"><img src="${ci_url}.svg?branch=${default_branch}" width="100"/></a> \
| <a href="${ci_url}?branch=gh-pages"><img src="${ci_url}.svg?branch=gh-pages" width="100"/></a> \
|
EOF

# Repo-specific About: section...
echo -e "\n\n---\n\n## About ${AMWA_ID}\n\n" >> "$INDEX"
cat "$INTRO" >> "$INDEX"
echo -e "\n\n---\n\n" >> "$INDEX"

# Heading/intro depends on repo type
if [[ "$AMWA_ID" == "NMOS" || "$AMWA_ID" == "BCP-003" || "$AMWA_ID" == "NMOS-TESTING" ]]; then
    echo "## Documentation" >> "$INDEX"
elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
    echo "## Parameter Registers" >> "$INDEX"
elif [[ "$AMWA_ID" == "BCP-002" ]]; then
    echo "## Best Current Practice document" >> "$INDEX"
else
    # Common intro for specs
    sed "s~%AMWA_ID%~${AMWA_ID}~g; s~%REPO_ADDRESS%~${REPO_ADDRESS}~g; s~%DEFAULT_TREE%~${DEFAULT_TREE}~g" "$INTRO_COMMON" >> "$INDEX"
fi

# Add the default links at the top - correct the links while copying text
if [ "$DEFAULT_TREE" ]; then
    echo "Adding in contents of $INDEX for default tree $DEFAULT_TREE"
    sed "s:(:($DEFAULT_TREE/:" "$DEFAULT_TREE/$INDEX" >> "$INDEX"
fi

# TODO: DRY on the following...


# These excluded repos don't have branch and tags indexes
if [[ ! "$AMWA_ID" == "NMOS" && ! "$AMWA_ID" == "BCP-002" && ! "$AMWA_ID" == "BCP-003" ]]; then
    echo Adding branches index...
    INDEX_BRANCHES="branches/index.md"
    # Parameter Registers use branches for published and dev versions
    if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
        echo "## Branches" > "$INDEX_BRANCHES"
        echo -e "\n## Branches" >> "$INDEX"
    else
        echo "## Development Branches" > "$INDEX_BRANCHES"
        echo -e "\n## Development Branches" >> "$INDEX"
    fi
    for dir in branches/*; do
        [ ! -d $dir ] && continue
        branch="${dir##*/}"
        echo -e "\n[$branch](branches/$branch/)" >>  "$INDEX"
        echo -e "\n[$branch]($branch/)" >>  "$INDEX_BRANCHES"
    done

    # No tags for Parameter Registers
    if [[ "$AMWA_ID" != "NMOS-PARAMETER-REGISTERS" ]]; then
        echo Adding tags index...
        INDEX_TAGS="tags/index.md"
        echo "## Published Releases/Tags" > "$INDEX_TAGS"
        echo -e "\n##  Published Releases/Tags" >> "$INDEX"
        for dir in tags/*; do
            [ ! -d $dir ] && continue
            tag="${dir##*/}"
            echo -e "\n[$tag](tags/$tag/)" >>  "$INDEX"
            echo -e "\n[$tag]($tag/)" >>  "$INDEX_TAGS"
        done
    fi

fi

echo Adding warnings and project description to each autogenerated file...
find . -name "$INDEX" -exec perl -pi -e 'print "<!-- AUTOGENERATED FILE: DO NOT EDIT -->\n\n# {{ site.github.project_tagline }}\n\n" if $. == 1' {} \;
