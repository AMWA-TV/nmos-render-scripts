#!/usr/bin/env bash

# shellcheck source=get-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/get-config.sh"

set -o errexit

echo Creating _data files

[[ ! -d _data ]] && mkdir _data

if [[ -f ../spec.yml ]]; then
	echo Making spec.json
	yaml2json ../spec.yml > _data/spec.json
fi

# NMOS specs need to get specs.json from the index to populate their menus
if [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS" ]]; then
	echo Getting specs.json
	wget -O- -q https://specs.amwa.tv/nmos/specs.json > _data/specs.json
fi

if [[ "$AMWA_ID" != "SPECS" && "$AMWA_ID" != "NMOS-PARAMETER-REGISTERS" ]]; then
	echo Getting registers.json
	wget -O- -q https://specs.amwa.tv/nmos-parameter-registers/registers.json > _data/registers.json
fi

if [[ -d "$DEFAULT_TREE/docs" ]]; then
	echo Making docs.json
	awk -F'^ *- \\[.*\\]\\(' '(NF>1){print $2}' "$DEFAULT_TREE/docs/README.md" | \
	sed 's/\.html)$//' | \
	jq -R -n '[inputs]' | \
	jq '[.[] | {name: . | sub("_";" "), file: "\(.).html" }]' > _data/docs.json
fi