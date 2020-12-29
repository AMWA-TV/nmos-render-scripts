#!/bin/bash

set -o errexit

# shellcheck source=get-config.sh
. "$(dirname "$0")/get-config.sh"

git clone --no-checkout "$REPO_ADDRESS" source-repo/

