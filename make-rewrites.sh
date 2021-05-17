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
    for r in releases/*; do
        release=${r#*/}
        if [[ -n "$SHOW_RELEASES" && "$release" =~ $SHOW_RELEASES ]]; then
            echo "RewriteRule ^$release(.*) releases/$release\$1" >> $HTACCESS
        fi
    done
    echo Making latest release rewrite rules
    find releases -maxdepth 1 -type d -name 'v*' | sort | sed s:releases/:: | awk -F. '
{
    latest[sprintf("%s.%s", $1, $2)] = $0
}
END {
    for (v in latest) {
        printf("RewriteRule ^%s(.*) releases/%s$1\n", v, latest[v])
        overall_latest = latest[v]
    }
    printf("RewriteRule ^latest(.*) releases/%s$1\n", overall_latest)
}
' >> $HTACCESS
fi

echo Making repo rewrite rule
echo "RewriteRule ^repo(.*) $REPO_ADDRESS\$1 [R]" >> $HTACCESS
