#!/bin/bash

set -o errexit

. $(dirname "$0")/get-config.sh

git clone --no-checkout $REPO_ADDRESS source-repo/

