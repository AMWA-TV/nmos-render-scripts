#!/bin/bash

set -o errexit

[[ "${PWD##*/}" != "render" ]] && echo Run this from the top-level directory && exit 1

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# Just install these for specs that need them
if [[ -d ../APIs ]]; then
    rm -rf raml2html-nmos-theme
    git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
    cp .scripts/package.json .
    yarn install
    pip3 install setuptools
    pip3 install jsonref pathlib
fi

# All specs need Jekyll
bundle install
