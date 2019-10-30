#!/bin/bash

set -o errexit

if [ ! -d node_modules/.bin ]; then
    echo "fatal: Cannot find build tools (have you done 'make build-tools?')"
    exit 1
fi

PATH=$PWD/node_modules/.bin:$PATH

function extract {
    checkout=$1
    target_dir=$2
    echo "Extracting documentation from $checkout into $target_dir"
    mkdir "$target_dir"
    cd source-repo
        echo "Checking out $checkout..."
        git checkout "$checkout"
        if [ -d docs ]; then
            cp -r docs "../$target_dir"
        fi
        if [ -d APIs ]; then
            cd APIs
                cd schemas
                    mkdir with-refs resolved
                    for i in *.json; do
                        echo "Resolving schema references for $i"
                        if ! ../../../resolve-schema.py $i > resolved/$i ; then
                            echo "WARNING: Resolving failed: resolved/$i may include \$refs"
                            cp $i resolved/$i
                        fi
                        mv $i with-refs/
                        cp resolved/$i $i
                    done
                    cd ..
                for i in *.raml; do
                    HTML_API=${i%%.raml}.html
                    echo "Generating $HTML_API from $i..."
                    cat << EOF > "$HTML_API"
---
layout: default
title: API $i
---
EOF
                    raml2html -p --theme raml2html-nmos-theme $i >> "$HTML_API"
                done
                mkdir "../../$target_dir/html-APIs"
                mv *.html "../../$target_dir/html-APIs/"
                cp ../../json-formatter.js "../../$target_dir/html-APIs/"

                if [ -d schemas ]; then
                    echo "Rendering with-refs schemas..."
                    for i in schemas/with-refs/*.json; do
                        HTML_SCHEMA=${i%%.json}.html
                        # echo "Generating $HTML_SCHEMA from $i..."
                        ../../render-json.sh "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/with-refs/resolved}" "Resolve referenced schemas" > "$HTML_SCHEMA"
                    done
                    echo "Rendering resolved schemas..."
                    for i in schemas/resolved/*.json; do
                        HTML_SCHEMA=${i%%.json}.html
                        # echo "Generating $HTML_SCHEMA from $i..."
                        ../../render-json.sh "$i" "Schema ${i##*/}" "../../${HTML_SCHEMA/resolved/with-refs}" "Show referenced schemas with \$ref" > "$HTML_SCHEMA"
                    done
                    echo "Moving schemas..."
                    mkdir "../../$target_dir/html-APIs/schemas"
                    mkdir "../../$target_dir/html-APIs/schemas/with-refs"
                    cp ../../json-formatter.js "../../$target_dir/html-APIs/schemas/with-refs"
                    mv schemas/with-refs/*.html "../../$target_dir/html-APIs/schemas/with-refs"
                    mkdir "../../$target_dir/html-APIs/schemas/resolved"
                    cp ../../json-formatter.js "../../$target_dir/html-APIs/schemas/resolved"
                    mv schemas/resolved/*.html "../../$target_dir/html-APIs/schemas/resolved"
                    echo "Tidying..."
                    # Restore things how they were to ensure next checkout doesn't overwrite
                    mv schemas/with-refs/*.json schemas/ 
                    rm -rf schemas/with-refs schemas/resolved
                fi
                cd ..
        fi
        if [ -d examples ]; then
            # echo "Linting examples..."
            # jsonlint -v examples/*.json
            echo "Rendering examples..."
            for i in examples/*.json; do
               HTML_EXAMPLE=${i%%.json}.html 
               # echo "Rendering $HTML_EXAMPLE from $i..." 
               ../render-json.sh $i "Example ${i##*/}" >> "$HTML_EXAMPLE"
            done
            echo "Moving examples..."
            mkdir "../$target_dir/examples"
            mv examples/*.html "../$target_dir/examples"
            cp ../json-formatter.js "../$target_dir/examples"
        fi
    cd ..
}

# Find out which branches and tags will be shown
. ./get-config.sh

mkdir branches
for branch in $(cd source-repo; git branch -r | sed 's:origin/::' | grep -v HEAD | grep -v gh-pages); do
    if [[ "$branch" =~ $SHOW_BRANCHES ]]; then
        extract "$branch" "branches/$branch"
    else
        echo Skipping branch $branch
    fi
done

mkdir tags
for tag in $(cd source-repo; git tag); do
    if [[ "$tag" =~ $SHOW_TAGS ]]; then
        extract "tags/$tag" "tags/$tag"
    else
        echo Skipping tag $tag
    fi
done
