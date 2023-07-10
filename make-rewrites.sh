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
    # This sorts the releases in semantic order and selects the last release
    # for each major.minor version and the last overall
    find releases -maxdepth 1 -type d -name 'v*' | sed s:releases/v:: | sort -V | awk -F. '
{
    latest[sprintf("%s.%s", $1, $2)] = $0
}
END {
    for (v in latest) {
        printf("RewriteRule ^v%s(.*) releases/v%s$1\n", v, latest[v])
        overall_latest = latest[v]
    }
    printf("RewriteRule ^latest(.*) releases/v%s$1\n", overall_latest)
}
' >> $HTACCESS
fi

echo Making repo rewrite rule
echo "RewriteRule ^repo(.*) $REPO_ADDRESS\$1 [R]" >> $HTACCESS

if compgen -G "*/*/examples/*.sdp" > /dev/null; then
    echo "Adding Content-Type for SDP examples"
    echo "AddType application/sdp .sdp" >> $HTACCESS
fi
