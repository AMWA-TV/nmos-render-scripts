#!/usr/bin/env bash

# shellcheck source=get-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/get-config.sh"

set -o errexit

echo Setting up layouts

git clone --single-branch --branch main https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/nmos-doc-layouts .layouts
rm -rf _layouts assets
mv .layouts/_layouts .
mv .layouts/assets .
[[ ! -d _includes ]] && mkdir _includes # nmos repo already has it
mv .layouts/_includes/* _includes/
rm -rf .layouts

# NMOS specs need to get specs.json from the index to populate their menus
if [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS" ]]; then
	echo Getting specs.json
	wget -O- -q https://specs.amwa.tv/nmos/specs.json > _data/specs.json
fi

if [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS-PARAMETER-REGISTERS" ]]; then
	echo Getting registers.json
	wget -O- -q https://specs.amwa.tv/nmos-parameter-registers/registers.json > _data/registers.json
fi
