#!/usr/bin/env bash

shopt -s globstar nullglob

echo Linting Markdown...
if ! find . -name node_modules -prune -o -name '*.md' -print0 | xargs -0 ./node_modules/.bin/remark --rc-path .scripts/.remarkrc --frail; then
    failed=y
fi

if [ -d APIs ]; then
    echo Linting APIs...
    for i in APIs/*.raml; do
        perl -pi.bak -e 's/!include//' "$i"
        if ./node_modules/.bin/yamllint "$i" > output; then
            echo "$i" ok
        else
            cat output
            echo -e "\033[31m$i failed\033[0m"
            failed=y
            rm output
        fi
        mv "$i.bak" "$i"
    done
fi

if [ -d APIs/schemas ]; then
    echo Linting schemas...
    for i in APIs/schemas/*.json ; do
        if ./node_modules/.bin/jsonlint "$i" > /dev/null; then
            echo "$i" ok
        else
            echo -e "\033[31m$i failed\033[0m"
        failed=y
      fi
    done
fi

if [ -d examples ]; then
    echo Linting examples...
    for i in examples/**/*.json ; do
        if ./node_modules/.bin/jsonlint "$i" > /dev/null; then
            echo "$i" ok
        else
            echo -e "\033[31m$i failed\033[0m"
        failed=y
      fi
    done
fi

if [ "$failed" == "y" ]; then
    exit 1
else
    exit 0
fi
