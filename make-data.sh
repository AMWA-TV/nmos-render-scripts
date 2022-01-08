#!/usr/bin/env bash

# shellcheck source=get-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/get-config.sh"

set -o errexit

function make_json_page {
	cat <<EOF > "$1.json"
---
---

{{ site.data.$1 | jsonify }}
EOF
}

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
	jq '[.[] | {name: . | sub("_";" "), file: "\(.).html"}]' > _data/docs.json
	make_json_page docs
fi

if [[ -d "$DEFAULT_TREE/APIs" ]]; then
	echo Making apis.json
	(
		cd "$DEFAULT_TREE/APIs" || exit 1
		for file in *.html; do
			echo "${file%.html}"
		done
	) | \
	jq -R -n '[inputs]'	| \
	jq '[.[] | {name: . | sub("API$"; " API"), file: "\(.).html"}]' > _data/apis.json
	make_json_page apis
fi

if [[ -d "$DEFAULT_TREE/APIs/schemas/with-refs" ]]; then
	echo Making schemas.json
	(
		cd "$DEFAULT_TREE/APIs/schemas/with-refs" || exit 1
		for file in *.html; do
			echo "${file%.html}"
		done
	) | \
	jq -R -n '[inputs]'	| \
	jq '[.[] | {name: ., file: "\(.).html"}]' > _data/schemas.json
	make_json_page schemas
fi

if [[ -d "$DEFAULT_TREE/examples" ]]; then
	echo Making examples.json
	(
		cd "$DEFAULT_TREE/examples" || exit 1
		for file in *.html; do
			echo "${file%.html}"
		done
	) | \
	jq -R -n '[inputs]'	| \
	jq '[.[] | {name: ., file: "\(.).html"}]' > _data/examples.json
	make_json_page examples
fi

if [[ -d "branches" ]]; then
	echo Making branches.json
	(
		cd branches || exit 1
		for branch in *; do
			if [[ "$branch" != "index.md" ]]; then
				echo "$branch"
			fi
		done
	) | \
	jq -R -n '[inputs]'	| \
	jq '[.[] | {name: .}]' > _data/branches.json
	make_json_page branches
fi

if [[ -d "releases" ]]; then
	echo Making releases.json
	(
		cd releases || exit 1
		for release in *; do
			if [[ "$release" != "index.md" ]]; then
				echo "$release"
			fi
		done
	) | \
	jq -R -n '[inputs]'	| \
	jq '[.[] | {name: .}]' > _data/releases.json
	make_json_page releases
fi

exit 0