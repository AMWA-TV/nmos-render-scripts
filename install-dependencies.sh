#!/bin/bash

set -o errexit

[ ! -e README.md ] && echo Run this from the top-level directory && exit 1

git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
cp .scripts/package.json .
yarn install
sudo pip3 install jsonref pathlib
