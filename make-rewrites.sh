#!/usr/bin/env bash

# shellcheck source=get-config.sh
. .scripts/get-config.sh

HTACCESS=_site/.htaccess

echo "RewriteEngine on" > $HTACCESS

if [[ -d branches ]]; then
    echo Making branch rewrite rules
    for b in branches/*; do
        branch=${b#*/}
        if [[ "$branch" =~ $SHOW_BRANCHES ]]; then
            echo "RewriteRule ^$branch(.*) branches/$branch\$1" >> $HTACCESS
        fi
    done
fi

if [[ -d tags ]]; then
    echo Making tag rewrite rules
    for t in tags/*; do
        tag=${t#*/}
        if [[ "$tag" =~ $SHOW_TAGS ]]; then
            echo "RewriteRule ^$tag(.*) tags/$tag\$1" >> $HTACCESS
        fi
    done
fi

