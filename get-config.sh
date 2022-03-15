#!/usr/bin/env bash
# shellcheck disable=SC2034
# ^Unused variable warning: most of the variables are used in sourcing file

# This file is sourced from build scripts
# It now pulls in settings from _config.yml
# TODO: just read _config.yml once!

if [[ "$CONFIG" ]]; then
    echo "Warning: Using config from $CONFIG rather than _config.yml"
    _CONFIG_YML="$CONFIG"
else
    _CONFIG_YML=_config.yml
fi

if [ ! -f $_CONFIG_YML ]; then
    echo Cannot find $_CONFIG_YML >&2 
    exit 1
else
    echo Getting config from $_CONFIG_YML
fi

if [[ "$EXTRACT_FROM" ]]; then
    echo "Warning: Extracting from $EXTRACT_FROM rather than origin"
    REPO_ADDRESS="$EXTRACT_FROM"
else
    REPO_ORIGIN="$(git remote get-url origin)"
    REPO_ADDRESS="${REPO_ORIGIN%.git}"
fi

REPO_NAME="${REPO_ADDRESS##*/}"
BASEURL="$(awk '/^\s*baseurl:/ { print $2 }' $_CONFIG_YML)"
SITE_NAME="${BASEURL#/}"
AMWA_ID="$(awk '/^\s*amwa_id:/ { print $2 }' $_CONFIG_YML)"
DEFAULT_TREE="$(awk '/^\s*default_tree:/ { print $2 }' $_CONFIG_YML)"
SHOW_RELEASES="$(awk '/^\s*show_releases:/ { print $2 }' $_CONFIG_YML)"
SHOW_BRANCHES="$(awk '/^\s*show_branches:/ { print $2 }' $_CONFIG_YML)"
SPEC_SERVER="$(awk '/^\s*spec_server:/ { print $2 }' $_CONFIG_YML)"
