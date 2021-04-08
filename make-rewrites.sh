#!/usr/bin/env bash

set -o errexit

shopt -s nullglob

# shellcheck source=get-config.sh
. .scripts/get-config.sh

HTACCESS=_site/.htaccess

echo "RewriteEngine on" > $HTACCESS

if [[ "$AMWA_ID" == "SPECS" ]]; then
    echo Copying top-level .htaccess
    cp ../.htaccess $HTACCESS
    exit 0
fi


if [[ -d branches ]]; then
    echo Making branch rewrite rules
    for b in branches/*; do
        branch=${b#*/}
        if [[ -n "$SHOW_BRANCHES" && "$branch" =~ $SHOW_BRANCHES ]]; then
            echo "RewriteRule ^$branch(.*) branches/$branch\$1" >> $HTACCESS
        fi
    done
fi

if [[ -d releases ]]; then
    echo Making release rewrite rules
    for t in releases/*; do
        release=${t#*/}
        if [[ -n "$SHOW_RELEASES" && "$release" =~ $SHOW_RELEASES ]]; then
            echo "RewriteRule ^$release(.*) releases/$release\$1" >> $HTACCESS
        fi
    done
fi

echo Making repo rewrite rule
echo "RewriteRule ^repo/?$ $REPO_ADDRESS [R]" >> $HTACCESS
