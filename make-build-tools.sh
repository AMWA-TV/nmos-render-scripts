#!/bin/bash

set -o errexit

git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme
yarn install
sudo pip3 install jsonref pathlib
