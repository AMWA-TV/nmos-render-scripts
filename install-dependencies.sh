#!/bin/bash

set -o errexit

[[ "${PWD##*/}" != ".render" ]] && echo Run this from the top-level directory && exit 1

# shellcheck source=get-config.sh
. .scripts/get-config.sh
