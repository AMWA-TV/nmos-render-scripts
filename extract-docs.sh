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

PATH=$PWD/.scripts:$PWD/node_modules/.bin:$PATH

. get-config.sh

if [[ "$AMWA_ID" =~ "IS-" && ! -d node_modules/.bin ]]; then
    echo "fatal: Cannot find build tools (have you done 'make build-tools?')"
    exit 1
fi

# Unfortunately bash doesn't have proper functions or scoping...
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

        # NMOS gets copies of some wiki docs
        if [[ "$AMWA_ID" == "NMOS" ]]; then
            git clone https://github.com/AMWA-TV/nmos.wiki

            function get_wiki_doc {
                echo "# $2" > "$1"
                # Strip off table of contents comments
                sed 's~^\[//\]:.*~~' "nmos.wiki/$1" >> "$1"
            }
            get_wiki_doc FAQ.md "NMOS FAQ"
            get_wiki_doc Glossary.md "NMOS Glossary"
            get_wiki_doc NMOS-Solutions.md "NMOS Solutions"

            rm -rf nmos.wiki
        fi

        # These repos have docs in the main dir, not docs/
        if [[ "$AMWA_ID" == "NMOS" || "$AMWA_ID" == "BCP-002" || "$AMWA_ID" == "BCP-003" ]]; then
            cp -- *.md "../$target_dir"
            if [ -d images ] ; then
                cp -r images "../$target_dir" 
            fi

            # NMOS-PARAMETER-REGISTERS has individual dir for each register
            elif [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
                cp -r common device-control-types device-types formats node-service-types tags transports "../$target_dir"

            # Other repos have some or all of docs/, APIs/, examples/
            else
                if [ -d docs ]; then
                (
                    cd docs || exit 1
                    mkdir "../../$target_dir/docs"
                    prev_file=
                    prev_link=
                    prevprev_link=
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
                        mkdir with-refs resolved
                        for i in *.json; do
                            echo "Resolving schema references for $i"
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
                        echo "Generating $HTML_API from $i..."
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
                    mv -- *.html "../../$target_dir/APIs/"

                    cp ../../.scripts/json-formatter.js "../../$target_dir/APIs/"

                    if [ -d schemas ]; then
                        echo "Rendering with-refs schemas..."
                        for i in schemas/with-refs/*.json; do
                            HTML_SCHEMA=${i%%.json}.html
                            # echo "Generating $HTML_SCHEMA from $i..."
                            render-json.sh -n "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/with-refs/resolved}" "Resolve referenced schemas (may reorder keys)" > "$HTML_SCHEMA"
                        done
                        echo "Rendering resolved schemas..."
                        for i in schemas/resolved/*.json; do
                            HTML_SCHEMA=${i%%.json}.html
                            # echo "Generating $HTML_SCHEMA from $i..."
                            render-json.sh "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/resolved/with-refs}" "Show original (referenced schemas with \$ref)" > "$HTML_SCHEMA"
                        done
                        echo "Moving schemas..."
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
                        echo "Tidying..."
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
                    echo "Rendering examples..."
                    cd examples || exit 1
                        for i in **/*.json; do
                            flat=${i//*\//}
                            HTML_EXAMPLE=${flat%%.json}.html 
                            echo "Rendering $HTML_EXAMPLE from $i..." 
                            render-json.sh -n "$i" "Example ${i##*/}" >> "$HTML_EXAMPLE"
                        done
                        echo "Moving examples..."
                        mkdir "../../$target_dir/examples"
                        mv -- *.html "../../$target_dir/examples"
                        cp ../../.scripts/json-formatter.js "../../$target_dir/examples"
                        cp -r ../../.scripts/codemirror "../../$target_dir/examples"
                )
                fi
        fi # AMWA_ID
    )
}

mkdir branches
for branch in $(cd source-repo; git branch -r | sed 's:origin/::' | grep -v HEAD | grep -v gh-pages); do
    if [[ "$branch" =~ $SHOW_BRANCHES ]]; then
        extract "$branch" "branches/$branch"
    else
        echo Skipping branch "$branch"
    fi
done

# Unfortunately NMOS-PARAMETER-REGISTERS already has a "tags" register, which has grabbed the /tags/ dir.
# For now just skip in this case, but if we ever want to have releases of param-regs we'll need a better way...

if [[ "$AMWA_ID" != "NMOS-PARAMETER-REGISTERS" ]]; then
    mkdir tags
    for tag in $(cd source-repo; git tag); do
        if [[ "$tag" =~ $SHOW_TAGS ]]; then
            extract "tags/$tag" "tags/$tag"
        else
            echo Skipping tag "$tag"
        fi
    done
fi
