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
TOP_README=../README.md
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
}


function add_docs_from_markdown_list_of_links {
    list=$1

    if [[ ! -f "$list" ]]; then
        echo "$list not found"
        exit 1
    fi

    # Rename to use underscores instead of escaped (%20) spaces
    while read -r doc; do

        space_doc="${doc//%20/ }.md"
        underscore_doc="${doc//%20/_}.md"
        [[ "$underscore_doc" != "$space_doc" ]] && mv "docs/$space_doc" "docs/$underscore_doc"

    done <<< "$(awk -F'^ *- \\[.*\\]\\(' '(NF>1){print $2}' "$list" | sed 's/\.md)//')"

    # append index links with docs/
    perl -p -e 's~\]\(~\]\(docs/~' "$list" >> "$INDEX"
    perl -p -e 's~\]\(~\]\(docs/~' "$list" >> "$INDEX_DOCS"
}

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
}

function do_docs_index
{
    docs_dir="$1"

    INDEX_DOCS="$docs_dir/$INDEX"
    echo -e "\n## Documentation $tree_text\n" >> "$INDEX"
    echo -e "## Documentation $tree_text\n" > "$INDEX_DOCS"

    if compgen -G "docs/[1-9].*.md" > /dev/null ; then
        echo "Adding numbered docs"
        for doc in "$docs_dir"/[1-9]*.md; do
            add_numbered_doc "$doc"
        done
    elif [ -f "$docs_dir/README.md" ] ; then
        echo Adding docs from list in README.md
        add_docs_from_markdown_list_of_links "$docs_dir/README.md"
    else
        echo No numbered docs or README.md found
        exit 1
    fi
}
function do_apis_index
{
    apis_dir="$1"

    INDEX_APIS="$apis_dir/$INDEX"
    echo -e "\n## APIs $tree_text\n" >> "$INDEX"
    echo -e "## APIs $tree_text\n" > "$INDEX_APIS"
    for api in "$apis_dir"/*.html; do
        no_ext="${api%%.html}"
        linktext="${no_ext##*/}"
        echo "- [$linktext](${api##*/})" >> "$INDEX_APIS"
        echo "- [$linktext]($api)" >> "$INDEX"
    done

}

function do_schemas_index
{
    schemas_dir="$1" 

    INDEX_SCHEMAS="$schemas_dir/$INDEX"
    echo -e "\n### [JSON Schemas]($schemas_dir) $tree_text\n" >> "$INDEX"
    echo -e "## JSON Schemas $tree_text\n" > "$INDEX_SCHEMAS"
    for schema in "$schemas_dir/with-refs"/*.html; do
        no_ext="${schema%%.html}"
        linktext="${no_ext##*/}"
        echo "- [$linktext](with-refs/$linktext.html) [(flattened)](resolved/$linktext.html) [(raw)]($linktext.json)" >> "$INDEX_SCHEMAS"
    done
}

function do_examples_index
{
    examples_dir="$1"

    INDEX_EXAMPLES="$examples_dir/$INDEX"
    echo -e "\n### [Examples]($examples_dir) $tree_text\n" >> "$INDEX"
    echo -e "## Examples $tree_text\n" > "$INDEX_EXAMPLES"
    for example in "$examples_dir"/*.html; do
        no_ext="${example%%.html}"
        linktext="${no_ext##*/}"
        echo "- [$linktext](${example##*/})" >> "$INDEX_EXAMPLES"
    done
}

function do_models_index
{
    models_dir="$1"

    INDEX_MODELS="$models_dir/$INDEX"
    echo "### [Control class models $tree_text](classes)" > "$INDEX_MODELS"
    echo "### [Datatype models $tree_text](datatypes)" >> "$INDEX_MODELS"
}

function do_classes_index
{
    classes_dir="$1"

    INDEX_CLASSES="$classes_dir/$INDEX"
    echo -e "\n### [Control class models]($classes_dir) $tree_text\n" >> "$INDEX"
    echo -e "## Control class models $tree_text\n" > "$INDEX_CLASSES"
    for class in "$classes_dir"/*.html; do
        no_ext="${class%%.html}"
        linktext="${no_ext##*/}"
        name=$(jq -r .name "${no_ext}".json) # meaningful name
        echo "- [$linktext](${class##*/}) ($name)" >> "$INDEX_CLASSES"
    done
}

function do_datatypes_index
{
    datatypes_dir="$1"

    INDEX_DATATYPES="$datatypes_dir/$INDEX"
    echo -e "\n### [Datatype models]($datatypes_dir) $tree_text\n" >> "$INDEX"
    echo -e "## Datatype models $tree_text\n" > "$INDEX_DATATYPES"
    for datatype in "$datatypes_dir"/*.html; do
        no_ext="${datatype%%.html}"
        linktext="${no_ext##*/}"
        echo "- [$linktext](${datatype##*/})" >> "$INDEX_DATATYPES"
    done
}

function do_tree {
    tree=$1
    label=$2 # because of spelling of plurals

    echo "Processing $tree $INDEX"
    (
        cd "$tree" || exit 1
        for dir in */; do
            dirname="${dir%%/}"
            echo "Making $dirname/$INDEX"
            (
                cd "$dir" || exit 1

                # NMOS-PARAMETER-REGISTERS has its own table
                if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
                    echo "{% include register_table.html %}" >> "$INDEX"

                # NMOS-CONTROL-FEATURE-SETS has its own table
                elif [[ "$AMWA_ID" == "NMOS-CONTROL-FEATURE-SETS" ]]; then
                    echo "{% include feature_set_table.html %}" >> "$INDEX"

                # Other repos may have (possibly numbered) docs/, APIs/, APIs/schemas/, schemas/, examples/, idl/
                else
                    if [[ "$label" == "branch" && "$dirname" == "main" ]]; then
                        # avoid "...for branch main" in repos where that might cause confusion
                        tree_text=
                    else
                        tree_text="for $label $dirname"
                    fi
                    if [ -d docs ]; then
                        do_docs_index docs
                    fi

                    if [ -d APIs ]; then
                        do_apis_index APIs
                    elif [ -d testingfacade/APIs ]; then
                        do_apis_index testingfacade/APIs
                    fi

                    if [ -d APIs/schemas ]; then
                        do_schemas_index APIs/schemas
                    elif [ -d schemas ]; then
                        do_schemas_index schemas
                    elif [ -d testingfacade/APIs/schemas ]; then
                        do_schemas_index testingfacade/APIs/schemas 
                    fi

                    if [ -d examples ]; then
                        do_examples_index examples
                    elif [ -d testingfacade/examples ]; then
                        do_examples_index testingfacade/examples
                    fi

                    if [ -d models ]; then
                        do_models_index models
                        do_classes_index models/classes
                        do_datatypes_index models/datatypes
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
    ed -s "$TOP_README" <<< '/INTRO-START/+1,/INTRO-END/-1p'
    echo -e "\n\n---\n\n"
} > "$INDEX"

# Heading/intro depends on repo type
if [[ "$AMWA_ID" == "NMOS-TESTING" ]]; then
    echo "## Documentation" >> "$INDEX"
elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
    echo "## Parameter Registers" >> "$INDEX"
elif [[ "$AMWA_ID" == "NMOS-CONTROL-FEATURE-SETS" ]]; then
    echo "## Feature Sets" >> "$INDEX"
elif [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS" && "$AMWA_ID" != "BCP-002" && "$AMWA_ID" != "BCP-003" ]]; then
    # Common intro for specs
    sed "s~%AMWA_ID%~${AMWA_ID}~g; s~%REPO_ADDRESS%~${REPO_ADDRESS}~g; s~%DEFAULT_TREE%~${DEFAULT_TREE}~g" "$INTRO_COMMON" >> "$INDEX"
fi

# Add the default links at the top - correct the links while copying text
if [ "$DEFAULT_TREE" ]; then
    echo "Adding in contents of $INDEX for default tree $DEFAULT_TREE"
    if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
        echo "Please select a release or branch from below to see the table of parameter registers" >> "$INDEX"
    elif [[ "$AMWA_ID" == "NMOS-CONTROL-FEATURE-SETS" ]]; then
        echo "Please select a release or branch from below to see the table of feature sets" >> "$INDEX"
    else
        sed "s:](:]($DEFAULT_TREE/:" "$DEFAULT_TREE/$INDEX" >> "$INDEX"
    fi
fi

# TODO: DRY on the following...


# These excluded repos don't have branch and releases indexes
if [[ ! "$AMWA_ID" == "SPECS" && ! "$AMWA_ID" == "NMOS" && ! "$AMWA_ID" == "BCP-002" && ! "$AMWA_ID" == "BCP-003" ]]; then
    echo Adding releases index
    INDEX_RELEASES="releases/index.md"
    echo "## Published Releases" > "$INDEX_RELEASES"
    echo -e "\n##  Published Releases" >> "$INDEX"
    for release in $(cd releases && echo -- * | awk '{ for (i=NF; i>=1; i--) print $i}'); do
        [ ! -d "releases/$release" ] && continue
        echo -e "\n[$release](releases/$release/)" >>  "$INDEX"
        echo -e "\n[$release]($release/)" >>  "$INDEX_RELEASES"
    done

    echo Adding branches index
    INDEX_BRANCHES="branches/index.md"
    echo "## Live Branches" > "$INDEX_BRANCHES"
    echo -e "\n## Live Branches" >> "$INDEX"
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

These pages are rendered from the source of the specification, which is in [this GitHub repository]($REPO_ADDRESS).

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
