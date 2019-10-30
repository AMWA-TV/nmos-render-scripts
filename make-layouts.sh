#!/bin/bash

set -o errexit

git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/nmos-doc-layouts .layouts
rm -rf _layouts assets
mv .layouts/_layouts .
mv .layouts/assets .
rm -rf .layouts
