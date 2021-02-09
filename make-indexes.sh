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

# shellcheck source=get-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/get-config.sh"

set -o errexit

# TODO: Move some of the common/looped code into functions (DRY)

shopt -s nullglob

# Text in this file will appear at the start of the top-level index
README=../README.md
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

function do_tree {
    tree=$1
    label=$2 # because of spelling of plurals
    
    echo "Processing $tree $INDEX..."
    (
        cd "$tree" || exit 1
        for dir in */; do
            dirname="${dir%%/}"
            echo "Making $dirname/$INDEX"
            (
                cd "$dir" || exit 1

                if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
                    for reg in common device-control-types device-types formats node-service-types tags transports; do
                        echo "- [$reg]($reg)" >> "$INDEX"
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
                    if [[ "$label" == "branch" && "$dirname" == "main" ]]; then
                        # avoid "...for branch main" in repos where that might cause confusion
                        tree_text=
                    else
                        tree_text="for $label $dirname"
                    fi
                    if [ -d docs ]; then
                        INDEX_DOCS="docs/$INDEX"
                        echo -e "\n## Documentation $tree_text\n" >> "$INDEX"
                        echo -e "## Documentation $tree_text\n" >> "$INDEX_DOCS"
                        for doc in docs/[1-9]*.md; do
                            add_numbered_doc "$doc"
                        done
                    fi

                    if [ -d APIs ]; then
                        INDEX_APIS="APIs/$INDEX"
                        echo -e "\n## APIs $tree_text\n" >> "$INDEX"
                        echo -e "## APIs $tree_text\n" > "$INDEX_APIS"
                        for api in APIs/*.html; do
                            no_ext="${api%%.html}"
                            linktext="${no_ext##*/}"
                            echo "- [$linktext](${api##*/})" >> "$INDEX_APIS"
                            echo "- [$linktext]($api)" >> "$INDEX"
                        done
                    fi

                    if [ -d APIs/schemas ]; then
                        INDEX_SCHEMAS="APIs/schemas/$INDEX"
                        echo -e "\n### [JSON Schemas](APIs/schemas/) $tree_text\n" >> "$INDEX"
                        echo -e "## JSON Schemas $tree_text\n" > "$INDEX_SCHEMAS"
                        for schema in APIs/schemas/with-refs/*.html; do
                            no_ext="${schema%%.html}"
                            linktext="${no_ext##*/}"
                            echo "- [$linktext](with-refs/$linktext.html) [(flattened)](resolved/$linktext.html)" >> "$INDEX_SCHEMAS"
                        done
                    fi

                    if [ -d examples ]; then
                        INDEX_EXAMPLES="examples/$INDEX"
                        echo -e "\n### [Examples](examples/) $tree_text\n" >> "$INDEX"
                        echo -e "## Examples $tree_text\n" > "$INDEX_EXAMPLES"
                        for example in examples/*.html; do
                            no_ext="${example%%.html}"
                            linktext="${no_ext##*/}"
                            echo "- [$linktext](${example##*/})" >> "$INDEX_EXAMPLES"
                        done
                    fi

                fi
            )
        done
    )
}

do_tree branches branch
do_tree releases release

echo "Making top level $INDEX"

# Repo-specific intro taken from readme
{
    if [[ "$AMWA_ID" == "BCP-002" || "$AMWA_ID" == "BCP-003" ]]; then
        echo -e "\n\n## About the ${AMWA_ID} Recommendations\n\n" 
    elif [[ "$AMWA_ID" != "SPECS" ]]; then
        echo -e "\n\n## About ${AMWA_ID}\n\n"
    fi
    ed -s "$README" <<< '/INTRO-START/+1,/INTRO-END/-1p'
    echo -e "\n\n---\n\n"
} > "$INDEX"

# Heading/intro depends on repo type
if [[ "$AMWA_ID" == "NMOS-TESTING" ]]; then
    echo "## Documentation" >> "$INDEX"
elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
    echo "## Parameter Registers" >> "$INDEX"
elif [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS" && "$AMWA_ID" != "BCP-002" && "$AMWA_ID" != "BCP-003" ]]; then
    # Common intro for specs
    sed "s~%AMWA_ID%~${AMWA_ID}~g; s~%REPO_ADDRESS%~${REPO_ADDRESS}~g; s~%DEFAULT_TREE%~${DEFAULT_TREE}~g" "$INTRO_COMMON" >> "$INDEX"
fi

# Add the default links at the top - correct the links while copying text
if [ "$DEFAULT_TREE" ]; then
    echo "Adding in contents of $INDEX for default tree $DEFAULT_TREE"
    sed "s:(:($DEFAULT_TREE/:" "$DEFAULT_TREE/$INDEX" >> "$INDEX"
fi

# TODO: DRY on the following...


# These excluded repos don't have branch and releases indexes
if [[ ! "$AMWA_ID" == "SPECS" && ! "$AMWA_ID" == "NMOS" && ! "$AMWA_ID" == "BCP-002" && ! "$AMWA_ID" == "BCP-003" ]]; then
    echo Adding releases index...
    INDEX_RELEASES="releases/index.md"
    echo "## Published Releases" > "$INDEX_RELEASES"
    echo -e "\n##  Published Releases" >> "$INDEX"
    for release in $(cd releases && echo -- * | awk '{ for (i=NF; i>=1; i--) print $i}'); do
        [ ! -d "releases/$release" ] && continue
        echo -e "\n[$release](releases/$release/)" >>  "$INDEX"
        echo -e "\n[$release]($release/)" >>  "$INDEX_RELEASES"
    done

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
    for branch in $(cd branches && echo -- * | awk '{ for (i=NF; i>=1; i--) print $i}'); do
        [ ! -d "branches/$branch" ] && continue
        echo -e "\n[$branch](branches/$branch/)" >>  "$INDEX"
        echo -e "\n[$branch]($branch/)" >>  "$INDEX_BRANCHES"
    done
fi

if [[ "$AMWA_ID" != "SPECS" ]]; then
    # Add repo links and lint and render status badges -- with GitHub Actions these default to default branch
    default_branch="$(git remote show origin | awk '/HEAD branch/ { print $3 }')"
    cat << EOF >> "$INDEX"

---

The formal specification is provided in [this GitHub repository]($REPO_ADDRESS). These pages render the documentation and APIs (which are specified in RAML and JSON Schema).

| Repository | Default Branch | Lint (default) | Render (all) |
| --- | --- | --- | --- |
| [${REPO_ADDRESS##*/}]($REPO_ADDRESS) \
| $default_branch \
| [![Lint Status]($REPO_ADDRESS/workflows/Lint/badge.svg)]($REPO_ADDRESS/actions?query=workflow%3ALint) \
| [![Render Status]($REPO_ADDRESS/workflows/Render/badge.svg)]($REPO_ADDRESS/actions?query=workflow%3ARender) \
|
EOF
fi

echo Adding warnings and project description to each autogenerated file...
find . -name "$INDEX" -exec perl -pi -e 'print "<!-- AUTOGENERATED FILE: DO NOT EDIT -->\n\n# {{ site.github.project_tagline }}\n\n" if $. == 1' {} \;
