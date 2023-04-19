#!/usr/bin/env bash

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
shopt -s extglob globstar nullglob

PATH=$PWD/.scripts:$PWD/node_modules/.bin:/usr/local/share/.config/yarn/global/node_modules/.bin:$PATH

. get-config.sh

# Unfortunately bash doesn't have proper functions or scoping
function make_label {
    local label="${1%%.md}"
    label="${label//%20/ }"
    label="${label/#*([0-9.]) /}"
    # label="${label/#* - /}"
    echo "$label"
 }

function add_nav_links {
    local prev="$1"
    local next="$2"
    local file="$3"
    local string=
    if [[ -n "$prev" ]]; then
        string+="[←$(make_label "$prev") ]($prev) · "
    fi
    string+="[ Index↑ ](..)"
    if [[ -n "$next" ]]; then
        string+=" · [$(make_label "$next")→]($next)"
    fi
    # this assumes there is the main heading on line 1 and line 2 is either blank or {:no_toc}
    sed -i -e "3i$string\\n" -e "\$a\\\n$string" "$file"
}


# Render docs in the specified relative path
function render_docs {
    docs_dir="$1"

    mkdir "../$target_dir/$docs_dir"
    prev_file=
    prev_link=
    prevprev_link=

    if compgen -G "$docs_dir/[1-9].*.md" > /dev/null; then
        echo "Extracting and rendering numbered docs"

        for i in "$docs_dir"/[1-9]*.md; do
            filename="${i##*/}" # strip path
            cp "$docs_dir/$filename" "../$target_dir/$docs_dir/"
            this_file="../$target_dir/$docs_dir/$filename"
            this_link="${filename// /%20}" # so links look like they do on github.com -- fixlinks.sh converts to underscore
            if [ -n "$prev_file" ]; then
                add_nav_links "$prevprev_link" "$this_link" "$prev_file"
            fi
            prevprev_link="$prev_link"
            prev_file="$this_file"
            prev_link="$this_link"
        done
        add_nav_links "$prevprev_link" "" "$this_file" # Last one has no next; singleton has no previous either

    elif [ -f "$docs_dir/README.md" ]; then
        echo "Extracting and rendering docs from list in README.md"
        while read -r i; do
            filename="${i//%20/ }.md" # README.md links use %20 for spaces
            cp "$docs_dir/$filename" "../$target_dir/$docs_dir/"
            this_file="../$target_dir/$docs_dir/$filename"
            this_link="${filename// /%20}" # so links look like they do on github.com -- fixlinks.sh converts to underscore
            if [ -n "$prev_file" ]; then
                add_nav_links "$prevprev_link" "$this_link" "$prev_file"
            fi
            prevprev_link="$prev_link"
            prev_file="$this_file"
            prev_link="$this_link"
        done <<< "$(awk -F'^ *- \\[.*\\]\\(' '(NF>1){print $2}' "$docs_dir/README.md"| sed 's/.md)//')"
        add_nav_links "$prevprev_link" "" "$this_file" # Last one has no next; singleton has no previous either

        # Need to extract README.md to make indexes later
        cp "$docs_dir/README.md" "../$target_dir/$docs_dir"

    else
        echo No numbered docs or README.md found
        exit 1
    fi

    if [ -d "$docs_dir/images" ] ; then
        echo "Copying images"
        cp -r "$docs_dir/images" "../$target_dir/$docs_dir"
    fi
}

# Render RAML in the specified relative path
function render_APIs {
    apis_dir="$1"

    for i in "$apis_dir"/*.raml; do

        HTML_API=${i%%.raml}.html
        echo "Generating $HTML_API from $i"
        cat << EOF > "$HTML_API"
---
layout: default
title: API $i
---
EOF
        if grep -q '^#%RAML *0.8' "$i"; then
            echo "Warning: relabelling RAML 0.8 as 1.0"
            perl -pi.bak -e 's/^#%RAML *0\.8/#%RAML 1.0/' "$i"
        fi
        raml2html --theme raml2html-nmos-theme "$i" >> "$HTML_API"
        [ -e "$i.bak" ] && mv "$i.bak" "$i" # Otherwise next checkout will fail
    done
    echo "Moving APIs"
    mkdir -p "../$target_dir/$apis_dir"
    for i in "$apis_dir"/*.html; do
        mv "$i" "../$target_dir/$apis_dir"
    done

    cp ../.scripts/json-formatter.js "../$target_dir/$apis_dir/"
}

# Render with-refs and resolved versions of JSON schemas in the specified relative path
function render_schemas {
    schemas_dir="$1" 

    (
        cd "$schemas_dir" || exit 1
        echo "Resolving schema references"
        mkdir with-refs resolved
        for i in *.json; do
            if ! resolve-schema.py "$i" > "resolved/$i" ; then
                echo "WARNING: Resolving failed: resolved/$i may include \$refs"
                cp "$i" "resolved/$i"
            fi
            mv "$i" with-refs/
            cp "resolved/$i" "$i"
        done
    )

    echo "Rendering with-refs schema"
    for i in "$schemas_dir/with-refs"/*.json; do
        HTML_SCHEMA=${i%%.json}.html
        HTML_SCHEMA_TAIL="with-refs/${HTML_SCHEMA##*/}" # e.g. with-refs/name.html
        render-json.sh -n "$i" "Schema ${i##*/}" "../${HTML_SCHEMA_TAIL/with-refs/resolved}" "Resolve referenced schemas (may reorder keys)" > "$HTML_SCHEMA"
    done
    echo "Rendering resolved schemas"
    for i in "$schemas_dir/resolved"/*.json; do
        HTML_SCHEMA=${i%%.json}.html
        HTML_SCHEMA_TAIL="resolved/${HTML_SCHEMA##*/}" # e.g. resolved/name.html
        render-json.sh "$i" "Schema ${i##*/}" "../${HTML_SCHEMA_TAIL/resolved/with-refs}" "Show original (referenced schemas with \$ref)" > "$HTML_SCHEMA"
    done
    echo "Moving schemas"
    mkdir "../$target_dir/$schemas_dir"
    mkdir "../$target_dir/$schemas_dir/with-refs"
    cp ../.scripts/json-formatter.js "../$target_dir/$schemas_dir/with-refs"
    cp -r ../.scripts/codemirror "../$target_dir/$schemas_dir/with-refs"
    for i in "$schemas_dir/with-refs"/*.html; do
        mv "$i" "../$target_dir/$schemas_dir/with-refs"
    done
    mkdir "../$target_dir/$schemas_dir/resolved"
    cp ../.scripts/json-formatter.js "../$target_dir/$schemas_dir/resolved"
    cp -r ../.scripts/codemirror "../$target_dir/$schemas_dir/resolved"
    for i in "$schemas_dir/resolved"/*.html; do
        mv "$i" "../$target_dir/$schemas_dir/resolved"
    done
    echo "Tidying"
    # Restore things how they were to ensure next checkout doesn't overwrite
    for i in "$schemas_dir/with-refs/"*.json; do
        mv "$i" "$schemas_dir/"
    done
    rm -rf "$schemas_dir/with-refs" "$schemas_dir/resolved"

}

# Render JSON examples in the specified relative path
function render_examples {
    examples_dir=$1

    for i in "$examples_dir"/*.json; do
        HTML_EXAMPLE=${i%%.json}.html
        render-json.sh -n "$i" "Example ${i##*/}" >> "$HTML_EXAMPLE"
    done

    for i in "$examples_dir"/*.sdp; do
        HTML_EXAMPLE=${i%%.sdp}.html
        render-other-code.sh -n "$i" "Example ${i##*/}" >> "$HTML_EXAMPLE"
    done

    echo "Moving examples"
    mkdir -p "../$target_dir/$examples_dir"
    for i in "$examples_dir"/*.html; do
        mv "$i" "../$target_dir/$examples_dir"
    done
    cp ../.scripts/json-formatter.js "../$target_dir/$examples_dir"
    cp -r ../.scripts/codemirror "../$target_dir/$examples_dir"

}

# Render Web IDL in the specified relative path
function render_webidl {
    idl_dir=$1

    for i in "$idl_dir"/*.webidl; do
        HTML_EXAMPLE=${i%%.webidl}.html
        render-webidl.sh -n "$i" "Framework definitions ${i##*/}" >> "$HTML_EXAMPLE"
    done

    echo "Moving webidl"
    mkdir -p "../$target_dir/$idl_dir"
    for i in "$idl_dir"/*.html; do
        mv "$i" "../$target_dir/$idl_dir"
    done
    cp -r ../.scripts/codemirror "../$target_dir/$idl_dir"

}

function extract_and_render {
    checkout=$1
    target_dir=$2
    echo "Extracting and rendering $checkout into $target_dir"
    mkdir "$target_dir"

    (
        cd source-repo || exit 1
        git checkout "$checkout"

        # 404 doc for specs repo
        if [[ "$AMWA_ID" == "SPECS" ]]; then
            cp 404.md "../$target_dir"
            cp .htaccess "../$target_dir"
        fi

        # Individual doc tables for NMOS
        if [[ "$AMWA_ID" == "NMOS" ]]; then
            cp -r is ms bcp info  ".."
        fi

        # Param regs still a special case
        if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
            for id in $(yaml2json registers.yml | jq -r '.[].id'); do 
                cp -r "$id" "../$target_dir"
            done
            # Param reg JSONs that need rendering as HTML
                for json in */*.json; do
                    render-json.sh -n "$json" "$json" > "../$target_dir/${json%%.json}.html"
                    cp ../.scripts/json-formatter.js "../$target_dir/${json%/*.json}/"
                    cp -r ../.scripts/codemirror "../$target_dir/${json%/*.json}/"
                done

        # Control feature sets a special case
        elif [[ "$AMWA_ID" == "NMOS-CONTROL-FEATURE-SETS" ]]; then
            for id in $(yaml2json feature-sets.yml | jq -r '.[].id'); do 
                cp -r "$id" "../$target_dir"
            done


        # Other repos have some or all of docs/, APIs/, APIs/schemas/, schemas/, examples/
        else
            if [ -d docs ]; then
                render_docs docs
            fi

            if [ -d APIs ]; then
                render_APIs APIs 
            fi

            if [ -d testingfacade/APIs ]; then
                render_APIs testingfacade/APIs
            fi 

            if [ -d APIs/schemas ]; then
                render_schemas APIs/schemas
            fi

            if [ -d schemas ]; then
                render_schemas schemas 
            fi

            if [ -d testingfacade/APIs/schemas ]; then
                render_schemas testingfacade/APIs/schemas
            fi 

            if [ -d examples ]; then
                render_examples examples
            fi

            if [ -d testingfacade/examples ]; then
                render_examples testingfacade/examples
            fi

            if [ -d idl ]; then
                render_webidl idl
            fi
        fi # AMWA_ID
    )
}

mkdir branches
for branch in $(cd source-repo; git branch -r | sed 's:origin/::' | grep -v HEAD | grep -v gh-pages); do
    if [[ -n "$SHOW_BRANCHES" && "$branch" =~ $SHOW_BRANCHES ]]; then
        extract_and_render "$branch" "branches/$branch"
    else
        echo "Skipping branch $branch"
    fi
done

# tag means git tag, release means NMOS/GitHub release
mkdir releases
for tag in $(cd source-repo; git tag); do
    if [[ -n "$SHOW_RELEASES" && "$tag" =~ $SHOW_RELEASES ]]; then
        extract_and_render "tags/$tag" "releases/$tag"
    else
        echo "Skipping tag/release $tag"
    fi
done
