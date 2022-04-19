#!/bin/bash

# This file is only used when building without docker (otherwise see Dockerfile)

set -o errexit

[[ "${PWD##*/}" != ".render" ]] && echo Run this from the top-level directory && exit 1

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# Just install these for specs that need them
if [[ -d ../APIs || -d ../testingfacade/APIs || -d ../examples ]]; then
    rm -rf raml2html-nmos-theme
    git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
    cp .scripts/package.json .
    yarn install
    pip install setuptools
    pip install jsonref pathlib
fi

# Param regs is a special case
if [[ "$AMWA_ID" == "NMOS-PARAMETER-REGISTERS" ]]; then
    yarn add jsonlint
fi

# All specs need Jekyll
bundle install
