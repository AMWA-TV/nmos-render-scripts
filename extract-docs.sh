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

PATH=$PWD/.scripts:/usr/local/share/.config/yarn/global/node_modules/.bin:$PATH

. get-config.sh

if [[ "$AMWA_ID" =~ "IS-" && ! -d /usr/local/share/.config/yarn/global/node_modules/.bin ]]; then
    echo "fatal: Cannot find build tools (have you done 'make build-tools?')"
    exit 1
fi

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


function extract {
    checkout=$1
    target_dir=$2
    echo "Extracting $checkout into $target_dir"
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
            cp -r capabilities common device-control-types device-types flow-attributes formats node-service-types tags transports transport-parameters "../$target_dir"
            # Param reg JSONs that need rendering as HTML
                for json in */*.json; do
                    render-json.sh -n "$json" "$json" > "../$target_dir/${json%%.json}.html"
                    cp ../.scripts/json-formatter.js "../$target_dir/${json%/*.json}/"
                    cp -r ../.scripts/codemirror "../$target_dir/${json%/*.json}/"
                done



        # Other repos have some or all of docs/, APIs/, examples/
        else
            if [ -d docs ]; then
            (
                cd docs || exit 1

                mkdir "../../$target_dir/docs"
                prev_file=
                prev_link=
                prevprev_link=

                if compgen -G "[1-9].*.md" > /dev/null; then
                    echo "Extracting numbered docs"

                    for i in [1-9]*.md; do
                        cp "$i" "../../$target_dir/docs"
                        this_file="../../$target_dir/docs/$i"
                        this_link="${i// /%20}" # so links look like they do on github.com -- fixlinks.sh converts to underscore
                        if [ -n "$prev_file" ]; then
                            add_nav_links "$prevprev_link" "$this_link" "$prev_file"
                        fi
                        prevprev_link="$prev_link"
                        prev_file="$this_file"
                        prev_link="$this_link"
                    done
                    add_nav_links "$prevprev_link" "" "$this_file" # Last one has no next; singleton has no previous either

                elif [ -f README.md ]; then
                    echo "Extracting docs from list in README.md"

                    while read -r i; do
                        filename="${i//%20/ }.md" # README.md links use %20 for spaces
                        cp "$filename" "../../$target_dir/docs"
                        this_file="../../$target_dir/docs/$filename"
                        this_link="${filename// /%20}" # so links look like they do on github.com -- fixlinks.sh converts to underscore
                        if [ -n "$prev_file" ]; then
                            add_nav_links "$prevprev_link" "$this_link" "$prev_file"
                        fi
                        prevprev_link="$prev_link"
                        prev_file="$this_file"
                        prev_link="$this_link"
                    done <<< "$(awk -F'^ *- \\[.*\\]\\(' '(NF>1){print $2}' README.md | sed 's/.md)//')"
                    add_nav_links "$prevprev_link" "" "$this_file" # Last one has no next; singleton has no previous either

                    # Need to extract README.md to make indexes later
                    cp README.md "../../$target_dir/docs"

                else
                    echo No numbered docs or README.md found
                    exit 1
                fi

                if [ -d images ] ; then
                    cp -r images "../../$target_dir/docs"
                fi

            )
            fi

            if [ -d APIs ]; then
            (
                cd APIs || exit 1
                (
                    cd schemas || exit 1
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
                for i in *.raml; do
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
                mkdir "../../$target_dir/APIs"
                for i in *.html; do
                    mv "$i" "../../$target_dir/APIs/"
                done

                cp ../../.scripts/json-formatter.js "../../$target_dir/APIs/"

                if [ -d schemas ]; then
                    echo "Rendering with-refs schemas"
                    for i in schemas/with-refs/*.json; do
                        HTML_SCHEMA=${i%%.json}.html
                        render-json.sh -n "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/with-refs/resolved}" "Resolve referenced schemas (may reorder keys)" > "$HTML_SCHEMA"
                    done
                    echo "Rendering resolved schemas"
                    for i in schemas/resolved/*.json; do
                        HTML_SCHEMA=${i%%.json}.html
                        render-json.sh "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/resolved/with-refs}" "Show original (referenced schemas with \$ref)" > "$HTML_SCHEMA"
                    done
                    echo "Moving schemas"
                    mkdir "../../$target_dir/APIs/schemas"
                    mkdir "../../$target_dir/APIs/schemas/with-refs"
                    cp ../../.scripts/json-formatter.js "../../$target_dir/APIs/schemas/with-refs"
                    cp -r ../../.scripts/codemirror "../../$target_dir/APIs/schemas/with-refs"
                    for i in schemas/with-refs/*.html; do
                        mv "$i" "../../$target_dir/APIs/schemas/with-refs"
                    done
                    mkdir "../../$target_dir/APIs/schemas/resolved"
                    cp ../../.scripts/json-formatter.js "../../$target_dir/APIs/schemas/resolved"
                    cp -r ../../.scripts/codemirror "../../$target_dir/APIs/schemas/resolved"
                    for i in schemas/resolved/*.html; do
                        mv "$i" "../../$target_dir/APIs/schemas/resolved"
                    done
                    echo "Tidying"
                    # Restore things how they were to ensure next checkout doesn't overwrite
                    for i in schemas/with-refs/*.json; do
                        mv "$i" schemas/
                    done
                    rm -rf schemas/with-refs schemas/resolved
                fi
            ) # APIs
            fi
            if [ -d examples ]; then
            (
                echo "Rendering examples"
                cd examples || exit 1
                    for i in **/*.json; do
                        flat=${i//*\//}
                        HTML_EXAMPLE=${flat%%.json}.html
                        render-json.sh -n "$i" "Example ${i##*/}" >> "$HTML_EXAMPLE"
                    done
                    echo "Moving examples"
                    mkdir "../../$target_dir/examples"
                    for i in *.html; do
                        mv "$i" "../../$target_dir/examples"
                    done
                    cp ../../.scripts/json-formatter.js "../../$target_dir/examples"
                    cp -r ../../.scripts/codemirror "../../$target_dir/examples"
            )
            fi
        fi # AMWA_ID
    )
}

mkdir branches
for branch in $(cd source-repo; git branch -r | sed 's:origin/::' | grep -v HEAD | grep -v gh-pages); do
    if [[ -n "$SHOW_BRANCHES" && "$branch" =~ $SHOW_BRANCHES ]]; then
        extract "$branch" "branches/$branch"
    else
        echo "Skipping branch $branch"
    fi
done

# tag means git tag, release means NMOS/GitHub release
mkdir releases
for tag in $(cd source-repo; git tag); do
    if [[ -n "$SHOW_RELEASES" && "$tag" =~ $SHOW_RELEASES ]]; then
        extract "tags/$tag" "releases/$tag"
    else
        echo "Skipping tag/release $tag"
    fi
done
