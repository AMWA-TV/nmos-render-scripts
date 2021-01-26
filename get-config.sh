#!/usr/bin/env bash
# shellcheck disable=SC2034
# ^Unused variable warning: most of the variables are used in sourcing file

# This file is sourced from build scripts
# It now pulls in settings from _config.yml
# TODO: just read _config.yml once!

_CONFIG_YML=_config.yml

if [ ! -f $_CONFIG_YML ]; then
    echo Cannot find $_CONFIG_YML >&2 
    exit 1
else
    echo Getting config from $_CONFIG_YML
fi

AMWA_ID="$(awk '/amwa_id/ { print $2 }' $_CONFIG_YML)"
REPO_ORIGIN="$(git remote get-url origin)"
REPO_ADDRESS="${REPO_ORIGIN%.git}"
REPO_NAME="${REPO_ADDRESS##*/}"
BASEURL="$(awk '/baseurl/ { print $2 }' $_CONFIG_YML)"
SITE_NAME="${BASEURL#/}"
DEFAULT_TREE="$(awk '/default_tree:/ { print $2 }' $_CONFIG_YML)"
SHOW_RELEASES="$(awk '/show_releases:/ { print $2 }' $_CONFIG_YML)"
SHOW_BRANCHES="$(awk '/show_branches:/ { print $2 }' $_CONFIG_YML)"
SPEC_SERVER="$(awk '/spec_server/ { print $2 }' $_CONFIG_YML)"
