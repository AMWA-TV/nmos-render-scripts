#!/bin/bash

set -o errexit

. ./get-config.sh

git clone --no-checkout $REPO_ADDRESS source-repo/

