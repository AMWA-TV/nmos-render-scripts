#!/bin/bash

set -o errexit

[ ! -e README.md ] && echo Run this from the top-level directory && exit 1

# shellcheck source=get-config.sh
. .scripts/get-config.sh


# Many things only relate to IS- specs
if [[ "$AMWA_ID" =~ "IS-" ]]; then
    rm -rf raml2html-nmos-theme
    git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
    cp .scripts/package.json .
    yarn install
    pip3 install setuptools
    pip3 install jsonref pathlib
fi

# All specs need Jekull etc.
bundle install
